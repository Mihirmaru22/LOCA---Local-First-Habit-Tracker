package com.loca.record

import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.datetime.Clock
import kotlin.uuid.Uuid

/**
 * The single gatekeeper for all writes to the Record.
 *
 * Analogue to Swift's `actor RecordEngine`.
 * A Mutex replaces Swift actor isolation — only one coroutine writes at a time.
 *
 * Enforced invariants:
 *  G1: Immutability — stored Facts are never modified.
 *  G2: Identity — each Fact.id is unique; duplicate IDs are rejected.
 *  G3: Ordering — recordedAt is set by the engine at write time.
 *  G4: Replayability — replayableFacts() returns insertion-ordered Facts.
 */
class RecordEngine(private val store: RecordStoring) {

    private val mutex = Mutex()
    private val knownIDs = mutableSetOf<Uuid>()

    // ── Init ──────────────────────────────────────────────────────────────────

    /**
     * Must be called once after construction to restore dedup state
     * from a warm store (e.g. after process restart).
     */
    suspend fun initialize() {
        val existing = store.existingIDs()
        mutex.withLock { knownIDs.addAll(existing) }
    }

    // ── Write ─────────────────────────────────────────────────────────────────

    /**
     * Validate and append a FactDraft to the Record.
     *
     * @throws RecordError.DuplicateFact if the draft's ID was already stored.
     * @throws RecordError.ValidationFailure if the draft fails validation.
     * @throws RecordError.StorageFailure if the store throws.
     */
    suspend fun append(draft: FactDraft): Fact = mutex.withLock {
        if (knownIDs.contains(draft.id)) {
            throw RecordError.DuplicateFact(draft.id)
        }

        validate(draft)

        val fact = Fact(
            id          = draft.id,
            kind        = draft.kind,
            payload     = draft.payload,
            provenance  = FactProvenance(
                source              = draft.source,
                author              = draft.author,
                entryMethod         = draft.entryMethod,
                confidence          = draft.confidence,
                sourceIdentifier    = draft.sourceIdentifier,
                externalTimestamp   = draft.externalTimestamp
            ),
            recordedAt  = Clock.System.now(),
            occurredAt  = draft.occurredAt
        )

        try {
            store.append(fact)
        } catch (e: Exception) {
            throw RecordError.StorageFailure(e)
        }

        knownIDs.add(fact.id)
        fact
    }

    // ── Reads ─────────────────────────────────────────────────────────────────

    suspend fun facts(matching: RecordQuery = RecordQuery.all): List<Fact> =
        store.facts(matching)

    suspend fun count(matching: RecordQuery = RecordQuery.all): Int =
        store.count(matching)

    /**
     * Returns all Facts in insertion order.
     * Replaying these Facts through any derivation engine reproduces
     * the same derived state — the Record is the single source of truth.
     */
    suspend fun replayableFacts(): List<Fact> = store.allFacts()

    // ── Validation ────────────────────────────────────────────────────────────

    private fun validate(draft: FactDraft) {
        // Every FactKind — including deferred Life kinds — has a defined payload
        // shape, and the exhaustive `when` below checks all of them. Do not skip
        // validation for Life: an early return here would let Life facts be
        // stored with a mismatched payload.
        val payloadKindMatch = when (draft.kind) {
            FactKind.HABIT_DEFINED              -> draft.payload is FactPayload.HabitDefined
            FactKind.HABIT_LOGGED               -> draft.payload is FactPayload.HabitLogged
            FactKind.REFLECTION_WRITTEN         -> draft.payload is FactPayload.ReflectionWritten
            FactKind.MEMORABLE_MOMENT_CAPTURED  -> draft.payload is FactPayload.MemorableMomentCaptured
            FactKind.INTENTION_SET              -> draft.payload is FactPayload.IntentionSet
            FactKind.TODO_CREATED               -> draft.payload is FactPayload.TodoCreated
            FactKind.TODO_COMPLETED             -> draft.payload is FactPayload.TodoCompleted
            FactKind.HEALTH_SAMPLE_IMPORTED     -> draft.payload is FactPayload.HealthSampleImported
            FactKind.CORRECTION_SUBMITTED       -> draft.payload is FactPayload.CorrectionSubmitted
            FactKind.CONFIRMATION_SUBMITTED     -> draft.payload is FactPayload.ConfirmationSubmitted
            FactKind.DELETION_REQUESTED         -> draft.payload is FactPayload.DeletionRequested
            FactKind.PERMISSION_CHANGED         -> draft.payload is FactPayload.PermissionChanged
            FactKind.CONSENT_CHANGED            -> draft.payload is FactPayload.ConsentChanged
            FactKind.STATE_CHECKED_IN           -> draft.payload is FactPayload.StateCheckedIn
            FactKind.DIRECTION_CHANGED          -> draft.payload is FactPayload.DirectionChanged
            FactKind.QUESTION_ASKED             -> draft.payload is FactPayload.QuestionAsked
            FactKind.CALENDAR_EVENT_IMPORTED    -> draft.payload is FactPayload.CalendarEventImported
        }

        if (!payloadKindMatch) {
            throw RecordError.ValidationFailure(
                "Payload type does not match FactKind ${draft.kind}"
            )
        }

        validateDomain(draft.payload)
    }

    /**
     * Domain-level rules beyond payload-kind matching. Rejects values that would
     * silently corrupt derivation — a zero/negative habit log counting as a
     * completion, a blank reflection, a non-positive target, etc.
     *
     * Sensor-imported health values are allowed to be zero (0 steps is real);
     * they must only be finite.
     */
    private fun validateDomain(payload: FactPayload) {
        fun fail(reason: String): Nothing = throw RecordError.ValidationFailure(reason)

        when (payload) {
            is FactPayload.HabitDefined -> {
                if (payload.name.isBlank()) fail("Habit name must not be blank")
                if (!payload.targetValue.isFinite() || payload.targetValue <= 0.0)
                    fail("Habit target must be a positive number")
            }
            is FactPayload.HabitLogged -> {
                if (!payload.value.isFinite() || payload.value <= 0.0)
                    fail("Habit log value must be a positive number")
            }
            is FactPayload.ReflectionWritten ->
                if (payload.text.isBlank()) fail("Reflection text must not be blank")
            is FactPayload.MemorableMomentCaptured ->
                if (payload.text.isBlank()) fail("Moment text must not be blank")
            is FactPayload.IntentionSet ->
                if (payload.text.isBlank()) fail("Intention text must not be blank")
            is FactPayload.TodoCreated ->
                if (payload.title.isBlank()) fail("Task title must not be blank")
            is FactPayload.HealthSampleImported ->
                if (!payload.value.isFinite()) fail("Health sample value must be finite")
            else -> Unit
        }
    }
}
