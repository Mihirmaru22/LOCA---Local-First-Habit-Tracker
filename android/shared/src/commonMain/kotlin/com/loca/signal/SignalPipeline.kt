package com.loca.signal

import com.loca.record.Fact
import com.loca.record.FactPayload
import kotlinx.datetime.Clock

/**
 * Pure stateless transformation from Fact → Signal.
 *
 * Pipeline steps:
 *  1. Extract and normalize the FactPayload into a SignalPayload
 *  2. Build SignalProvenance from the Fact and its FactProvenance
 *  3. Produce an immutable Signal
 *
 * Signal.id is set equal to the source Fact.id, making the 1:1 relationship
 * explicit and enabling deterministic replay (same Fact → same Signal.id).
 *
 * No state. No side effects. No inference. Calling transform twice with the
 * same Fact produces structurally identical Signals (same id, kind, payload).
 */
object SignalPipeline {

    /**
     * The current pipeline version. Increment when the transformation logic
     * changes in a way that would produce different Signals from the same Facts.
     * Signals carrying an older pipelineVersion are candidates for replay.
     */
    const val VERSION: Int = 1

    /**
     * Transform a Fact into a Signal.
     *
     * @throws SignalPipelineError.PayloadKindMismatch if the Fact's payload
     *   does not match its declared kind.
     */
    fun transform(fact: Fact): Signal {
        val payload = buildPayload(fact)
        val expectedKind = fact.kind.signalKind
        if (payload.signalKind != expectedKind) {
            throw SignalPipelineError.PayloadKindMismatch(fact.id, fact.kind)
        }

        val now = Clock.System.now()
        val provenance = SignalProvenance(
            sourceFactID    = fact.id,
            sourceFactKind  = fact.kind,
            factRecordedAt  = fact.recordedAt,
            factOccurredAt  = fact.occurredAt,
            factSource      = fact.provenance.source,
            factConfidence  = fact.provenance.confidence,
            transformedAt   = now,
            pipelineVersion = VERSION
        )
        return Signal(
            id          = fact.id,
            kind        = expectedKind,
            payload     = payload,
            provenance  = provenance,
            occurredAt  = fact.occurredAt,
            producedAt  = now
        )
    }

    // ── Payload normalization ───────────────────────────────────────────────

    private fun buildPayload(fact: Fact): SignalPayload = when (val p = fact.payload) {
        is FactPayload.HabitDefined -> SignalPayload.HabitDefinition(
            habitID = p.habitID, name = p.name, description = p.description,
            targetValue = p.targetValue, unit = p.unit, frequency = p.frequency
        )
        is FactPayload.HabitLogged -> SignalPayload.HabitCompletion(
            habitID = p.habitID, value = p.value, note = p.note
        )
        is FactPayload.ReflectionWritten -> SignalPayload.Reflection(
            text = p.text, promptText = p.promptText, seedFactID = p.seedFactID
        )
        is FactPayload.MemorableMomentCaptured -> SignalPayload.MemorableMoment(
            text = p.text, tags = p.tags
        )
        is FactPayload.IntentionSet -> SignalPayload.Intention(
            text = p.text, period = p.period, expiresAt = p.expiresAt
        )
        is FactPayload.TodoCreated -> SignalPayload.TodoCreation(
            todoID = p.todoID, title = p.title, dueDate = p.dueDate, notes = p.notes
        )
        is FactPayload.TodoCompleted -> SignalPayload.TodoCompletion(
            todoID = p.todoID
        )
        is FactPayload.HealthSampleImported -> SignalPayload.HealthSample(
            sampleType = p.sampleType, value = p.value, unit = p.unit,
            startDate = p.startDate, endDate = p.endDate
        )
        is FactPayload.CorrectionSubmitted -> SignalPayload.Correction(
            targetFactID = p.targetFactID, field = p.field,
            correctedValue = p.correctedValue, reason = p.reason
        )
        is FactPayload.ConfirmationSubmitted -> SignalPayload.Confirmation(
            targetFactID = p.targetFactID, confirmationType = p.confirmationType
        )
        is FactPayload.DeletionRequested -> SignalPayload.Deletion(
            targetFactID = p.targetFactID, reason = p.reason, scope = p.scope
        )
        is FactPayload.PermissionChanged -> SignalPayload.Permission(
            permission = p.permission, granted = p.granted
        )
        is FactPayload.ConsentChanged -> SignalPayload.Consent(
            source = p.source, granted = p.granted
        )
        is FactPayload.StateCheckedIn -> SignalPayload.StateCheckIn(
            mood = p.mood, energy = p.energy, focus = p.focus,
            stress = p.stress, note = p.note
        )
        is FactPayload.DirectionChanged -> SignalPayload.Direction(
            directionID = p.directionID, title = p.title,
            directionDescription = p.description, isArchived = p.isArchived
        )
        is FactPayload.QuestionAsked -> SignalPayload.Question(
            text = p.text, contextHint = p.contextHint
        )
        is FactPayload.CalendarEventImported -> SignalPayload.CalendarEvent(
            externalID = p.externalID, title = p.title,
            startDate = p.startDate, endDate = p.endDate,
            isAllDay = p.isAllDay, calendarName = p.calendarName
        )
    }
}

/** The SignalKind this payload structurally represents. */
val SignalPayload.signalKind: SignalKind
    get() = when (this) {
        is SignalPayload.HabitDefinition -> SignalKind.HABIT_DEFINITION
        is SignalPayload.HabitCompletion -> SignalKind.HABIT_COMPLETION
        is SignalPayload.Reflection      -> SignalKind.REFLECTION
        is SignalPayload.MemorableMoment -> SignalKind.MEMORABLE_MOMENT
        is SignalPayload.Intention       -> SignalKind.INTENTION
        is SignalPayload.TodoCreation    -> SignalKind.TODO_CREATION
        is SignalPayload.TodoCompletion  -> SignalKind.TODO_COMPLETION
        is SignalPayload.HealthSample    -> SignalKind.HEALTH_SAMPLE
        is SignalPayload.Correction      -> SignalKind.CORRECTION
        is SignalPayload.Confirmation    -> SignalKind.CONFIRMATION
        is SignalPayload.Deletion        -> SignalKind.DELETION_REQUESTED
        is SignalPayload.Permission      -> SignalKind.PERMISSION
        is SignalPayload.Consent         -> SignalKind.CONSENT
        is SignalPayload.StateCheckIn    -> SignalKind.STATE_CHECK_IN
        is SignalPayload.Direction       -> SignalKind.DIRECTION
        is SignalPayload.Question        -> SignalKind.QUESTION
        is SignalPayload.CalendarEvent   -> SignalKind.CALENDAR_EVENT
    }
