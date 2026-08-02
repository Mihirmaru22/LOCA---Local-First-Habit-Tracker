import XCTest
@testable import LOCA

/// Tests for SignalPipeline:
///  - All FactKind cases produce the correct SignalKind
///  - Signal.id equals source Fact.id
///  - Provenance fields are correctly populated
///  - Payload data is preserved without modification
///  - occurredAt is preserved
///  - Determinism: same Fact → same Signal (S2)
final class SignalPipelineTests: XCTestCase {

    // MARK: - Helpers

    private func makeFact(
        id: UUID = UUID(),
        kind: FactKind,
        payload: FactPayload,
        occurredAt: Date = Date()
    ) -> Fact {
        let provenance = FactProvenance(
            source: .userEntry, author: .person, entryMethod: .explicit,
            confidence: .known, sourceIdentifier: nil, externalTimestamp: nil)
        return Fact(
            id: id, kind: kind, payload: payload,
            provenance: provenance,
            recordedAt: Date(timeIntervalSinceReferenceDate: 100_000),
            occurredAt: occurredAt)
    }

    // MARK: - All FactKind → SignalKind mappings

    func testHabitLoggedProducesHabitCompletion() {
        let fact = makeFact(kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil)))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.kind, .habitCompletion)
    }

    func testReflectionWrittenProducesReflection() {
        let fact = makeFact(kind: .reflectionWritten,
            payload: .reflectionWritten(ReflectionPayload(text: "today", promptText: nil, seedFactID: nil)))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.kind, .reflection)
    }

    func testStateCheckedInProducesStateCheckIn() {
        let fact = makeFact(kind: .stateCheckedIn,
            payload: .stateCheckedIn(StateCheckInPayload(mood: 4, energy: 3, focus: nil, stress: nil, note: nil)))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.kind, .stateCheckIn)
    }

    func testCorrectionSubmittedProducesCorrection() {
        let fact = makeFact(kind: .correctionSubmitted,
            payload: .correctionSubmitted(CorrectionPayload(targetFactID: UUID(), field: "value", correctedValue: "2.0", reason: nil)))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.kind, .correction)
    }

    func testDirectionChangedProducesDirection() {
        let fact = makeFact(kind: .directionChanged,
            payload: .directionChanged(DirectionPayload(directionID: UUID(), title: "Run 5K", description: nil, isArchived: false)))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.kind, .direction)
    }

    func testQuestionAskedProducesQuestion() {
        let fact = makeFact(kind: .questionAsked,
            payload: .questionAsked(QuestionAskedPayload(text: "Why?", contextHint: nil)))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.kind, .question)
    }

    func testPermissionChangedProducesPermission() {
        let fact = makeFact(kind: .permissionChanged,
            payload: .permissionChanged(PermissionChangedPayload(permission: "healthKit.steps", granted: true)))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.kind, .permission)
    }

    func testCalendarEventImportedProducesCalendarEvent() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let fact = makeFact(kind: .calendarEventImported,
            payload: .calendarEventImported(CalendarEventPayload(
                externalID: "evt1", title: "Meeting",
                startDate: now, endDate: nil, isAllDay: false, calendarName: "Work")))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.kind, .calendarEvent)
    }

    func testHealthSampleImportedProducesHealthSample() {
        let now = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let fact = makeFact(kind: .healthSampleImported,
            payload: .healthSampleImported(HealthSamplePayload(
                sampleType: "HKStepCount", value: 1000, unit: "count",
                startDate: now, endDate: now)))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.kind, .healthSample)
    }

    func testConsentChangedProducesConsent() {
        let fact = makeFact(kind: .consentChanged,
            payload: .consentChanged(ConsentChangedPayload(source: "healthKit", granted: true)))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.kind, .consent)
    }

    func testConfirmationSubmittedProducesConfirmation() {
        let fact = makeFact(kind: .confirmationSubmitted,
            payload: .confirmationSubmitted(ConfirmationPayload(targetFactID: UUID(), confirmationType: "landmark")))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.kind, .confirmation)
    }

    func testDeletionRequestedProducesDeletionRequested() {
        let fact = makeFact(kind: .deletionRequested,
            payload: .deletionRequested(DeletionRequestedPayload(targetFactID: UUID(), reason: nil, scope: .singleFact)))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.kind, .deletionRequested)
    }

    // MARK: - Signal.id == Fact.id (S2)

    func testSignalIDEqualsFactID() {
        let id = UUID()
        let fact = makeFact(id: id, kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil)))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.id, id)
    }

    // MARK: - Provenance correctness

    func testProvenanceSourceFactIDMatchesFact() {
        let fact = makeFact(kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil)))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.provenance.sourceFactID, fact.id)
        XCTAssertEqual(s.provenance.sourceFactKind, fact.kind)
        XCTAssertEqual(s.provenance.factSource, fact.provenance.source)
        XCTAssertEqual(s.provenance.factConfidence, fact.provenance.confidence)
        XCTAssertEqual(s.provenance.factRecordedAt, fact.recordedAt)
        XCTAssertEqual(s.provenance.factOccurredAt, fact.occurredAt)
    }

    func testProvenancePipelineVersionIsCurrentVersion() {
        let fact = makeFact(kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil)))
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.provenance.pipelineVersion, SignalPipeline.version)
    }

    // MARK: - Payload data preservation

    func testHabitPayloadDataPreserved() {
        let habitID = UUID()
        let fact = makeFact(kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: habitID, value: 3.5, note: "ran today")))
        guard case .success(let s) = SignalPipeline.transform(fact),
              case .habitCompletion(let p) = s.payload else { XCTFail(); return }
        XCTAssertEqual(p.habitID, habitID)
        XCTAssertEqual(p.value, 3.5)
        XCTAssertEqual(p.note, "ran today")
    }

    func testReflectionPayloadDataPreserved() {
        let seedID = UUID()
        let fact = makeFact(kind: .reflectionWritten,
            payload: .reflectionWritten(ReflectionPayload(text: "great day", promptText: "how was today?", seedFactID: seedID)))
        guard case .success(let s) = SignalPipeline.transform(fact),
              case .reflection(let p) = s.payload else { XCTFail(); return }
        XCTAssertEqual(p.text, "great day")
        XCTAssertEqual(p.promptText, "how was today?")
        XCTAssertEqual(p.seedFactID, seedID)
    }

    func testStateCheckInPayloadDataPreserved() {
        let fact = makeFact(kind: .stateCheckedIn,
            payload: .stateCheckedIn(StateCheckInPayload(mood: 4, energy: 2, focus: 3, stress: 5, note: "tired")))
        guard case .success(let s) = SignalPipeline.transform(fact),
              case .stateCheckIn(let p) = s.payload else { XCTFail(); return }
        XCTAssertEqual(p.mood, 4)
        XCTAssertEqual(p.energy, 2)
        XCTAssertEqual(p.focus, 3)
        XCTAssertEqual(p.stress, 5)
        XCTAssertEqual(p.note, "tired")
    }

    func testHealthPayloadDataPreserved() {
        let start = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let end = Date(timeIntervalSinceReferenceDate: 1_001_000)
        let fact = makeFact(kind: .healthSampleImported,
            payload: .healthSampleImported(HealthSamplePayload(
                sampleType: "HKHeartRate", value: 72.0, unit: "bpm",
                startDate: start, endDate: end)))
        guard case .success(let s) = SignalPipeline.transform(fact),
              case .healthSample(let p) = s.payload else { XCTFail(); return }
        XCTAssertEqual(p.sampleType, "HKHeartRate")
        XCTAssertEqual(p.value, 72.0)
        XCTAssertEqual(p.unit, "bpm")
        XCTAssertEqual(p.startDate, start)
        XCTAssertEqual(p.endDate, end)
    }

    // MARK: - occurredAt preservation

    func testOccurredAtPreserved() {
        let ts = Date(timeIntervalSinceReferenceDate: 1_234_567)
        let fact = makeFact(kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: UUID(), value: 1.0, note: nil)),
            occurredAt: ts)
        guard case .success(let s) = SignalPipeline.transform(fact) else { XCTFail(); return }
        XCTAssertEqual(s.occurredAt, ts)
    }

    // MARK: - Determinism (S2): same Fact → same id, kind, payload

    func testSameFactProducesSameSignalKindAndPayload() {
        let habitID = UUID()
        let factID = UUID()
        let prov = FactProvenance(source: .userEntry, author: .person, entryMethod: .explicit,
            confidence: .known, sourceIdentifier: nil, externalTimestamp: nil)
        let fact = Fact(
            id: factID, kind: .habitLogged,
            payload: .habitLogged(HabitLogPayload(habitID: habitID, value: 2.0, note: nil)),
            provenance: prov,
            recordedAt: Date(timeIntervalSinceReferenceDate: 500_000),
            occurredAt: Date(timeIntervalSinceReferenceDate: 1_000_000))

        guard case .success(let s1) = SignalPipeline.transform(fact),
              case .success(let s2) = SignalPipeline.transform(fact) else { XCTFail(); return }

        XCTAssertEqual(s1.id, s2.id)
        XCTAssertEqual(s1.kind, s2.kind)
        XCTAssertEqual(s1.payload, s2.payload)
        XCTAssertEqual(s1.occurredAt, s2.occurredAt)
        XCTAssertEqual(s1.provenance.sourceFactID, s2.provenance.sourceFactID)
    }

    // MARK: - FactKind.signalKind mapping completeness

    func testAllFactKindsMapped() {
        for kind in FactKind.allCases {
            let signalKind = kind.signalKind
            XCTAssertNotNil(signalKind, "FactKind.\(kind) must map to a SignalKind")
        }
    }
}
