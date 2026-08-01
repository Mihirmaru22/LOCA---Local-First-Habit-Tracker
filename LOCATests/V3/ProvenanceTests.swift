import XCTest
@testable import LOCA

/// Tests for provenance completeness invariant (I4):
///  - Every written Fact carries a fully populated FactProvenance
///  - Source, author, entryMethod, confidence are never nil
///  - Optional fields (sourceIdentifier, externalTimestamp) are present when expected
///  - Writer enforces provenance integrity end-to-end
///  - All FactSource cases are accepted by the engine
final class ProvenanceTests: XCTestCase {

    // MARK: - Helpers

    private func makeEngine() async throws -> RecordEngine {
        try await RecordEngine(store: InMemoryRecordStore())
    }

    private func makeWriter(engine: RecordEngine) -> RecordWriter {
        RecordWriter(engine: engine)
    }

    private func makeFact(
        source: FactSource = .userEntry,
        author: FactAuthor = .person,
        entryMethod: EntryMethod = .explicit,
        confidence: FactConfidence = .known,
        sourceIdentifier: String? = nil,
        externalTimestamp: Date? = nil
    ) -> Fact {
        Fact(
            id: UUID(),
            kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil)),
            provenance: FactProvenance(
                source: source,
                author: author,
                entryMethod: entryMethod,
                confidence: confidence,
                sourceIdentifier: sourceIdentifier,
                externalTimestamp: externalTimestamp
            ),
            recordedAt: Date(),
            occurredAt: Date()
        )
    }

    // MARK: - All sources accepted

    func testAllFactSourceCasesAreAccepted() async throws {
        let engine = try await makeEngine()

        for source in FactSource.allCases {
            let fact = makeFact(source: source)
            try await engine.append(fact)
        }

        let count = try await engine.count(matching: .all)
        XCTAssertEqual(count, FactSource.allCases.count)
    }

    // MARK: - Provenance fields preserved end-to-end

    func testProvenanceFieldsArePreservedThroughEngine() async throws {
        let engine = try await makeEngine()
        let ts = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let fact = makeFact(
            source: .healthKit,
            author: .sensor,
            entryMethod: .imported,
            confidence: .high,
            sourceIdentifier: "HKStepCount",
            externalTimestamp: ts
        )

        try await engine.append(fact)

        let retrieved = try await engine.allFacts()
        let p = try XCTUnwrap(retrieved.first?.provenance)
        XCTAssertEqual(p.source, .healthKit)
        XCTAssertEqual(p.author, .sensor)
        XCTAssertEqual(p.entryMethod, .imported)
        XCTAssertEqual(p.confidence, .high)
        XCTAssertEqual(p.sourceIdentifier, "HKStepCount")
        XCTAssertEqual(p.externalTimestamp, ts)
    }

    func testUserEntryProvenanceIsPreserved() async throws {
        let engine = try await makeEngine()
        let fact = makeFact(source: .userEntry, author: .person, entryMethod: .explicit, confidence: .known)

        try await engine.append(fact)

        let retrieved = try await engine.allFacts()
        let p = try XCTUnwrap(retrieved.first?.provenance)
        XCTAssertEqual(p.source, .userEntry)
        XCTAssertEqual(p.author, .person)
        XCTAssertEqual(p.entryMethod, .explicit)
        XCTAssertEqual(p.confidence, .known)
        XCTAssertNil(p.sourceIdentifier)
        XCTAssertNil(p.externalTimestamp)
    }

    // MARK: - Writer provenance assembly

    func testWriterAssemblesProvenanceFromDraft() async throws {
        let engine = try await makeEngine()
        let writer = makeWriter(engine: engine)
        let ts = Date(timeIntervalSinceReferenceDate: 500_000)

        let draft = FactDraft(
            id: UUID(),
            kind: .healthSampleImported,
            payload: .healthSampleImported(HealthSamplePayload(
                sampleType: "HKHeartRate",
                value: 72,
                unit: "bpm",
                startDate: ts,
                endDate: ts
            )),
            occurredAt: ts,
            source: .healthKit,
            author: .sensor,
            entryMethod: .imported,
            confidence: .high,
            sourceIdentifier: "HKHeartRate",
            externalTimestamp: ts
        )

        let fact = try await writer.write(draft)
        XCTAssertEqual(fact.provenance.source, .healthKit)
        XCTAssertEqual(fact.provenance.author, .sensor)
        XCTAssertEqual(fact.provenance.entryMethod, .imported)
        XCTAssertEqual(fact.provenance.confidence, .high)
        XCTAssertEqual(fact.provenance.sourceIdentifier, "HKHeartRate")
        XCTAssertEqual(fact.provenance.externalTimestamp, ts)
    }

    // MARK: - Confidence ordering

    func testConfidenceLevelsAreOrdered() {
        XCTAssertLessThan(FactConfidence.low, .medium)
        XCTAssertLessThan(FactConfidence.medium, .high)
        XCTAssertLessThan(FactConfidence.high, .known)
    }

    // MARK: - No anonymous facts

    func testEveryFactInReplayHasFullProvenance() async throws {
        let engine = try await makeEngine()

        for source in FactSource.allCases {
            let fact = makeFact(source: source, confidence: .known)
            try await engine.append(fact)
        }

        let replay = try await engine.replayableFacts()
        for fact in replay {
            // Provenance fields are non-optional by type; this verifies they compile and are accessible
            _ = fact.provenance.source
            _ = fact.provenance.author
            _ = fact.provenance.entryMethod
            _ = fact.provenance.confidence
            // Verifying the fact participates in the replay at all is the invariant
            XCTAssertNotNil(fact.id)
        }
        XCTAssertEqual(replay.count, FactSource.allCases.count,
                       "Every appended fact must appear in replay")
    }

    // MARK: - Correction provenance

    func testCorrectionFactHasCorrectionSource() async throws {
        let engine = try await makeEngine()
        let writer = makeWriter(engine: engine)

        // Write original
        let original = FactDraft(
            id: UUID(),
            kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil)),
            occurredAt: Date(),
            source: .userEntry, author: .person, entryMethod: .explicit, confidence: .known,
            sourceIdentifier: nil, externalTimestamp: nil
        )
        let originalFact = try await writer.write(original)

        // Write correction
        let correction = FactDraft.correction(
            targetFactID: originalFact.id,
            field: "value",
            correctedValue: "2.0",
            reason: "logged wrong value"
        )
        let correctionFact = try await writer.write(correction)

        XCTAssertEqual(correctionFact.provenance.source, .correction)
        XCTAssertEqual(correctionFact.provenance.entryMethod, .explicit)
    }

    // MARK: - Codable round-trip

    func testProvenanceRoundTripsJSON() throws {
        let original = FactProvenance(
            source: .healthKit,
            author: .sensor,
            entryMethod: .imported,
            confidence: .high,
            sourceIdentifier: "HKStepCount",
            externalTimestamp: Date(timeIntervalSinceReferenceDate: 1_000_000)
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FactProvenance.self, from: data)

        XCTAssertEqual(decoded.source, original.source)
        XCTAssertEqual(decoded.author, original.author)
        XCTAssertEqual(decoded.entryMethod, original.entryMethod)
        XCTAssertEqual(decoded.confidence, original.confidence)
        XCTAssertEqual(decoded.sourceIdentifier, original.sourceIdentifier)
        XCTAssertEqual(decoded.externalTimestamp?.timeIntervalSinceReferenceDate,
                       original.externalTimestamp?.timeIntervalSinceReferenceDate,
                       accuracy: 0.001)
    }
}
