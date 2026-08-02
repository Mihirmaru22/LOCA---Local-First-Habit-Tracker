import XCTest
@testable import LOCA

/// Tests for SignalEngine invariants:
///  - One Signal per Fact (S1)
///  - process() returns Signal for new Fact, nil for duplicate
///  - processAll() handles batches and skips duplicates
///  - Replay produces the same signal IDs (S2, S3)
///  - signal(forFactID:) lookup
final class SignalEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeSignalEngine() async throws -> SignalEngine {
        try await SignalEngine(store: InMemorySignalStore())
    }

    private func makePair() async throws -> (SignalEngine, RecordEngine) {
        let signalEngine = try await SignalEngine(store: InMemorySignalStore())
        let recordEngine = try await RecordEngine(store: InMemoryRecordStore())
        return (signalEngine, recordEngine)
    }

    private func appendFact(
        to record: RecordEngine,
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
        return try await record.append(draft)
    }

    // MARK: - Basic processing

    func testProcessReturnsSignalForNewFact() async throws {
        let (engine, record) = try await makePair()
        let fact = try await appendFact(to: record)

        let signal = try await engine.process(fact)

        XCTAssertNotNil(signal)
        XCTAssertEqual(signal?.id, fact.id)
        XCTAssertEqual(signal?.kind, .habitCompletion)
    }

    func testProcessReturnsNilForDuplicateFact() async throws {
        let (engine, record) = try await makePair()
        let fact = try await appendFact(to: record)

        _ = try await engine.process(fact)
        let second = try await engine.process(fact)

        XCTAssertNil(second, "Processing the same Fact twice must be idempotent (S1)")
    }

    func testSignalCountAfterProcessing() async throws {
        let (engine, record) = try await makePair()
        let fact1 = try await appendFact(to: record)
        let fact2 = try await appendFact(to: record)

        _ = try await engine.process(fact1)
        _ = try await engine.process(fact2)

        let count = try await engine.count()
        XCTAssertEqual(count, 2)
    }

    func testDuplicateProcessingDoesNotDoubleCount() async throws {
        let (engine, record) = try await makePair()
        let fact = try await appendFact(to: record)

        _ = try await engine.process(fact)
        _ = try await engine.process(fact)

        let count = try await engine.count()
        XCTAssertEqual(count, 1, "Duplicate process must not increase count (S1)")
    }

    // MARK: - Signal.id == Fact.id (S2)

    func testSignalIDEqualsSourceFactID() async throws {
        let (engine, record) = try await makePair()
        let fact = try await appendFact(to: record)

        let signal = try await engine.process(fact)

        XCTAssertEqual(signal?.id, fact.id, "Signal.id must equal source Fact.id (S2)")
    }

    // MARK: - processAll

    func testProcessAllHandlesBatch() async throws {
        let (engine, record) = try await makePair()
        let f1 = try await appendFact(to: record)
        let f2 = try await appendFact(to: record)
        let f3 = try await appendFact(to: record)

        let produced = try await engine.processAll([f1, f2, f3])

        XCTAssertEqual(produced.count, 3)
    }

    func testProcessAllSkipsDuplicates() async throws {
        let (engine, record) = try await makePair()
        let fact = try await appendFact(to: record)

        _ = try await engine.process(fact)
        let produced = try await engine.processAll([fact])

        XCTAssertEqual(produced.count, 0, "processAll must skip already-processed Facts")
    }

    func testProcessAllReturnCount() async throws {
        let (engine, record) = try await makePair()
        let f1 = try await appendFact(to: record)
        let f2 = try await appendFact(to: record)

        _ = try await engine.process(f1)
        let produced = try await engine.processAll([f1, f2])

        XCTAssertEqual(produced.count, 1, "Only newly processed fact should be returned")
    }

    // MARK: - Replay (S3)

    func testReplayProducesSameSignalIDs() async throws {
        let (engine, record) = try await makePair()
        for i in 0..<4 {
            try await appendFact(to: record,
                occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 1000)))
        }
        let facts = try await record.replayableFacts()

        let firstPass = try await engine.replay(from: facts)
        let secondPass = try await engine.replay(from: facts)

        XCTAssertEqual(
            firstPass.map(\.id).sorted { $0.uuidString < $1.uuidString },
            secondPass.map(\.id).sorted { $0.uuidString < $1.uuidString },
            "Replay must produce the same signal IDs (S3)")
    }

    func testReplayClearsAndRegeneratesSignals() async throws {
        let (engine, record) = try await makePair()
        try await appendFact(to: record)
        let facts = try await record.replayableFacts()

        _ = try await engine.replay(from: facts)
        _ = try await engine.replay(from: facts)

        let count = try await engine.count()
        XCTAssertEqual(count, 1, "Replay must not accumulate — it clears and regenerates")
    }

    func testReplayOverEmptyRecordProducesNoSignals() async throws {
        let engine = try await makeSignalEngine()
        let signals = try await engine.replay(from: [])
        XCTAssertTrue(signals.isEmpty)
    }

    func testReplaySignalIDsMatchFactIDs() async throws {
        let (engine, record) = try await makePair()
        let f1 = try await appendFact(to: record)
        let f2 = try await appendFact(to: record)
        let facts = try await record.replayableFacts()

        let signals = try await engine.replay(from: facts)

        let factIDs = Set([f1.id, f2.id])
        let signalIDs = Set(signals.map(\.id))
        XCTAssertEqual(signalIDs, factIDs, "Each Signal ID must equal its source Fact ID")
    }

    // MARK: - signal(forFactID:)

    func testSignalForFactIDReturnsCorrectSignal() async throws {
        let (engine, record) = try await makePair()
        let fact = try await appendFact(to: record)

        _ = try await engine.process(fact)
        let retrieved = try await engine.signal(forFactID: fact.id)

        XCTAssertEqual(retrieved?.id, fact.id)
    }

    func testSignalForUnknownFactIDReturnsNil() async throws {
        let engine = try await makeSignalEngine()
        let result = try await engine.signal(forFactID: UUID())
        XCTAssertNil(result)
    }

    // MARK: - allSignals ordering

    func testAllSignalsReturnsInsertionOrder() async throws {
        let (engine, record) = try await makePair()
        let t1 = Date(timeIntervalSinceReferenceDate: 3_000)
        let t2 = Date(timeIntervalSinceReferenceDate: 1_000)
        let t3 = Date(timeIntervalSinceReferenceDate: 2_000)

        let f1 = try await appendFact(to: record, occurredAt: t1)
        let f2 = try await appendFact(to: record, occurredAt: t2)
        let f3 = try await appendFact(to: record, occurredAt: t3)

        _ = try await engine.process(f1)
        _ = try await engine.process(f2)
        _ = try await engine.process(f3)

        let signals = try await engine.allSignals()
        XCTAssertEqual(signals[0].id, f1.id)
        XCTAssertEqual(signals[1].id, f2.id)
        XCTAssertEqual(signals[2].id, f3.id)
    }
}
