import Foundation

// MARK: - RecordReading protocol

/// The public read interface for the Record layer.
/// Any subsystem may read the Record; reads are always concurrent and
/// return a consistent snapshot (the Record does not mutate during a read).
protocol RecordReading: Sendable {
    func facts(matching query: RecordQuery) async throws -> [Fact]
    func allFacts() async throws -> [Fact]
    func count(matching query: RecordQuery) async throws -> Int
    func contains(factID: UUID) async -> Bool
    /// Returns all facts in append order for replay.
    /// Replay is the primary correctness guarantee of the Record layer:
    /// running the derivation engine over `replay()` output must
    /// reproduce the same derived state as the live system.
    func replay() async throws -> [Fact]
}

// MARK: - RecordReader

/// The canonical read path over the Record.
///
/// Characteristics:
///  - Deterministic: the same query always returns the same facts
///    (given the same Record contents).
///  - Ordered: every result set has an explicit sort order (no "undefined order").
///  - Non-mutating: reads never alter the Record.
///  - Replayable: `replay()` returns facts in the canonical order needed
///    to reconstruct all derived state from scratch.
struct RecordReader: RecordReading {

    private let engine: RecordEngine

    init(engine: RecordEngine) {
        self.engine = engine
    }

    // MARK: - RecordReading

    func facts(matching query: RecordQuery) async throws -> [Fact] {
        try await engine.facts(matching: query)
    }

    func allFacts() async throws -> [Fact] {
        try await engine.allFacts()
    }

    func count(matching query: RecordQuery) async throws -> Int {
        try await engine.count(matching: query)
    }

    func contains(factID: UUID) async -> Bool {
        await engine.contains(factID: factID)
    }

    func replay() async throws -> [Fact] {
        try await engine.replayableFacts()
    }

    // MARK: - Convenience queries

    func facts(ofKind kind: FactKind) async throws -> [Fact] {
        try await facts(matching: .kind(kind))
    }

    func facts(ofKind kind: FactKind, in range: RecordDateRange) async throws -> [Fact] {
        try await facts(matching: RecordQuery(kinds: [kind], dateRange: range))
    }

    func mostRecent(kind: FactKind, limit: Int = 1) async throws -> [Fact] {
        try await facts(matching: .recentOf(kind: kind, limit: limit))
    }

    func corrections(for factID: UUID) async throws -> [Fact] {
        let allCorrections = try await facts(ofKind: .correctionSubmitted)
        return allCorrections.filter { fact in
            if case .correctionSubmitted(let p) = fact.payload {
                return p.targetFactID == factID
            }
            return false
        }
    }
}
