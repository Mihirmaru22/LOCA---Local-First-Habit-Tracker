import XCTest
@testable import LOCA

/// Tests for DefaultFactValidator:
///  - Each kind's payload match rule (correct payload accepted, wrong payload rejected)
///  - Required-field rules per kind
///  - Bounds checks
///  - No silent repair: every failure carries a specific ValidationError
final class FactValidatorTests: XCTestCase {

    private let validator = DefaultFactValidator()

    // MARK: - Helpers

    private func validate(_ draft: FactDraft) -> Result<FactDraft, ValidationError> {
        validator.validate(draft)
    }

    private func makeDraft(
        id: UUID = UUID(),
        kind: FactKind,
        payload: FactPayload,
        occurredAt: Date = Date(),
        source: FactSource = .userEntry,
        author: FactAuthor = .person,
        entryMethod: EntryMethod = .explicit,
        confidence: FactConfidence = .known,
        sourceIdentifier: String? = nil,
        externalTimestamp: Date? = nil
    ) -> FactDraft {
        FactDraft(
            id: id,
            kind: kind,
            payload: payload,
            occurredAt: occurredAt,
            source: source,
            author: author,
            entryMethod: entryMethod,
            confidence: confidence,
            sourceIdentifier: sourceIdentifier,
            externalTimestamp: externalTimestamp
        )
    }

    // MARK: - habitLogged

    func testHabitLoggedWithMatchingPayloadPasses() {
        let draft = makeDraft(
            kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil))
        )
        XCTAssertNoThrow(try validate(draft).get())
    }

    func testHabitLoggedWithMismatchedPayloadFails() {
        let draft = makeDraft(
            kind: .habitLogged,
            payload: .reflectionWritten(ReflectionPayload(text: "x", promptText: nil, seedFactID: nil))
        )
        if case .success = validate(draft) {
            XCTFail("Expected validation failure for mismatched payload")
        }
    }

    // MARK: - reflectionWritten

    func testReflectionWrittenWithTextPasses() {
        let draft = makeDraft(
            kind: .reflectionWritten,
            payload: .reflectionWritten(ReflectionPayload(text: "Today was good", promptText: nil, seedFactID: nil))
        )
        XCTAssertNoThrow(try validate(draft).get())
    }

    func testReflectionWrittenWithEmptyTextFails() {
        let draft = makeDraft(
            kind: .reflectionWritten,
            payload: .reflectionWritten(ReflectionPayload(text: "", promptText: nil, seedFactID: nil))
        )
        if case .success = validate(draft) {
            XCTFail("Expected validation failure for empty reflection text")
        }
    }

    func testReflectionWrittenWithMismatchedPayloadFails() {
        let draft = makeDraft(
            kind: .reflectionWritten,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil))
        )
        if case .success = validate(draft) {
            XCTFail("Expected validation failure for mismatched payload")
        }
    }

    // MARK: - stateCheckedIn

    func testStateCheckedInWithMatchingPayloadPasses() {
        let draft = makeDraft(
            kind: .stateCheckedIn,
            payload: .stateCheckedIn(StateCheckInPayload(mood: 3, energy: nil, focus: nil, stress: nil, note: nil))
        )
        XCTAssertNoThrow(try validate(draft).get())
    }

    func testStateCheckedInWithOutOfBoundsValueFails() {
        // mood outside 1–5 range
        let draft = makeDraft(
            kind: .stateCheckedIn,
            payload: .stateCheckedIn(StateCheckInPayload(mood: 8, energy: nil, focus: nil, stress: nil, note: nil))
        )
        if case .success = validate(draft) {
            XCTFail("Expected validation failure: mood > 5")
        }
    }

    func testStateCheckedInWithNegativeValueFails() {
        // mood below 1
        let draft = makeDraft(
            kind: .stateCheckedIn,
            payload: .stateCheckedIn(StateCheckInPayload(mood: 0, energy: nil, focus: nil, stress: nil, note: nil))
        )
        if case .success = validate(draft) {
            XCTFail("Expected validation failure: mood < 1")
        }
    }

    func testStateCheckedInWithAllNilFails() {
        // At least one dimension required
        let draft = makeDraft(
            kind: .stateCheckedIn,
            payload: .stateCheckedIn(StateCheckInPayload(mood: nil, energy: nil, focus: nil, stress: nil, note: nil))
        )
        if case .success = validate(draft) {
            XCTFail("Expected validation failure: all dimensions nil")
        }
    }

    // MARK: - healthSampleImported

    func testHealthSampleImportedWithMatchingPayloadPasses() {
        let draft = makeDraft(
            kind: .healthSampleImported,
            payload: .healthSampleImported(HealthSamplePayload(
                sampleType: "HKStepCount",
                value: 5000,
                unit: "count",
                startDate: Date(),
                endDate: Date()
            )),
            source: .healthKit,
            author: .sensor,
            entryMethod: .imported
        )
        XCTAssertNoThrow(try validate(draft).get())
    }

    func testHealthSampleImportedWithEmptySampleTypeFails() {
        let draft = makeDraft(
            kind: .healthSampleImported,
            payload: .healthSampleImported(HealthSamplePayload(
                sampleType: "",
                value: 5000,
                unit: "count",
                startDate: Date(),
                endDate: Date()
            ))
        )
        if case .success = validate(draft) {
            XCTFail("Expected validation failure: empty sampleType")
        }
    }

    // MARK: - correctionSubmitted

    func testCorrectionSubmittedWithMatchingPayloadPasses() {
        let draft = makeDraft(
            kind: .correctionSubmitted,
            payload: .correctionSubmitted(CorrectionPayload(
                targetFactID: UUID(),
                field: "value",
                correctedValue: "2.0",
                reason: "wrong value"
            )),
            source: .correction
        )
        XCTAssertNoThrow(try validate(draft).get())
    }

    func testCorrectionSubmittedWithEmptyFieldFails() {
        let draft = makeDraft(
            kind: .correctionSubmitted,
            payload: .correctionSubmitted(CorrectionPayload(
                targetFactID: UUID(),
                field: "",
                correctedValue: "2.0",
                reason: nil
            )),
            source: .correction
        )
        if case .success = validate(draft) {
            XCTFail("Expected validation failure: empty field")
        }
    }

    // MARK: - Error type specificity

    func testMismatchedPayloadProducesMalformedPayloadError() {
        let draft = makeDraft(
            kind: .habitLogged,
            payload: .reflectionWritten(ReflectionPayload(text: "x", promptText: nil, seedFactID: nil))
        )
        switch validate(draft) {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            if case .malformedPayload = error {
                // correct
            } else {
                XCTFail("Expected .malformedPayload, got \(error)")
            }
        }
    }

    func testMissingRequiredFieldProducesMissingFieldError() {
        let draft = makeDraft(
            kind: .reflectionWritten,
            payload: .reflectionWritten(ReflectionPayload(text: "", promptText: nil, seedFactID: nil))
        )
        switch validate(draft) {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            if case .missingRequiredField = error {
                // correct
            } else {
                XCTFail("Expected .missingRequiredField, got \(error)")
            }
        }
    }
}
