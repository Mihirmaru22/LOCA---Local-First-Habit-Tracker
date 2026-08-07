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
        if (draft.kind.pillar == Pillar.LIFE && draft.kind.isImplemented.not()) return

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
    }
}
