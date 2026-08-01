import XCTest
@testable import LOCA

/// Tests for RecordWriter pipeline invariants:
///  - Validation gate (invalid drafts rejected before the Record is touched)
///  - Provenance assembly (all fields populated on the written Fact)
///  - Timestamp stamping (recordedAt set at write time, occurredAt preserved)
///  - Deduplication key forwarded to engine (sensor dedup via writer)
///  - Single-path contract: every fact enters the Record through write(_:)
final class RecordWriterTests: XCTestCase {

    // MARK: - Helpers

    private func makeWriter() async throws -> RecordWriter {
        let engine = try await RecordEngine(store: InMemoryRecordStore())
        return RecordWriter(engine: engine)
    }

    private func makeEngine() async throws -> RecordEngine {
        try await RecordEngine(store: InMemoryRecordStore())
    }

    private func habitDraft(
        id: UUID = UUID(),
        occurredAt: Date = Date(),
        source: FactSource = .userEntry,
        author: FactAuthor = .person,
        entryMethod: EntryMethod = .explicit,
        confidence: FactConfidence = .known
    ) -> FactDraft {
        FactDraft(
            id: id,
            kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil)),
            occurredAt: occurredAt,
            source: source,
            author: author,
            entryMethod: entryMethod,
            confidence: confidence,
            sourceIdentifier: nil,
            externalTimestamp: nil
        )
    }

    private func healthDraft(
        sampleType: String = "HKStepCount",
        value: Double = 5000,
        occurredAt: Date = Date()
    ) -> FactDraft {
        FactDraft(
            id: UUID(),
            kind: .healthSampleImported,
            payload: .healthSampleImported(HealthSamplePayload(
                sampleType: sampleType,
                value: value,
                unit: "count",
                startDate: occurredAt,
                endDate: occurredAt
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

    // MARK: - Basic write

    func testWriteReturnsFactWithCorrectKind() async throws {
        let writer = try await makeWriter()
        let draft = habitDraft()

        let fact = try await writer.write(draft)

        XCTAssertEqual(fact.kind, .habitLogged)
    }

    func testWritePreservesOccurredAt() async throws {
        let writer = try await makeWriter()
        let ts = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let draft = habitDraft(occurredAt: ts)

        let fact = try await writer.write(draft)

        XCTAssertEqual(fact.occurredAt, ts)
    }

    func testWritePreservesDraftID() async throws {
        let writer = try await makeWriter()
        let id = UUID()
        let draft = habitDraft(id: id)

        let fact = try await writer.write(draft)

        XCTAssertEqual(fact.id, id)
    }

    func testWriteSetsRecordedAtNear() async throws {
        let writer = try await makeWriter()
        let before = Date()
        let draft = habitDraft()
        let fact = try await writer.write(draft)
        let after = Date()

        XCTAssertGreaterThanOrEqual(fact.recordedAt, before.addingTimeInterval(-1))
        XCTAssertLessThanOrEqual(fact.recordedAt, after.addingTimeInterval(1))
    }

    // MARK: - Provenance assembly

    func testProvenanceSourceIsPreserved() async throws {
        let writer = try await makeWriter()
        let draft = habitDraft(source: .userEntry)

        let fact = try await writer.write(draft)

        XCTAssertEqual(fact.provenance.source, .userEntry)
    }

    func testProvenanceAuthorIsPreserved() async throws {
        let writer = try await makeWriter()
        let draft = habitDraft(author: .person)

        let fact = try await writer.write(draft)

        XCTAssertEqual(fact.provenance.author, .person)
    }

    func testProvenanceEntryMethodIsPreserved() async throws {
        let writer = try await makeWriter()
        let draft = habitDraft(entryMethod: .explicit)

        let fact = try await writer.write(draft)

        XCTAssertEqual(fact.provenance.entryMethod, .explicit)
    }

    func testProvenanceConfidenceIsPreserved() async throws {
        let writer = try await makeWriter()
        let draft = habitDraft(confidence: .known)

        let fact = try await writer.write(draft)

        XCTAssertEqual(fact.provenance.confidence, .known)
    }

    func testSensorProvenanceCarriesSourceIdentifier() async throws {
        let writer = try await makeWriter()
        let draft = healthDraft(sampleType: "HKStepCount")

        let fact = try await writer.write(draft)

        XCTAssertEqual(fact.provenance.sourceIdentifier, "HKStepCount")
    }

    func testSensorProvenanceCarriesExternalTimestamp() async throws {
        let writer = try await makeWriter()
        let ts = Date(timeIntervalSinceReferenceDate: 500_000)
        let draft = healthDraft(occurredAt: ts)

        let fact = try await writer.write(draft)

        XCTAssertEqual(fact.provenance.externalTimestamp, ts)
    }

    // MARK: - Validation gate

    func testInvalidDraftIsRejectedBeforeEngineIsWritten() async throws {
        let engine = try await makeEngine()
        let writer = RecordWriter(engine: engine)

        // An empty habitID is not currently validated, so use payload mismatch:
        // Write a draft whose kind doesn't match its payload
        let mismatchedDraft = FactDraft(
            id: UUID(),
            kind: .reflectionWritten,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil)),
            occurredAt: Date(),
            source: .userEntry,
            author: .person,
            entryMethod: .explicit,
            confidence: .known,
            sourceIdentifier: nil,
            externalTimestamp: nil
        )

        do {
            _ = try await writer.write(mismatchedDraft)
            XCTFail("Expected RecordError.invalidFact but no error was thrown")
        } catch RecordError.invalidFact {
            // correct
        }

        let count = try await engine.count(matching: .all)
        XCTAssertEqual(count, 0, "Record must not be written when validation fails")
    }

    // MARK: - Deduplication key forwarding

    func testSensorDeduplicationKeyPreventsDoubleWrite() async throws {
        let engine = try await makeEngine()
        let writer = RecordWriter(engine: engine)
        let ts = Date(timeIntervalSinceReferenceDate: 1_000_000)

        let draft1 = healthDraft(sampleType: "HKStepCount", value: 5000, occurredAt: ts)
        let draft2 = healthDraft(sampleType: "HKStepCount", value: 5000, occurredAt: ts)

        _ = try await writer.write(draft1)
        _ = try await writer.write(draft2) // same dedup key → silently dropped

        let count = try await engine.count(matching: .all)
        XCTAssertEqual(count, 1, "Sensor dedup must prevent double-write via writer")
    }

    func testDifferentSensorSamplesAreAccepted() async throws {
        let engine = try await makeEngine()
        let writer = RecordWriter(engine: engine)
        let t1 = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let t2 = Date(timeIntervalSinceReferenceDate: 2_000_000)

        let draft1 = healthDraft(sampleType: "HKStepCount", value: 5000, occurredAt: t1)
        let draft2 = healthDraft(sampleType: "HKStepCount", value: 7000, occurredAt: t2)

        _ = try await writer.write(draft1)
        _ = try await writer.write(draft2)

        let count = try await engine.count(matching: .all)
        XCTAssertEqual(count, 2)
    }

    // MARK: - Idempotency

    func testDuplicateDraftIDThrowsDuplicateFact() async throws {
        let writer = try await makeWriter()
        let id = UUID()
        let draft = habitDraft(id: id)

        _ = try await writer.write(draft)

        do {
            _ = try await writer.write(draft)
            XCTFail("Expected RecordError.duplicateFact")
        } catch RecordError.duplicateFact(let existingID) {
            XCTAssertEqual(existingID, id)
        }
    }

    // MARK: - Correction pipeline

    func testCorrectionDraftProducesCorrectKind() async throws {
        let engine = try await makeEngine()
        let writer = RecordWriter(engine: engine)

        let original = habitDraft()
        let originalFact = try await writer.write(original)

        let correctionDraft = FactDraft.correction(
            targetFactID: originalFact.id,
            field: "value",
            correctedValue: "2.0",
            reason: "wrong value"
        )
        let correctionFact = try await writer.write(correctionDraft)

        XCTAssertEqual(correctionFact.kind, .correctionSubmitted)
        XCTAssertEqual(correctionFact.provenance.source, .correction)
    }
}
