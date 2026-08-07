import Foundation

/// Pure stateless transformation from Fact → Signal.
///
/// Pipeline steps:
///  1. Extract and normalize the FactPayload into a SignalPayload
///  2. Build SignalProvenance from the Fact and its FactProvenance
///  3. Produce an immutable Signal
///
/// Signal.id is set equal to the source Fact.id, making the 1:1 relationship
/// explicit and enabling deterministic replay (same Fact → same Signal.id).
///
/// No state. No side effects. No inference. Calling transform(_:) twice with
/// the same Fact produces structurally identical Signals (same id, kind, payload).
enum SignalPipeline {

    /// The current pipeline version. Increment when the transformation logic
    /// changes in a way that would produce different Signals from the same Facts.
    /// Signals carrying an older pipelineVersion are candidates for replay.
    static let version: Int = 1

    // MARK: - Transform

    /// Transform a Fact into a Signal.
    ///
    /// Returns `.success(Signal)` on success.
    /// Returns `.failure(SignalPipelineError)` if the payload is malformed.
    static func transform(_ fact: Fact) -> Result<Signal, SignalPipelineError> {
        switch buildPayload(from: fact) {
        case .failure(let e):
            return .failure(e)
        case .success(let payload):
            let now = Date()
            let provenance = SignalProvenance(
                sourceFactID: fact.id,
                sourceFactKind: fact.kind,
                factRecordedAt: fact.recordedAt,
                factOccurredAt: fact.occurredAt,
                factSource: fact.provenance.source,
                factConfidence: fact.provenance.confidence,
                transformedAt: now,
                pipelineVersion: version
            )
            let signal = Signal(
                id: fact.id,
                kind: fact.kind.signalKind,
                payload: payload,
                provenance: provenance,
                occurredAt: fact.occurredAt,
                producedAt: now
            )
            return .success(signal)
        }
    }

    // MARK: - Payload normalization

    private static func buildPayload(from fact: Fact) -> Result<SignalPayload, SignalPipelineError> {
        switch fact.payload {

        case .habitLogged(let p):
            return .success(.habitCompletion(HabitCompletionSignal(
                habitID: p.habitID, value: p.value, note: p.note)))

        case .reflectionWritten(let p):
            return .success(.reflection(ReflectionSignal(
                text: p.text, promptText: p.promptText, seedFactID: p.seedFactID)))

        case .stateCheckedIn(let p):
            return .success(.stateCheckIn(StateCheckInSignal(
                mood: p.mood, energy: p.energy, focus: p.focus,
                stress: p.stress, note: p.note)))

        case .correctionSubmitted(let p):
            return .success(.correction(CorrectionSignal(
                targetFactID: p.targetFactID, field: p.field,
                correctedValue: p.correctedValue, reason: p.reason)))

        case .directionChanged(let p):
            return .success(.direction(DirectionSignal(
                directionID: p.directionID, title: p.title,
                directionDescription: p.description, isArchived: p.isArchived)))

        case .questionAsked(let p):
            return .success(.question(QuestionSignal(
                text: p.text, contextHint: p.contextHint)))

        case .permissionChanged(let p):
            return .success(.permission(PermissionSignal(
                permission: p.permission, granted: p.granted)))

        case .calendarEventImported(let p):
            return .success(.calendarEvent(CalendarEventSignal(
                externalID: p.externalID, title: p.title,
                startDate: p.startDate, endDate: p.endDate,
                isAllDay: p.isAllDay, calendarName: p.calendarName)))

        case .healthSampleImported(let p):
            return .success(.healthSample(HealthSampleSignal(
                sampleType: p.sampleType, value: p.value, unit: p.unit,
                startDate: p.startDate, endDate: p.endDate)))

        case .consentChanged(let p):
            return .success(.consent(ConsentSignal(
                source: p.source, granted: p.granted)))

        case .confirmationSubmitted(let p):
            return .success(.confirmation(ConfirmationSignal(
                targetFactID: p.targetFactID, confirmationType: p.confirmationType)))

        case .deletionRequested(let p):
            return .success(.deletionRequested(DeletionSignal(
                targetFactID: p.targetFactID, reason: p.reason, scope: p.scope)))
        }
    }
}
