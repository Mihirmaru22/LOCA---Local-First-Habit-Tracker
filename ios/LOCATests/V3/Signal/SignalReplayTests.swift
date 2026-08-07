import XCTest
@testable import LOCA

/// Tests for Signal Engine replay guarantees (S2, S3):
///  - Replay produces the same Signal IDs as the first pass
///  - Replay is complete — one Signal per Fact
///  - Replay is idempotent — multiple replays produce the same result
///  - Replay over an empty Record produces no Signals
///  - Mixed fact kinds survive replay in insertion order
///  - SignalContract invariants pass after replay
///  - Replay correctly produces re-derived aggregate data
final class SignalReplayTests: XCTestCase {

    // MARK: - Helpers

    private func makePair() async throws -> (SignalEngine, RecordEngine) {
        let signalEngine = try await SignalEngine(store: InMemorySignalStore())
        let recordEngine = try await RecordEngine(store: InMemoryRecordStore())
        return (signalEngine, recordEngine)
    }

    private func appendHabitFact(
        to record: RecordEngine,
        habitID: UUID = UUID(),
        value: Double = 1.0,
        occurredAt: Date = Date()
    ) async throws -> Fact {
        let draft = FactDraft(
            id: UUID(),
            kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: habitID, value: value, note: nil)),
            occurredAt: occurredAt,
            source: .userEntry,
            author: .person,
            entryMethod: .explicit,
            confidence: .known
        )
        return try await record.append(draft)
    }

    // MARK: - Empty replay

    func testReplayOverEmptyRecordProducesNoSignals() async throws {
        let (signalEngine, _) = try await makePair()
        let signals = try await signalEngine.replay(from: [])
        XCTAssertTrue(signals.isEmpty)
    }

    // MARK: - Completeness (S3)

    func testReplayProducesOneSignalPerFact() async throws {
        let (signalEngine, record) = try await makePair()
        for i in 0..<7 {
            try await appendHabitFact(
                to: record,
                occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 1000)))
        }
        let facts = try await record.replayableFacts()
        let signals = try await signalEngine.replay(from: facts)
        XCTAssertEqual(signals.count, facts.count,
            "Replay must produce exactly one Signal per Fact (S3)")
    }

    // MARK: - Determinism (S2)

    func testReplayProducesSameSignalIDs() async throws {
        let (signalEngine, record) = try await makePair()
        for i in 0..<4 {
            try await appendHabitFact(
                to: record,
                occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 1000)))
        }
        let facts = try await record.replayableFacts()

        let firstIDs = try await signalEngine.replay(from: facts).map(\.id)
        let secondIDs = try await signalEngine.replay(from: facts).map(\.id)

        XCTAssertEqual(firstIDs, secondIDs, "Replay must produce the same Signal IDs (S2)")
    }

    func testReplaySignalIDsEqualFactIDs() async throws {
        let (signalEngine, record) = try await makePair()
        let f1 = try await appendHabitFact(to: record)
        let f2 = try await appendHabitFact(to: record)
        let facts = try await record.replayableFacts()

        let signals = try await signalEngine.replay(from: facts)

        let factIDs = Set([f1.id, f2.id])
        let signalIDs = Set(signals.map(\.id))
        XCTAssertEqual(signalIDs, factIDs,
            "Each Signal.id must equal its source Fact.id (S2)")
    }

    // MARK: - Idempotency

    func testMultipleReplaysProduceSameCount() async throws {
        let (signalEngine, record) = try await makePair()
        for i in 0..<3 {
            try await appendHabitFact(
                to: record,
                occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 1000)))
        }
        let facts = try await record.replayableFacts()

        _ = try await signalEngine.replay(from: facts)
        _ = try await signalEngine.replay(from: facts)
        let count = try await signalEngine.count()

        XCTAssertEqual(count, 3, "Repeated replays must not accumulate signals")
    }

    // MARK: - Ordering

    func testReplayPreservesInsertionOrder() async throws {
        let (signalEngine, record) = try await makePair()
        let t3 = Date(timeIntervalSinceReferenceDate: 3_000)
        let t1 = Date(timeIntervalSinceReferenceDate: 1_000)
        let t2 = Date(timeIntervalSinceReferenceDate: 2_000)

        let f1 = try await appendHabitFact(to: record, occurredAt: t3)
        let f2 = try await appendHabitFact(to: record, occurredAt: t1)
        let f3 = try await appendHabitFact(to: record, occurredAt: t2)

        let facts = try await record.replayableFacts()
        let signals = try await signalEngine.replay(from: facts)

        XCTAssertEqual(signals[0].id, f1.id)
        XCTAssertEqual(signals[1].id, f2.id)
        XCTAssertEqual(signals[2].id, f3.id)
    }

    // MARK: - Mixed kinds (all FactKind survive replay)

    func testReplayPreservesAllKindSignals() async throws {
        let (signalEngine, record) = try await makePair()

        let habitDraft = FactDraft(
            id: UUID(), kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil)),
            occurredAt: Date(timeIntervalSinceReferenceDate: 1_000),
            source: .userEntry, author: .person, entryMethod: .explicit, confidence: .known)
        let reflectionDraft = FactDraft(
            id: UUID(), kind: .reflectionWritten,
            payload: .reflectionWritten(ReflectionPayload(text: "today", promptText: nil, seedFactID: nil)),
            occurredAt: Date(timeIntervalSinceReferenceDate: 2_000),
            source: .userEntry, author: .person, entryMethod: .explicit, confidence: .known)
        let healthDraft = FactDraft(
            id: UUID(), kind: .healthSampleImported,
            payload: .healthSampleImported(HealthSamplePayload(
                sampleType: "HKStepCount", value: 5000, unit: "count",
                startDate: Date(timeIntervalSinceReferenceDate: 3_000),
                endDate: Date(timeIntervalSinceReferenceDate: 3_000))),
            occurredAt: Date(timeIntervalSinceReferenceDate: 3_000),
            source: .healthKit, author: .sensor, entryMethod: .imported, confidence: .high,
            sourceIdentifier: "HKStepCount", externalTimestamp: Date(timeIntervalSinceReferenceDate: 3_000))

        try await record.append(habitDraft)
        try await record.append(reflectionDraft)
        try await record.append(healthDraft)

        let facts = try await record.replayableFacts()
        let signals = try await signalEngine.replay(from: facts)

        XCTAssertEqual(signals.count, 3)
        XCTAssertEqual(signals[0].kind, .habitCompletion)
        XCTAssertEqual(signals[1].kind, .reflection)
        XCTAssertEqual(signals[2].kind, .healthSample)
    }

    // MARK: - Derived aggregate matches after replay (S3)

    func testReplayedAggregateMatchesLiveAggregate() async throws {
        let (signalEngine, record) = try await makePair()
        let habitID = UUID()
        var liveTotal = 0.0

        for i in 0..<5 {
            let value = Double(i + 1)
            liveTotal += value
            try await appendHabitFact(
                to: record, habitID: habitID, value: value,
                occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 1000)))
        }

        let facts = try await record.replayableFacts()
        let signals = try await signalEngine.replay(from: facts)

        var replayTotal = 0.0
        for signal in signals {
            if case .habitCompletion(let p) = signal.payload, p.habitID == habitID {
                replayTotal += p.value
            }
        }

        XCTAssertEqual(replayTotal, liveTotal, accuracy: 0.001,
            "Derived total from replay must match live total (S3)")
    }

    // MARK: - Provenance completeness after replay (S4)

    func testReplayedSignalsHaveFullProvenance() async throws {
        let (signalEngine, record) = try await makePair()
        let fact = try await appendHabitFact(to: record)
        let facts = try await record.replayableFacts()

        let signals = try await signalEngine.replay(from: facts)
        let signal = try XCTUnwrap(signals.first)

        XCTAssertEqual(signal.provenance.sourceFactID, fact.id)
        XCTAssertEqual(signal.provenance.sourceFactKind, fact.kind)
        XCTAssertEqual(signal.provenance.factSource, .userEntry)
        XCTAssertEqual(signal.provenance.factConfidence, .known)
        XCTAssertEqual(signal.provenance.pipelineVersion, SignalPipeline.version)
    }

    // MARK: - SignalContract validation after replay

    func testSignalContractPassesAfterReplay() async throws {
        let (signalEngine, record) = try await makePair()
        for i in 0..<3 {
            try await appendHabitFact(
                to: record,
                occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 1000)))
        }

        let facts = try await record.replayableFacts()
        _ = try await signalEngine.replay(from: facts)

        let signals = try await signalEngine.allSignals()
        XCTAssertNoThrow(
            try SignalContract.validateInvariants(
                signals: signals, facts: facts, expectedCount: 3),
            "Signal layer invariants must pass after clean replay")
    }
}
