import XCTest
@testable import LOCA

/// Tests for RecordEngine invariants:
///  - Append-only
///  - No duplicate IDs
///  - Sensor deduplication
///  - Single-writer serialization
///  - Timestamp preservation
///  - Ordering guarantees
final class RecordEngineTests: XCTestCase {

    // MARK: - Helpers

    private func makeEngine() async throws -> RecordEngine {
        try await RecordEngine(store: InMemoryRecordStore())
    }

    private func makeFact(
        id: UUID = UUID(),
        kind: FactKind = .habitLogged,
        occurredAt: Date = Date()
    ) -> Fact {
        Fact(
            id: id,
            kind: kind,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil)),
            provenance: FactProvenance(
                source: .userEntry,
                author: .person,
                entryMethod: .explicit,
                confidence: .known,
                sourceIdentifier: nil,
                externalTimestamp: nil
            ),
            recordedAt: occurredAt,
            occurredAt: occurredAt
        )
    }

    // MARK: - Append-only: no mutation path exists

    func testAppendedFactIsRetrievable() async throws {
        let engine = try await makeEngine()
        let fact = makeFact()

        try await engine.append(fact)

        let retrieved = try await engine.allFacts()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, fact.id)
    }

    func testAppendedFactFieldsArePreserved() async throws {
        let engine = try await makeEngine()
        let id = UUID()
        let occurredAt = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let fact = makeFact(id: id, occurredAt: occurredAt)

        try await engine.append(fact)

        let retrieved = try await engine.allFacts()
        XCTAssertEqual(retrieved.first?.id, id)
        XCTAssertEqual(retrieved.first?.occurredAt, occurredAt)
        XCTAssertEqual(retrieved.first?.kind, .habitLogged)
    }

    // MARK: - No duplicate IDs

    func testDuplicateIDIsRejected() async throws {
        let engine = try await makeEngine()
        let fact = makeFact()

        try await engine.append(fact)

        do {
            try await engine.append(fact)
            XCTFail("Expected RecordError.duplicateFact, but no error was thrown")
        } catch RecordError.duplicateFact(let existingID) {
            XCTAssertEqual(existingID, fact.id)
        }
    }

    func testDifferentIDsAreAccepted() async throws {
        let engine = try await makeEngine()

        try await engine.append(makeFact(id: UUID()))
        try await engine.append(makeFact(id: UUID()))
        try await engine.append(makeFact(id: UUID()))

        let count = try await engine.count(matching: .all)
        XCTAssertEqual(count, 3)
    }

    func testDuplicateIDDoesNotCorruptCount() async throws {
        let engine = try await makeEngine()
        let fact = makeFact()

        try await engine.append(fact)
        try? await engine.append(fact) // swallow error

        let count = try await engine.count(matching: .all)
        XCTAssertEqual(count, 1, "Duplicate must not double-count")
    }

    // MARK: - Sensor deduplication (idempotent, not an error)

    func testSensorDedupKeyPreventsDoubleCounting() async throws {
        let engine = try await makeEngine()
        let dedupKey = "healthSampleImported:HKStepCount:1000000.0"

        let fact1 = makeFact(id: UUID())
        let fact2 = makeFact(id: UUID())

        try await engine.append(fact1, dedupKey: dedupKey)
        try await engine.append(fact2, dedupKey: dedupKey) // same key → silently dropped

        let count = try await engine.count(matching: .all)
        XCTAssertEqual(count, 1, "Second write with same dedup key must be silently dropped")
    }

    func testSensorDedupIsNotAnError() async throws {
        let engine = try await makeEngine()
        let dedupKey = "healthSampleImported:HKStepCount:2000000.0"

        let fact1 = makeFact(id: UUID())
        let fact2 = makeFact(id: UUID())

        try await engine.append(fact1, dedupKey: dedupKey)
        // Should NOT throw — if it does, the test fails via the implicit rethrow
        try await engine.append(fact2, dedupKey: dedupKey)
    }

    func testDifferentDedupKeysAreAccepted() async throws {
        let engine = try await makeEngine()

        let fact1 = makeFact(id: UUID())
        let fact2 = makeFact(id: UUID())

        try await engine.append(fact1, dedupKey: "key:A:1000")
        try await engine.append(fact2, dedupKey: "key:A:2000") // different key

        let count = try await engine.count(matching: .all)
        XCTAssertEqual(count, 2)
    }

    // MARK: - Timestamp preservation

    func testRecordedAtIsSetAtWriteTime() async throws {
        let engine = try await makeEngine()
        let before = Date()
        let fact = makeFact()
        try await engine.append(fact)
        let after = Date()

        // Note: in our architecture, recordedAt is set by RecordWriter, not RecordEngine.
        // RecordEngine receives an already-stamped Fact. So we verify the fact's
        // recordedAt is within the expected window.
        let retrieved = try await engine.allFacts()
        let retrievedFact = try XCTUnwrap(retrieved.first)

        // The fact was created with occurredAt = Date(), which should be within window
        XCTAssertGreaterThanOrEqual(retrievedFact.recordedAt, before.addingTimeInterval(-1))
        XCTAssertLessThanOrEqual(retrievedFact.recordedAt, after.addingTimeInterval(1))
    }

    func testOccurredAtIsDistinctFromRecordedAt() async throws {
        let engine = try await makeEngine()
        let pastDate = Date(timeIntervalSinceReferenceDate: 500_000)
        let fact = Fact(
            id: UUID(),
            kind: .healthSampleImported,
            payload: .healthSampleImported(HealthSamplePayload(
                sampleType: "HKStepCount",
                value: 5000,
                unit: "count",
                startDate: pastDate,
                endDate: pastDate
            )),
            provenance: FactProvenance(
                source: .healthKit,
                author: .sensor,
                entryMethod: .imported,
                confidence: .high,
                sourceIdentifier: "HKStepCount",
                externalTimestamp: pastDate
            ),
            recordedAt: Date(),
            occurredAt: pastDate
        )

        try await engine.append(fact)

        let retrieved = try await engine.allFacts()
        let retrievedFact = try XCTUnwrap(retrieved.first)
        XCTAssertEqual(retrievedFact.occurredAt, pastDate)
        XCTAssertNotEqual(retrievedFact.occurredAt, retrievedFact.recordedAt)
    }

    // MARK: - Ordering

    func testAllFactsReturnsChronologicalOrder() async throws {
        let engine = try await makeEngine()
        let t1 = Date(timeIntervalSinceReferenceDate: 1_000)
        let t2 = Date(timeIntervalSinceReferenceDate: 2_000)
        let t3 = Date(timeIntervalSinceReferenceDate: 3_000)

        // Append out of order
        try await engine.append(makeFact(id: UUID(), occurredAt: t3))
        try await engine.append(makeFact(id: UUID(), occurredAt: t1))
        try await engine.append(makeFact(id: UUID(), occurredAt: t2))

        let facts = try await engine.allFacts()
        XCTAssertEqual(facts.count, 3)
        // allFacts() sorts by recordedAt ascending (append order)
        // Since we appended in t3, t1, t2 order, recordedAt ordering is that order
        XCTAssertEqual(facts[0].occurredAt, t3)
        XCTAssertEqual(facts[1].occurredAt, t1)
        XCTAssertEqual(facts[2].occurredAt, t2)
    }

    func testQuerySortsOccurredAtAscending() async throws {
        let engine = try await makeEngine()
        let t1 = Date(timeIntervalSinceReferenceDate: 1_000)
        let t2 = Date(timeIntervalSinceReferenceDate: 2_000)
        let t3 = Date(timeIntervalSinceReferenceDate: 3_000)

        try await engine.append(makeFact(id: UUID(), occurredAt: t3))
        try await engine.append(makeFact(id: UUID(), occurredAt: t1))
        try await engine.append(makeFact(id: UUID(), occurredAt: t2))

        let query = RecordQuery(order: .occurredAtAscending)
        let facts = try await engine.facts(matching: query)
        XCTAssertEqual(facts[0].occurredAt, t1)
        XCTAssertEqual(facts[1].occurredAt, t2)
        XCTAssertEqual(facts[2].occurredAt, t3)
    }

    func testQuerySortsOccurredAtDescending() async throws {
        let engine = try await makeEngine()
        let t1 = Date(timeIntervalSinceReferenceDate: 1_000)
        let t2 = Date(timeIntervalSinceReferenceDate: 2_000)
        let t3 = Date(timeIntervalSinceReferenceDate: 3_000)

        try await engine.append(makeFact(id: UUID(), occurredAt: t1))
        try await engine.append(makeFact(id: UUID(), occurredAt: t2))
        try await engine.append(makeFact(id: UUID(), occurredAt: t3))

        let query = RecordQuery(order: .occurredAtDescending)
        let facts = try await engine.facts(matching: query)
        XCTAssertEqual(facts[0].occurredAt, t3)
        XCTAssertEqual(facts[1].occurredAt, t2)
        XCTAssertEqual(facts[2].occurredAt, t1)
    }

    // MARK: - Filtering

    func testKindFilter() async throws {
        let engine = try await makeEngine()

        try await engine.append(makeFact(id: UUID(), kind: .habitLogged))
        try await engine.append(makeFact(id: UUID(), kind: .reflectionWritten))
        try await engine.append(makeFact(id: UUID(), kind: .habitLogged))

        let habits = try await engine.facts(matching: .kind(.habitLogged))
        XCTAssertEqual(habits.count, 2)

        let reflections = try await engine.facts(matching: .kind(.reflectionWritten))
        XCTAssertEqual(reflections.count, 1)
    }

    func testDateRangeFilter() async throws {
        let engine = try await makeEngine()
        let inRange = Date(timeIntervalSinceReferenceDate: 1_500)
        let outOfRange = Date(timeIntervalSinceReferenceDate: 500)

        try await engine.append(makeFact(id: UUID(), occurredAt: inRange))
        try await engine.append(makeFact(id: UUID(), occurredAt: outOfRange))

        let range = DateRange(
            start: Date(timeIntervalSinceReferenceDate: 1_000),
            end: Date(timeIntervalSinceReferenceDate: 2_000)
        )
        let facts = try await engine.facts(matching: .inRange(range))
        XCTAssertEqual(facts.count, 1)
        XCTAssertEqual(facts.first?.occurredAt, inRange)
    }

    func testLimitAndOffset() async throws {
        let engine = try await makeEngine()
        for i in 0..<10 {
            try await engine.append(makeFact(
                id: UUID(),
                occurredAt: Date(timeIntervalSinceReferenceDate: Double(i * 1000))
            ))
        }

        let page1 = try await engine.facts(matching: RecordQuery(
            order: .occurredAtAscending, limit: 3, offset: 0
        ))
        XCTAssertEqual(page1.count, 3)

        let page2 = try await engine.facts(matching: RecordQuery(
            order: .occurredAtAscending, limit: 3, offset: 3
        ))
        XCTAssertEqual(page2.count, 3)
        XCTAssertNotEqual(page1.first?.id, page2.first?.id)
    }

    // MARK: - Contains

    func testContainsReturnsTrueForWrittenFact() async throws {
        let engine = try await makeEngine()
        let fact = makeFact()
        try await engine.append(fact)
        let result = await engine.contains(factID: fact.id)
        XCTAssertTrue(result)
    }

    func testContainsReturnsFalseForUnwrittenFact() async throws {
        let engine = try await makeEngine()
        let result = await engine.contains(factID: UUID())
        XCTAssertFalse(result)
    }

    // MARK: - Event subscription

    func testFactWrittenEventFires() async throws {
        let engine = try await makeEngine()
        let fact = makeFact()
        var received: [FactWrittenEvent] = []

        await engine.onFactWritten { event in
            received.append(event)
        }

        try await engine.append(fact)
        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first?.fact.id, fact.id)
    }

    func testFactWrittenEventDoesNotFireOnDuplicate() async throws {
        let engine = try await makeEngine()
        let fact = makeFact()
        var count = 0

        await engine.onFactWritten { _ in count += 1 }

        try await engine.append(fact)
        try? await engine.append(fact)

        XCTAssertEqual(count, 1, "Event must not fire for duplicate write")
    }

    func testFactWrittenEventDoesNotFireOnSensorDedup() async throws {
        let engine = try await makeEngine()
        let key = "test:key:1234"
        var count = 0

        await engine.onFactWritten { _ in count += 1 }

        try await engine.append(makeFact(id: UUID()), dedupKey: key)
        try await engine.append(makeFact(id: UUID()), dedupKey: key) // silently dropped

        XCTAssertEqual(count, 1, "Event must not fire for sensor-deduped write")
    }

    // MARK: - Invariant validation

    func testValidateInvariantsPassesOnCleanEngine() async throws {
        let engine = try await makeEngine()
        try await engine.append(makeFact())
        try await engine.append(makeFact())
        try await engine.validateInvariants(expectedCount: 2)
    }

    func testEmptyEnginePassesValidation() async throws {
        let engine = try await makeEngine()
        try await engine.validateInvariants(expectedCount: 0)
    }
}
