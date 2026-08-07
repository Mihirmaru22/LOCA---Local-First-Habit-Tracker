import XCTest
@testable import LOCA

/// Tests for Record Replay guarantee (G4):
///  - Replay produces the same sequence as allFacts()
///  - Replay output is complete (no facts omitted)
///  - Replay order is deterministic and stable across calls
///  - Replay is idempotent (multiple calls return the same sequence)
///  - Replay over an empty Record returns an empty sequence
///  - Simulated derivation re-run from replay produces the same aggregate as live
final class ReplayTests: XCTestCase {

    // MARK: - Helpers

    private func makeEngine() async throws -> RecordEngine {
        try await RecordEngine(store: InMemoryRecordStore())
    }

    private func appendFact(
        to engine: RecordEngine,
        occurredAt: Date = Date()
    ) async throws -> Fact {
        let draft = FactDraft(
            id: UUID(),
            kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil)),
            occurredAt: occurredAt,
            source: .userEntry,
            author: .person,
            entryMethod: .explicit,
            confidence: .known
        )
        return try await engine.append(draft)
    }

    // MARK: - Empty replay

    func testReplayOverEmptyRecordReturnsEmptySequence() async throws {
        let engine = try await makeEngine()
        let facts = try await engine.replayableFacts()
        XCTAssertTrue(facts.isEmpty)
    }

    // MARK: - Completeness

    func testReplayReturnsAllWrittenFacts() async throws {
        let engine = try await makeEngine()
        for i in 0..<7 {
            try await appendFact(to: engine, occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 1000)))
        }

        let facts = try await engine.replayableFacts()
        XCTAssertEqual(facts.count, 7)
    }

    // MARK: - Order determinism

    func testReplayOrderMatchesAppendOrder() async throws {
        let engine = try await makeEngine()
        let t3 = Date(timeIntervalSinceReferenceDate: 3_000)
        let t1 = Date(timeIntervalSinceReferenceDate: 1_000)
        let t2 = Date(timeIntervalSinceReferenceDate: 2_000)

        // Append out of chronological order; replay must return insertion order
        let f1 = try await appendFact(to: engine, occurredAt: t3)
        let f2 = try await appendFact(to: engine, occurredAt: t1)
        let f3 = try await appendFact(to: engine, occurredAt: t2)

        let facts = try await engine.replayableFacts()
        XCTAssertEqual(facts[0].id, f1.id)
        XCTAssertEqual(facts[1].id, f2.id)
        XCTAssertEqual(facts[2].id, f3.id)
    }

    // MARK: - Idempotency

    func testReplayCalledTwiceReturnsSameSequence() async throws {
        let engine = try await makeEngine()
        for i in 0..<5 {
            try await appendFact(to: engine, occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 1000)))
        }

        let first = try await engine.replayableFacts()
        let second = try await engine.replayableFacts()

        XCTAssertEqual(first.map(\.id), second.map(\.id))
    }

    // MARK: - Replay == allFacts

    func testReplayAndAllFactsMatchExactly() async throws {
        let engine = try await makeEngine()
        for i in 0..<5 {
            try await appendFact(to: engine, occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 1000)))
        }

        let replayFacts = try await engine.replayableFacts()
        let allFacts = try await engine.allFacts()

        XCTAssertEqual(replayFacts.map(\.id), allFacts.map(\.id))
    }

    // MARK: - Simulated derivation re-run

    func testReplayDerivedAggregateMatchesLiveAggregate() async throws {
        let engine = try await makeEngine()
        let habitID = UUID()
        var liveTotal = 0.0

        for i in 0..<5 {
            let value = Double(i + 1)
            liveTotal += value
            let draft = FactDraft(
                id: UUID(),
                kind: .habitLogged,
                payload: .habitLogged(HabitLogPayload(habitID: habitID, value: value, note: nil)),
                occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 1000)),
                source: .userEntry,
                author: .person,
                entryMethod: .explicit,
                confidence: .known
            )
            try await engine.append(draft)
        }

        // Re-derive from replay
        let replayFacts = try await engine.replayableFacts()
        var replayTotal = 0.0
        for fact in replayFacts {
            if case .habitLogged(let p) = fact.payload, p.habitID == habitID {
                replayTotal += p.value
            }
        }

        XCTAssertEqual(replayTotal, liveTotal, accuracy: 0.001,
                       "Derived total from replay must match live total")
    }

    // MARK: - Post-dedup replay correctness

    func testReplayExcludesSensorDedupDroppedFacts() async throws {
        let engine = try await makeEngine()
        let ts = Date(timeIntervalSinceReferenceDate: 1_000_000)

        // Two sensor drafts with same sampleType + externalTimestamp → same dedup key
        let draft1 = FactDraft(
            id: UUID(),
            kind: .healthSampleImported,
            payload: .healthSampleImported(HealthSamplePayload(
                sampleType: "HKStepCount", value: 1.0, unit: "count",
                startDate: ts, endDate: ts
            )),
            occurredAt: ts,
            source: .healthKit,
            author: .sensor,
            entryMethod: .imported,
            confidence: .high,
            sourceIdentifier: "HKStepCount",
            externalTimestamp: ts
        )
        let draft2 = FactDraft(
            id: UUID(),
            kind: .healthSampleImported,
            payload: .healthSampleImported(HealthSamplePayload(
                sampleType: "HKStepCount", value: 2.0, unit: "count",
                startDate: ts, endDate: ts
            )),
            occurredAt: ts,
            source: .healthKit,
            author: .sensor,
            entryMethod: .imported,
            confidence: .high,
            sourceIdentifier: "HKStepCount",
            externalTimestamp: ts
        )

        let fact1 = try await engine.append(draft1)
        try await engine.append(draft2) // silently dropped

        let replay = try await engine.replayableFacts()
        XCTAssertEqual(replay.count, 1)
        XCTAssertEqual(replay.first?.id, fact1.id)
    }

    // MARK: - Replay across mixed kinds

    func testReplayPreservesAllKindsInOrder() async throws {
        let engine = try await makeEngine()

        let habitDraft = FactDraft(
            id: UUID(),
            kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil)),
            occurredAt: Date(timeIntervalSinceReferenceDate: 1000),
            source: .userEntry,
            author: .person,
            entryMethod: .explicit,
            confidence: .known
        )
        let reflectionDraft = FactDraft(
            id: UUID(),
            kind: .reflectionWritten,
            payload: .reflectionWritten(ReflectionPayload(text: "good day", promptText: nil, seedFactID: nil)),
            occurredAt: Date(timeIntervalSinceReferenceDate: 2000),
            source: .userEntry,
            author: .person,
            entryMethod: .explicit,
            confidence: .known
        )

        try await engine.append(habitDraft)
        try await engine.append(reflectionDraft)

        let replay = try await engine.replayableFacts()
        XCTAssertEqual(replay.count, 2)
        XCTAssertEqual(replay[0].kind, .habitLogged)
        XCTAssertEqual(replay[1].kind, .reflectionWritten)
    }
}
