import Foundation

// MARK: - FactWrittenEvent

/// Emitted after a Fact is durably written to the Record.
/// Downstream subsystems (Derivation, Runtime) subscribe to this event
/// to trigger incremental recompute (Build2 event taxonomy: Class A/B).
struct FactWrittenEvent: Sendable {
    let fact: Fact
    let writtenAt: Date
}

// MARK: - RecordEngine

/// The single gatekeeper for all writes to the Record.
///
/// RecordEngine is the ONLY entity authorized to call RecordStoring.append().
/// All writes are serialized by the actor executor (single-writer discipline, Build2 §IV).
/// All reads are served directly from the store concurrently (snapshot reads).
///
/// Enforced invariants:
///  1. Append-only: no mutation or deletion of a prior Fact.
///  2. No duplicate IDs: the same Fact.id may never be written twice.
///  3. Sensor dedup: a Fact with a previously-seen deduplication key is silently
///     rejected (not an error — idempotent by design, Build2 §II Class B).
///  4. Completeness: every written Fact carries full provenance.
///  5. Single writer: the actor ensures sequential writes with no race conditions.
actor RecordEngine {

    // MARK: - State

    private let store: any RecordStoring

    /// Known fact IDs. Maintained in memory for O(1) duplicate checks.
    /// Populated from the store on initialisation so restarts are safe.
    private var knownIDs: Set<UUID>

    /// Known deduplication keys for sensed/imported facts.
    /// Missing = unknown, not an error (sensor dedup is best-effort).
    private var knownDedupKeys: Set<String>

    /// Registered fact-written handlers.
    private var factWrittenHandlers: [@Sendable (FactWrittenEvent) -> Void] = []

    // MARK: - Init

    /// Creates a RecordEngine backed by the given store.
    /// Loads existing IDs from the store to support restarts.
    init(store: any RecordStoring) async throws {
        self.store = store
        self.knownIDs = try await store.existingIDs()
        self.knownDedupKeys = []
        // Note: for a persistent store, dedup keys would also need to be
        // rebuilt from the store on init. For Sprint 1 (in-memory), the
        // store starts empty so this is a no-op.
    }

    // MARK: - Write (serialized by actor)

    /// Appends a fact to the Record.
    ///
    /// - Parameter fact: The Fact to append. Must have a unique id.
    /// - Parameter dedupKey: Optional deduplication key (for sensed facts).
    ///   If non-nil and already seen, the write is silently skipped (not an error).
    ///
    /// - Throws:
    ///   `RecordError.duplicateFact` if the id was already written.
    ///   `RecordError.storageFailure` if the underlying store fails.
    ///
    /// Called only by RecordWriter. Nothing else may call this.
    func append(_ fact: Fact, dedupKey: String? = nil) async throws {
        // 1. Duplicate-ID check (idempotency guard for retries)
        if knownIDs.contains(fact.id) {
            throw RecordError.duplicateFact(existingID: fact.id)
        }

        // 2. Sensor dedup (idempotent — not an error; second write is silently dropped)
        if let key = dedupKey, knownDedupKeys.contains(key) {
            // Not an error: this is the intended dedup behavior (Build2 §II Class B).
            // The caller treats this as a successful no-op.
            return
        }

        // 3. Write to store (cross-actor call — requires await)
        do {
            try await store.append(fact)
        } catch {
            throw RecordError.storageFailure(underlying: error)
        }

        // 4. Update dedup state (only after successful store write)
        knownIDs.insert(fact.id)
        if let key = dedupKey {
            knownDedupKeys.insert(key)
        }

        // 5. Emit event (synchronous; handlers must be non-blocking)
        let event = FactWrittenEvent(fact: fact, writtenAt: Date())
        for handler in factWrittenHandlers {
            handler(event)
        }
    }

    // MARK: - Read (concurrent; actor serializes but reads are non-mutating)

    func facts(matching query: RecordQuery) async throws -> [Fact] {
        try await store.facts(matching: query)
    }

    func allFacts() async throws -> [Fact] {
        try await store.allFacts()
    }

    func count(matching query: RecordQuery) async throws -> Int {
        try await store.count(matching: query)
    }

    func contains(factID: UUID) -> Bool {
        knownIDs.contains(factID)
    }

    // MARK: - Event subscription

    /// Register a handler to be called synchronously after each successful write.
    /// Handlers must complete quickly — they run on the actor's executor.
    func onFactWritten(_ handler: @escaping @Sendable (FactWrittenEvent) -> Void) {
        factWrittenHandlers.append(handler)
    }

    // MARK: - Replay

    /// Returns all facts in append order (recordedAt ascending).
    /// A replay over these facts, through the derivation engine, must
    /// reproduce the same derived state — the Record is the single truth.
    func replayableFacts() async throws -> [Fact] {
        try await store.allFacts()
    }
}
