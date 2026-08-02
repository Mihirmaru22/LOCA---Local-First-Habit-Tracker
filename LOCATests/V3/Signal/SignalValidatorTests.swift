import XCTest
@testable import LOCA

/// Tests for SignalValidator:
///  - Clean signal set passes validation
///  - Orphan signal detection (S6)
///  - Duplicate signal detection (S1)
///  - Malformed timestamp detection
///  - Stale pipeline version detection
final class SignalValidatorTests: XCTestCase {

    // MARK: - Helpers

    private let validator = SignalValidator()

    private func makeFact(id: UUID = UUID(), occurredAt: Date = Date()) -> Fact {
        let prov = FactProvenance(
            source: .userEntry, author: .person, entryMethod: .explicit,
            confidence: .known, sourceIdentifier: nil, externalTimestamp: nil)
        return Fact(
            id: id, kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil)),
            provenance: prov,
            recordedAt: Date(timeIntervalSinceReferenceDate: 100_000),
            occurredAt: occurredAt)
    }

    private func makeSignal(
        forFact fact: Fact,
        pipelineVersion: Int = SignalPipeline.version,
        occurredAt: Date? = nil
    ) -> Signal {
        let now = Date()
        let prov = SignalProvenance(
            sourceFactID: fact.id,
            sourceFactKind: fact.kind,
            factRecordedAt: fact.recordedAt,
            factOccurredAt: fact.occurredAt,
            factSource: fact.provenance.source,
            factConfidence: fact.provenance.confidence,
            transformedAt: now,
            pipelineVersion: pipelineVersion)
        return Signal(
            id: fact.id,
            kind: .habitCompletion,
            payload: .habitCompletion(HabitCompletionSignal(habitID: UUID(), value: 1.0, note: nil)),
            provenance: prov,
            occurredAt: occurredAt ?? fact.occurredAt,
            producedAt: now)
    }

    // MARK: - Clean sets pass

    func testEmptySignalSetPassesValidation() {
        let result = validator.validate(signals: [], against: [])
        XCTAssertTrue(result.isValid)
    }

    func testCleanSignalSetPassesValidation() {
        let fact = makeFact()
        let signal = makeSignal(forFact: fact)
        let result = validator.validate(signals: [signal], against: [fact])
        XCTAssertTrue(result.isValid)
    }

    func testMultipleCleanSignalsPassValidation() {
        let f1 = makeFact(); let f2 = makeFact(); let f3 = makeFact()
        let s1 = makeSignal(forFact: f1)
        let s2 = makeSignal(forFact: f2)
        let s3 = makeSignal(forFact: f3)
        let result = validator.validate(signals: [s1, s2, s3], against: [f1, f2, f3])
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.orphanSignals.count, 0)
        XCTAssertEqual(result.duplicateSignals.count, 0)
        XCTAssertEqual(result.malformedSignals.count, 0)
    }

    // MARK: - Orphan detection (S6)

    func testOrphanSignalDetected() {
        let orphanFact = makeFact()
        let signal = makeSignal(forFact: orphanFact)
        // Validate against an empty fact set — signal's sourceFactID not found
        let result = validator.validate(signals: [signal], against: [])
        XCTAssertEqual(result.orphanSignals.count, 1)
        XCTAssertFalse(result.isValid)
    }

    func testSignalWithMatchingFactIsNotOrphan() {
        let fact = makeFact()
        let signal = makeSignal(forFact: fact)
        let result = validator.validate(signals: [signal], against: [fact])
        XCTAssertTrue(result.orphanSignals.isEmpty)
    }

    func testMixedOrphanAndCleanSignals() {
        let cleanFact = makeFact()
        let cleanSignal = makeSignal(forFact: cleanFact)
        let orphanSignal = makeSignal(forFact: makeFact())
        let result = validator.validate(signals: [cleanSignal, orphanSignal], against: [cleanFact])
        XCTAssertEqual(result.orphanSignals.count, 1)
        XCTAssertEqual(result.orphanSignals.first?.id, orphanSignal.id)
    }

    // MARK: - Duplicate detection (S1)

    func testDuplicateSignalsDetected() {
        let fact = makeFact()
        let s1 = makeSignal(forFact: fact)
        let s2 = makeSignal(forFact: fact)
        let result = validator.validate(signals: [s1, s2], against: [fact])
        XCTAssertEqual(result.duplicateSignals.count, 1)
        XCTAssertFalse(result.isValid)
    }

    func testTwoSignalsForDifferentFactsAreNotDuplicates() {
        let f1 = makeFact(); let f2 = makeFact()
        let s1 = makeSignal(forFact: f1); let s2 = makeSignal(forFact: f2)
        let result = validator.validate(signals: [s1, s2], against: [f1, f2])
        XCTAssertTrue(result.duplicateSignals.isEmpty)
    }

    func testThreeDuplicatesFlagsTwo() {
        let fact = makeFact()
        let s1 = makeSignal(forFact: fact)
        let s2 = makeSignal(forFact: fact)
        let s3 = makeSignal(forFact: fact)
        let result = validator.validate(signals: [s1, s2, s3], against: [fact])
        XCTAssertEqual(result.duplicateSignals.count, 2,
            "Second and third signals are duplicates; first is the legitimate one")
    }

    // MARK: - Malformed timestamp detection

    func testSignalWithFarFutureOccurredAtDetectedAsMalformed() {
        let fact = makeFact()
        let farFuture = Date().addingTimeInterval(1_000_000)
        let signal = makeSignal(forFact: fact, occurredAt: farFuture)
        let result = validator.validate(signals: [signal], against: [fact])
        XCTAssertFalse(result.malformedSignals.isEmpty)
    }

    func testSignalWithNormalTimestampIsNotMalformed() {
        let past = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let fact = makeFact(occurredAt: past)
        let signal = makeSignal(forFact: fact)
        let result = validator.validate(signals: [signal], against: [fact])
        XCTAssertTrue(result.malformedSignals.isEmpty)
    }

    // MARK: - Stale version detection

    func testSignalWithOldPipelineVersionIsStale() {
        let fact = makeFact()
        let staleSignal = makeSignal(forFact: fact, pipelineVersion: 0)
        let result = validator.validate(signals: [staleSignal], against: [fact])
        XCTAssertFalse(result.staleVersionSignals.isEmpty)
    }

    func testSignalWithCurrentPipelineVersionIsNotStale() {
        let fact = makeFact()
        let signal = makeSignal(forFact: fact, pipelineVersion: SignalPipeline.version)
        let result = validator.validate(signals: [signal], against: [fact])
        XCTAssertTrue(result.staleVersionSignals.isEmpty)
    }

    // MARK: - isValid reflects orphan+duplicate+malformed only

    func testIsValidIgnoresStaleVersionAlone() {
        let fact = makeFact()
        let staleSignal = makeSignal(forFact: fact, pipelineVersion: 0)
        let result = validator.validate(signals: [staleSignal], against: [fact])
        XCTAssertTrue(result.isValid,
            "Stale version alone does not make isValid false — only orphan/duplicate/malformed do")
    }
}
