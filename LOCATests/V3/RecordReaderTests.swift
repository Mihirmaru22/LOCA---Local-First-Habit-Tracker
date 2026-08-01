import XCTest
@testable import LOCA

/// Tests for RecordReader guarantees:
///  - Deterministic ordering
///  - Filtering by kind, date range, and source
///  - Pagination (limit + offset)
///  - Replay consistency (replay output == allFacts output in append order)
///  - Convenience query helpers
final class RecordReaderTests: XCTestCase {

    // MARK: - Helpers

    private func makeReaderAndEngine() async throws -> (RecordReader, RecordEngine) {
        let engine = try await RecordEngine(store: InMemoryRecordStore())
        let reader = RecordReader(engine: engine)
        return (reader, engine)
    }

    private func appendFact(
        to engine: RecordEngine,
        kind: FactKind = .habitLogged,
        occurredAt: Date = Date(),
        source: FactSource = .userEntry
    ) async throws -> Fact {
        let payload: FactPayload
        switch kind {
        case .habitLogged:
            payload = .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil))
        case .reflectionWritten:
            payload = .reflectionWritten(ReflectionPayload(text: "test", promptText: nil, seedFactID: nil))
        case .healthSampleImported:
            payload = .healthSampleImported(HealthSamplePayload(
                sampleType: "HKStepCount", value: 100, unit: "count",
                startDate: occurredAt, endDate: occurredAt
            ))
        default:
            payload = .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil))
        }

        let fact = Fact(
            id: UUID(),
            kind: kind,
            payload: payload,
            provenance: FactProvenance(
                source: source,
                author: .person,
                entryMethod: .explicit,
                confidence: .known,
                sourceIdentifier: nil,
                externalTimestamp: nil
            ),
            recordedAt: occurredAt,
            occurredAt: occurredAt
        )
        try await engine.append(fact)
        return fact
    }

    // MARK: - allFacts ordering

    func testAllFactsReturnsFactsInAppendOrder() async throws {
        let (reader, engine) = try await makeReaderAndEngine()
        let f1 = try await appendFact(to: engine, occurredAt: Date(timeIntervalSinceReferenceDate: 3_000))
        let f2 = try await appendFact(to: engine, occurredAt: Date(timeIntervalSinceReferenceDate: 1_000))
        let f3 = try await appendFact(to: engine, occurredAt: Date(timeIntervalSinceReferenceDate: 2_000))

        let facts = try await reader.allFacts()

        XCTAssertEqual(facts.count, 3)
        XCTAssertEqual(facts[0].id, f1.id)
        XCTAssertEqual(facts[1].id, f2.id)
        XCTAssertEqual(facts[2].id, f3.id)
    }

    // MARK: - Ordered queries

    func testOccurredAtAscendingOrder() async throws {
        let (reader, engine) = try await makeReaderAndEngine()
        let t1 = Date(timeIntervalSinceReferenceDate: 1_000)
        let t2 = Date(timeIntervalSinceReferenceDate: 2_000)
        let t3 = Date(timeIntervalSinceReferenceDate: 3_000)

        try await appendFact(to: engine, occurredAt: t3)
        try await appendFact(to: engine, occurredAt: t1)
        try await appendFact(to: engine, occurredAt: t2)

        let facts = try await reader.facts(matching: RecordQuery(order: .occurredAtAscending))
        XCTAssertEqual(facts[0].occurredAt, t1)
        XCTAssertEqual(facts[1].occurredAt, t2)
        XCTAssertEqual(facts[2].occurredAt, t3)
    }

    func testOccurredAtDescendingOrder() async throws {
        let (reader, engine) = try await makeReaderAndEngine()
        let t1 = Date(timeIntervalSinceReferenceDate: 1_000)
        let t2 = Date(timeIntervalSinceReferenceDate: 2_000)
        let t3 = Date(timeIntervalSinceReferenceDate: 3_000)

        try await appendFact(to: engine, occurredAt: t1)
        try await appendFact(to: engine, occurredAt: t2)
        try await appendFact(to: engine, occurredAt: t3)

        let facts = try await reader.facts(matching: RecordQuery(order: .occurredAtDescending))
        XCTAssertEqual(facts[0].occurredAt, t3)
        XCTAssertEqual(facts[1].occurredAt, t2)
        XCTAssertEqual(facts[2].occurredAt, t1)
    }

    // MARK: - Kind filtering

    func testFactsOfKindReturnsOnlyThatKind() async throws {
        let (reader, engine) = try await makeReaderAndEngine()

        try await appendFact(to: engine, kind: .habitLogged)
        try await appendFact(to: engine, kind: .reflectionWritten)
        try await appendFact(to: engine, kind: .habitLogged)

        let habits = try await reader.facts(ofKind: .habitLogged)
        XCTAssertEqual(habits.count, 2)
        XCTAssertTrue(habits.allSatisfy { $0.kind == .habitLogged })

        let reflections = try await reader.facts(ofKind: .reflectionWritten)
        XCTAssertEqual(reflections.count, 1)
    }

    // MARK: - Date range filtering

    func testFactsOfKindInDateRange() async throws {
        let (reader, engine) = try await makeReaderAndEngine()
        let inRange = Date(timeIntervalSinceReferenceDate: 1_500)
        let outOfRange = Date(timeIntervalSinceReferenceDate: 500)

        try await appendFact(to: engine, kind: .habitLogged, occurredAt: inRange)
        try await appendFact(to: engine, kind: .habitLogged, occurredAt: outOfRange)

        let range = DateRange(
            start: Date(timeIntervalSinceReferenceDate: 1_000),
            end: Date(timeIntervalSinceReferenceDate: 2_000)
        )
        let facts = try await reader.facts(ofKind: .habitLogged, in: range)
        XCTAssertEqual(facts.count, 1)
        XCTAssertEqual(facts.first?.occurredAt, inRange)
    }

    // MARK: - Pagination

    func testLimitReturnsSubset() async throws {
        let (reader, engine) = try await makeReaderAndEngine()
        for i in 0..<5 {
            try await appendFact(
                to: engine,
                occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 1000))
            )
        }

        let query = RecordQuery(order: .occurredAtAscending, limit: 2, offset: 0)
        let facts = try await reader.facts(matching: query)
        XCTAssertEqual(facts.count, 2)
    }

    func testOffsetSkipsLeadingFacts() async throws {
        let (reader, engine) = try await makeReaderAndEngine()
        for i in 0..<5 {
            try await appendFact(
                to: engine,
                occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 1000))
            )
        }

        let page1 = try await reader.facts(matching: RecordQuery(
            order: .occurredAtAscending, limit: 2, offset: 0
        ))
        let page2 = try await reader.facts(matching: RecordQuery(
            order: .occurredAtAscending, limit: 2, offset: 2
        ))

        XCTAssertNotEqual(page1.first?.id, page2.first?.id)
        XCTAssertEqual(page2.count, 2)
    }

    // MARK: - mostRecent

    func testMostRecentReturnsLatestByOccurredAt() async throws {
        let (reader, engine) = try await makeReaderAndEngine()
        let t1 = Date(timeIntervalSinceReferenceDate: 1_000)
        let t2 = Date(timeIntervalSinceReferenceDate: 2_000)
        let t3 = Date(timeIntervalSinceReferenceDate: 3_000)

        try await appendFact(to: engine, kind: .habitLogged, occurredAt: t1)
        try await appendFact(to: engine, kind: .habitLogged, occurredAt: t3)
        try await appendFact(to: engine, kind: .habitLogged, occurredAt: t2)

        let recent = try await reader.mostRecent(kind: .habitLogged, limit: 1)
        XCTAssertEqual(recent.count, 1)
        XCTAssertEqual(recent.first?.occurredAt, t3)
    }

    func testMostRecentLimitRespected() async throws {
        let (reader, engine) = try await makeReaderAndEngine()
        for i in 0..<5 {
            try await appendFact(
                to: engine,
                kind: .habitLogged,
                occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 1000))
            )
        }

        let recent = try await reader.mostRecent(kind: .habitLogged, limit: 3)
        XCTAssertEqual(recent.count, 3)
    }

    // MARK: - Count

    func testCountMatchesFactsCount() async throws {
        let (reader, engine) = try await makeReaderAndEngine()

        try await appendFact(to: engine, kind: .habitLogged)
        try await appendFact(to: engine, kind: .reflectionWritten)
        try await appendFact(to: engine, kind: .habitLogged)

        let count = try await reader.count(matching: .kind(.habitLogged))
        XCTAssertEqual(count, 2)
    }

    // MARK: - Contains

    func testContainsReturnsTrueForWrittenFact() async throws {
        let (reader, engine) = try await makeReaderAndEngine()
        let fact = try await appendFact(to: engine)
        let result = await reader.contains(factID: fact.id)
        XCTAssertTrue(result)
    }

    func testContainsReturnsFalseForMissingFact() async throws {
        let (reader, _) = try await makeReaderAndEngine()
        let result = await reader.contains(factID: UUID())
        XCTAssertFalse(result)
    }

    // MARK: - Replay

    func testReplayReturnsFactsInAppendOrder() async throws {
        let (reader, engine) = try await makeReaderAndEngine()
        let t1 = Date(timeIntervalSinceReferenceDate: 3_000)
        let t2 = Date(timeIntervalSinceReferenceDate: 1_000)
        let t3 = Date(timeIntervalSinceReferenceDate: 2_000)

        let f1 = try await appendFact(to: engine, occurredAt: t1)
        let f2 = try await appendFact(to: engine, occurredAt: t2)
        let f3 = try await appendFact(to: engine, occurredAt: t3)

        let replayFacts = try await reader.replay()
        XCTAssertEqual(replayFacts.count, 3)
        XCTAssertEqual(replayFacts[0].id, f1.id)
        XCTAssertEqual(replayFacts[1].id, f2.id)
        XCTAssertEqual(replayFacts[2].id, f3.id)
    }

    func testReplayAndAllFactsProduceSameOrder() async throws {
        let (reader, engine) = try await makeReaderAndEngine()

        for i in 0..<5 {
            try await appendFact(
                to: engine,
                occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 500))
            )
        }

        let allFacts = try await reader.allFacts()
        let replayFacts = try await reader.replay()

        XCTAssertEqual(allFacts.map(\.id), replayFacts.map(\.id))
    }

    // MARK: - Corrections query

    func testCorrectionsForFactIDReturnsOnlyRelatedCorrections() async throws {
        let engine = try await RecordEngine(store: InMemoryRecordStore())
        let reader = RecordReader(engine: engine)

        let target = try await appendFact(to: engine)
        let other = try await appendFact(to: engine)

        let correction = Fact(
            id: UUID(),
            kind: .correctionSubmitted,
            payload: .correctionSubmitted(CorrectionPayload(
                targetFactID: target.id,
                field: "value",
                correctedValue: "2.0",
                reason: "typo"
            )),
            provenance: FactProvenance(
                source: .correction,
                author: .person,
                entryMethod: .explicit,
                confidence: .known,
                sourceIdentifier: nil,
                externalTimestamp: nil
            ),
            recordedAt: Date(),
            occurredAt: Date()
        )
        try await engine.append(correction)

        let corrections = try await reader.corrections(for: target.id)
        XCTAssertEqual(corrections.count, 1)
        XCTAssertEqual(corrections.first?.id, correction.id)

        let wrongCorrections = try await reader.corrections(for: other.id)
        XCTAssertEqual(wrongCorrections.count, 0)
    }
}
