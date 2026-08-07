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

    /// Returns a valid FactDraft. All fields produce a fact that passes DefaultFactValidator.
    private func makeDraft(
        id: UUID = UUID(),
        kind: FactKind = .habitLogged,
        occurredAt: Date = Date()
    ) -> FactDraft {
        let payload: FactPayload
        switch kind {
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
        return FactDraft(
            id: id,
            kind: kind,
            payload: payload,
            occurredAt: occurredAt,
            source: .userEntry,
            author: .person,
            entryMethod: .explicit,
            confidence: .known
        )
    }

    /// A sensor draft whose dedup key matches any other sensorDraft with the same sampleType + timestamp.
    private func sensorDraft(
        id: UUID = UUID(),
        sampleType: String = "HKStepCount",
        value: Double = 100,
        occurredAt: Date = Date(timeIntervalSinceReferenceDate: 1_000_000)
    ) -> FactDraft {
        FactDraft(
            id: id,
            kind: .healthSampleImported,
            payload: .healthSampleImported(HealthSamplePayload(
                sampleType: sampleType, value: value, unit: "count",
                startDate: occurredAt, endDate: occurredAt
            )),
            occurredAt: occurredAt,
            source: .healthKit,
            author: .sensor,
            entryMethod: .imported,
            confidence: .high,
            sourceIdentifier: sampleType,
            externalTimestamp: occurredAt
        )
    }

    // MARK: - Append-only: no mutation path exists

    func testAppendedFactIsRetrievable() async throws {
        let engine = try await makeEngine()
        let draft = makeDraft()

        try await engine.append(draft)

        let retrieved = try await engine.allFacts()
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.id, draft.id)
    }

    func testAppendedFactFieldsArePreserved() async throws {
        let engine = try await makeEngine()
        let id = UUID()
        let occurredAt = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let draft = makeDraft(id: id, occurredAt: occurredAt)

        try await engine.append(draft)

        let retrieved = try await engine.allFacts()
        XCTAssertEqual(retrieved.first?.id, id)
        XCTAssertEqual(retrieved.first?.occurredAt, occurredAt)
        XCTAssertEqual(retrieved.first?.kind, .habitLogged)
    }

    // MARK: - No duplicate IDs

    func testDuplicateIDIsRejected() async throws {
        let engine = try await makeEngine()
        let draft = makeDraft()

        try await engine.append(draft)

        do {
            try await engine.append(draft)
            XCTFail("Expected RecordError.duplicateFact, but no error was thrown")
        } catch RecordError.duplicateFact(let existingID) {
            XCTAssertEqual(existingID, draft.id)
        }
    }

    func testDifferentIDsAreAccepted() async throws {
        let engine = try await makeEngine()

        try await engine.append(makeDraft(id: UUID()))
        try await engine.append(makeDraft(id: UUID()))
        try await engine.append(makeDraft(id: UUID()))

        let count = try await engine.count(matching: .all)
        XCTAssertEqual(count, 3)
    }

    func testDuplicateIDDoesNotCorruptCount() async throws {
        let engine = try await makeEngine()
        let draft = makeDraft()

        try await engine.append(draft)
        try? await engine.append(draft) // swallow error

        let count = try await engine.count(matching: .all)
        XCTAssertEqual(count, 1, "Duplicate must not double-count")
    }

    // MARK: - Sensor deduplication (idempotent, not an error)

    func testSensorDedupKeyPreventsDoubleCounting() async throws {
        let engine = try await makeEngine()
        let ts = Date(timeIntervalSinceReferenceDate: 1_000_000)

        // Two sensor drafts with identical sampleType + externalTimestamp → same dedup key
        let draft1 = sensorDraft(id: UUID(), sampleType: "HKStepCount", occurredAt: ts)
        let draft2 = sensorDraft(id: UUID(), sampleType: "HKStepCount", occurredAt: ts)

        try await engine.append(draft1)
        try await engine.append(draft2) // same dedup key → silently dropped

        let count = try await engine.count(matching: .all)
        XCTAssertEqual(count, 1, "Second write with same dedup key must be silently dropped")
    }

    func testSensorDedupIsNotAnError() async throws {
        let engine = try await makeEngine()
        let ts = Date(timeIntervalSinceReferenceDate: 2_000_000)

        let draft1 = sensorDraft(id: UUID(), occurredAt: ts)
        let draft2 = sensorDraft(id: UUID(), occurredAt: ts)

        try await engine.append(draft1)
        // Should NOT throw — if it does, the test fails via the implicit rethrow
        try await engine.append(draft2)
    }

    func testDifferentDedupKeysAreAccepted() async throws {
        let engine = try await makeEngine()
        let t1 = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let t2 = Date(timeIntervalSinceReferenceDate: 2_000_000)

        // Different externalTimestamp → different dedup key
        let draft1 = sensorDraft(id: UUID(), occurredAt: t1)
        let draft2 = sensorDraft(id: UUID(), occurredAt: t2)

        try await engine.append(draft1)
        try await engine.append(draft2)

        let count = try await engine.count(matching: .all)
        XCTAssertEqual(count, 2)
    }

    // MARK: - Timestamp preservation

    func testRecordedAtIsSetAtWriteTime() async throws {
        let engine = try await makeEngine()
        let before = Date()
        let draft = makeDraft()
        let fact = try await engine.append(draft)
        let after = Date()

        XCTAssertGreaterThanOrEqual(fact.recordedAt, before.addingTimeInterval(-1))
        XCTAssertLessThanOrEqual(fact.recordedAt, after.addingTimeInterval(1))
    }

    func testOccurredAtIsDistinctFromRecordedAt() async throws {
        let engine = try await makeEngine()
        let pastDate = Date(timeIntervalSinceReferenceDate: 500_000)

        // A sensor draft with occurredAt in the past; recordedAt will be set to now by engine
        let draft = sensorDraft(id: UUID(), occurredAt: pastDate)
        try await engine.append(draft)

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

        // Append out of occurredAt order; allFacts() must return insertion order
        try await engine.append(makeDraft(id: UUID(), occurredAt: t3))
        try await engine.append(makeDraft(id: UUID(), occurredAt: t1))
        try await engine.append(makeDraft(id: UUID(), occurredAt: t2))

        let facts = try await engine.allFacts()
        XCTAssertEqual(facts.count, 3)
        // Insertion order: t3, t1, t2
        XCTAssertEqual(facts[0].occurredAt, t3)
        XCTAssertEqual(facts[1].occurredAt, t1)
        XCTAssertEqual(facts[2].occurredAt, t2)
    }

    func testQuerySortsOccurredAtAscending() async throws {
        let engine = try await makeEngine()
        let t1 = Date(timeIntervalSinceReferenceDate: 1_000)
        let t2 = Date(timeIntervalSinceReferenceDate: 2_000)
        let t3 = Date(timeIntervalSinceReferenceDate: 3_000)

        try await engine.append(makeDraft(id: UUID(), occurredAt: t3))
        try await engine.append(makeDraft(id: UUID(), occurredAt: t1))
        try await engine.append(makeDraft(id: UUID(), occurredAt: t2))

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

        try await engine.append(makeDraft(id: UUID(), occurredAt: t1))
        try await engine.append(makeDraft(id: UUID(), occurredAt: t2))
        try await engine.append(makeDraft(id: UUID(), occurredAt: t3))

        let query = RecordQuery(order: .occurredAtDescending)
        let facts = try await engine.facts(matching: query)
        XCTAssertEqual(facts[0].occurredAt, t3)
        XCTAssertEqual(facts[1].occurredAt, t2)
        XCTAssertEqual(facts[2].occurredAt, t1)
    }

    // MARK: - Filtering

    func testKindFilter() async throws {
        let engine = try await makeEngine()

        try await engine.append(makeDraft(id: UUID(), kind: .habitLogged))
        try await engine.append(makeDraft(id: UUID(), kind: .reflectionWritten))
        try await engine.append(makeDraft(id: UUID(), kind: .habitLogged))

        let habits = try await engine.facts(matching: .kind(.habitLogged))
        XCTAssertEqual(habits.count, 2)

        let reflections = try await engine.facts(matching: .kind(.reflectionWritten))
        XCTAssertEqual(reflections.count, 1)
    }

    func testDateRangeFilter() async throws {
        let engine = try await makeEngine()
        let inRange = Date(timeIntervalSinceReferenceDate: 1_500)
        let outOfRange = Date(timeIntervalSinceReferenceDate: 500)

        try await engine.append(makeDraft(id: UUID(), occurredAt: inRange))
        try await engine.append(makeDraft(id: UUID(), occurredAt: outOfRange))

        let range = RecordDateRange(
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
            try await engine.append(makeDraft(
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
        let draft = makeDraft()
        try await engine.append(draft)
        let result = await engine.contains(factID: draft.id)
        XCTAssertTrue(result)
    }

    func testContainsReturnsFalseForUnwrittenFact() async throws {
        let engine = try await makeEngine()
        let result = await engine.contains(factID: UUID())
        XCTAssertFalse(result)
    }

    // MARK: - Event subscription

    /// Collector for event-subscription tests.
    /// @unchecked Sendable is intentional: handlers fire synchronously on the
    /// actor executor, then the test immediately reads — no concurrent mutation.
    private final class EventCapture: @unchecked Sendable {
        var events: [FactWrittenEvent] = []
        func collect(_ event: FactWrittenEvent) { events.append(event) }
    }

    private final class CallCounter: @unchecked Sendable {
        var count = 0
        func increment() { count += 1 }
    }

    func testFactWrittenEventFires() async throws {
        let engine = try await makeEngine()
        let draft = makeDraft()
        let capture = EventCapture()

        await engine.onFactWritten { event in capture.collect(event) }

        try await engine.append(draft)
        XCTAssertEqual(capture.events.count, 1)
        XCTAssertEqual(capture.events.first?.fact.id, draft.id)
    }

    func testFactWrittenEventDoesNotFireOnDuplicate() async throws {
        let engine = try await makeEngine()
        let draft = makeDraft()
        let counter = CallCounter()

        await engine.onFactWritten { _ in counter.increment() }

        try await engine.append(draft)
        try? await engine.append(draft) // duplicate → throws, no event

        XCTAssertEqual(counter.count, 1, "Event must not fire for duplicate write")
    }

    func testFactWrittenEventDoesNotFireOnSensorDedup() async throws {
        let engine = try await makeEngine()
        let ts = Date(timeIntervalSinceReferenceDate: 9_000_000)
        let counter = CallCounter()

        await engine.onFactWritten { _ in counter.increment() }

        try await engine.append(sensorDraft(id: UUID(), occurredAt: ts))
        try await engine.append(sensorDraft(id: UUID(), occurredAt: ts)) // silently dropped

        XCTAssertEqual(counter.count, 1, "Event must not fire for sensor-deduped write")
    }

    // MARK: - Invariant validation

    func testValidateInvariantsPassesOnCleanEngine() async throws {
        let engine = try await makeEngine()
        try await engine.append(makeDraft())
        try await engine.append(makeDraft())
        try await engine.validateInvariants(expectedCount: 2)
    }

    func testEmptyEnginePassesValidation() async throws {
        let engine = try await makeEngine()
        try await engine.validateInvariants(expectedCount: 0)
    }
}
