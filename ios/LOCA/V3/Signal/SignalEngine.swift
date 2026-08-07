import Foundation

// MARK: - SignalEngine

/// The single gatekeeper for all writes to the Signal layer.
///
/// SignalEngine consumes Facts and produces Signals.
/// It is the Signal layer's analogue to RecordEngine.
///
/// Enforced invariants:
///  S1: One Signal per Fact. Processing the same Fact twice is idempotent.
///  S2: Determinism. Same Fact → same Signal (id, kind, payload).
///  S3: Replay. clear() + process(same facts) = same signals.
///  S4: Provenance completeness. Every Signal carries full SignalProvenance.
///  S5: Read-only from Record. SignalEngine never writes to the Record.
actor SignalEngine {

    // MARK: - State

    private let store: any SignalStoring

    /// Known source Fact IDs. Used for O(1) dedup.
    /// Populated from the store on init so restarts are safe.
    private var knownFactIDs: Set<UUID>

    // MARK: - Init

    init(store: any SignalStoring) async throws {
        self.store = store
        self.knownFactIDs = try await store.existingFactIDs()
    }

    // MARK: - Process a single Fact

    /// Transform a Fact into a Signal and store it.
    ///
    /// Returns the produced Signal, or nil if the Fact was already processed
    /// (idempotent — not an error).
    ///
    /// - Throws: `SignalError.pipelineFailure` if transformation fails.
    ///           `SignalError.storageFailure` if the store fails.
    @discardableResult
    func process(_ fact: Fact) async throws -> Signal? {
        guard !knownFactIDs.contains(fact.id) else { return nil }

        switch SignalPipeline.transform(fact) {
        case .failure(let e):
            throw SignalError.pipelineFailure(e)
        case .success(let signal):
            do {
                try await store.append(signal)
            } catch {
                throw SignalError.storageFailure(underlying: error)
            }
            knownFactIDs.insert(fact.id)
            return signal
        }
    }

    // MARK: - Batch processing

    /// Process a sequence of Facts in order.
    /// Facts already processed are silently skipped.
    /// Returns only the newly produced Signals.
    @discardableResult
    func processAll(_ facts: [Fact]) async throws -> [Signal] {
        var produced: [Signal] = []
        for fact in facts {
            if let signal = try await process(fact) {
                produced.append(signal)
            }
        }
        return produced
    }

    // MARK: - Replay

    /// Clear all Signals and reprocess every Fact in the given sequence.
    ///
    /// Replay guarantee: given the same ordered sequence of Facts, replay
    /// always produces the same set of Signals (same IDs, same payloads).
    /// This holds because Signal.id == source Fact.id.
    ///
    /// - Parameter facts: The complete ordered Fact sequence.
    ///   Pass `RecordEngine.replayableFacts()` for the canonical sequence.
    @discardableResult
    func replay(from facts: [Fact]) async throws -> [Signal] {
        do {
            try await store.clear()
        } catch {
            throw SignalError.replayFailure(message: "Store clear failed: \(error)")
        }
        knownFactIDs = []
        return try await processAll(facts)
    }

    // MARK: - Reads

    func allSignals() async throws -> [Signal] {
        try await store.allSignals()
    }

    func signal(forFactID id: UUID) async throws -> Signal? {
        try await store.signal(forFactID: id)
    }

    func count() async throws -> Int {
        try await store.count()
    }
}
