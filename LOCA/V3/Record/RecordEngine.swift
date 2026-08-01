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
/// Validation is enforced inside RecordEngine.append — there is no write path
/// that bypasses it. Callers submit a FactDraft; the engine validates, builds
/// the immutable Fact, and stores it. No pre-built Fact is accepted directly.
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
    private let validator: any FactValidating

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
    init(
        store: any RecordStoring,
        validator: any FactValidating = DefaultFactValidator()
    ) async throws {
        self.store = store
        self.validator = validator
        self.knownIDs = try await store.existingIDs()
        self.knownDedupKeys = []
        // Note: for a persistent store, dedup keys would also need to be
        // rebuilt from the store on init. For Sprint 1 (in-memory), the
        // store starts empty so this is a no-op.
    }

    // MARK: - Write (serialized by actor)

    /// Validates the draft, builds an immutable Fact, and appends it to the Record.
    ///
    /// Pipeline:
    ///   FactDraft (caller intent)
    ///     ↓  validate — reject malformed drafts before touching the Record
    ///     ↓  duplicate-ID check — hard error if id already written
    ///     ↓  build provenance + Fact (recordedAt set here, not by caller)
    ///     ↓  sensor dedup — silently drop if dedup key already seen
    ///     ↓  RecordStoring.append — serialized single-writer store write
    ///     → Fact (immutable, in the Record)
    ///
    /// Validation is mandatory and cannot be bypassed — all callers submit a
    /// FactDraft; there is no method to append a pre-built Fact directly.
    ///
    /// - Throws:
    ///   `RecordError.invalidFact` if the draft fails validation.
    ///   `RecordError.duplicateFact` if the id was already written.
    ///   `RecordError.storageFailure` if the underlying store fails.
    @discardableResult
    func append(_ draft: FactDraft) async throws -> Fact {
        // 1. Validate — reject before touching the Record
        let validatedDraft: FactDraft
        switch validator.validate(draft) {
        case .success(let d):
            validatedDraft = d
        case .failure(let error):
            throw RecordError.invalidFact(error)
        }

        // 2. Duplicate-ID check (hard error — first write wins)
        if knownIDs.contains(validatedDraft.id) {
            throw RecordError.duplicateFact(existingID: validatedDraft.id)
        }

        // 3. Build provenance and the immutable Fact.
        // recordedAt is set here — the moment it enters the Record — not by the caller.
        let provenance = FactProvenance(
            source: validatedDraft.source,
            author: validatedDraft.author,
            entryMethod: validatedDraft.entryMethod,
            confidence: validatedDraft.confidence,
            sourceIdentifier: validatedDraft.sourceIdentifier,
            externalTimestamp: validatedDraft.externalTimestamp
        )
        let fact = Fact(
            id: validatedDraft.id,
            kind: validatedDraft.kind,
            payload: validatedDraft.payload,
            provenance: provenance,
            recordedAt: Date(),
            occurredAt: validatedDraft.occurredAt
        )

        // 4. Sensor dedup (idempotent — not an error; second write is silently dropped)
        let dedupKey = validatedDraft.deduplicationKey
        if let key = dedupKey, knownDedupKeys.contains(key) {
            // Not stored, not emitted. Return the would-be Fact so callers have a value.
            return fact
        }

        // 5. Write to store (cross-actor call — requires await)
        do {
            try await store.append(fact)
        } catch {
            throw RecordError.storageFailure(underlying: error)
        }

        // 6. Update dedup state (only after successful store write)
        knownIDs.insert(fact.id)
        if let key = dedupKey {
            knownDedupKeys.insert(key)
        }

        // 7. Emit event (synchronous; handlers must be non-blocking)
        let event = FactWrittenEvent(fact: fact, writtenAt: Date())
        for handler in factWrittenHandlers {
            handler(event)
        }

        return fact
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

    /// Returns all facts in append (insertion) order.
    /// A replay over these facts, through the derivation engine, must
    /// reproduce the same derived state — the Record is the single truth.
    func replayableFacts() async throws -> [Fact] {
        try await store.allFacts()
    }
}
