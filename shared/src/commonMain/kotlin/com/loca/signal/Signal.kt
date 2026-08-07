@file:UseSerializers(UuidSerializer::class)

package com.loca.signal

import com.loca.record.FactKind
import com.loca.record.UuidSerializer
import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable
import kotlinx.serialization.UseSerializers
import kotlin.uuid.Uuid

/**
 * The kind of a Signal. Mirrors FactKind: one SignalKind for every FactKind.
 * The Signal Engine produces exactly one SignalKind for each FactKind.
 */
@Serializable
enum class SignalKind {
    HABIT_DEFINITION,       // ← HABIT_DEFINED
    HABIT_COMPLETION,       // ← HABIT_LOGGED
    REFLECTION,             // ← REFLECTION_WRITTEN
    MEMORABLE_MOMENT,       // ← MEMORABLE_MOMENT_CAPTURED
    INTENTION,              // ← INTENTION_SET
    TODO_CREATION,          // ← TODO_CREATED
    TODO_COMPLETION,        // ← TODO_COMPLETED
    HEALTH_SAMPLE,          // ← HEALTH_SAMPLE_IMPORTED
    CORRECTION,             // ← CORRECTION_SUBMITTED
    CONFIRMATION,           // ← CONFIRMATION_SUBMITTED
    DELETION_REQUESTED,     // ← DELETION_REQUESTED
    PERMISSION,             // ← PERMISSION_CHANGED
    CONSENT,                // ← CONSENT_CHANGED
    STATE_CHECK_IN,         // ← STATE_CHECKED_IN
    DIRECTION,              // ← DIRECTION_CHANGED
    QUESTION,               // ← QUESTION_ASKED
    CALENDAR_EVENT          // ← CALENDAR_EVENT_IMPORTED
}

/**
 * The SignalKind produced from this FactKind.
 * Every FactKind maps to exactly one SignalKind.
 */
val FactKind.signalKind: SignalKind
    get() = when (this) {
        FactKind.HABIT_DEFINED             -> SignalKind.HABIT_DEFINITION
        FactKind.HABIT_LOGGED              -> SignalKind.HABIT_COMPLETION
        FactKind.REFLECTION_WRITTEN        -> SignalKind.REFLECTION
        FactKind.MEMORABLE_MOMENT_CAPTURED -> SignalKind.MEMORABLE_MOMENT
        FactKind.INTENTION_SET             -> SignalKind.INTENTION
        FactKind.TODO_CREATED              -> SignalKind.TODO_CREATION
        FactKind.TODO_COMPLETED            -> SignalKind.TODO_COMPLETION
        FactKind.HEALTH_SAMPLE_IMPORTED    -> SignalKind.HEALTH_SAMPLE
        FactKind.CORRECTION_SUBMITTED      -> SignalKind.CORRECTION
        FactKind.CONFIRMATION_SUBMITTED    -> SignalKind.CONFIRMATION
        FactKind.DELETION_REQUESTED        -> SignalKind.DELETION_REQUESTED
        FactKind.PERMISSION_CHANGED        -> SignalKind.PERMISSION
        FactKind.CONSENT_CHANGED           -> SignalKind.CONSENT
        FactKind.STATE_CHECKED_IN          -> SignalKind.STATE_CHECK_IN
        FactKind.DIRECTION_CHANGED         -> SignalKind.DIRECTION
        FactKind.QUESTION_ASKED            -> SignalKind.QUESTION
        FactKind.CALENDAR_EVENT_IMPORTED   -> SignalKind.CALENDAR_EVENT
    }

/**
 * A normalized, provenance-bearing signal produced from an immutable Fact.
 *
 * Design invariants:
 *  S1: One Signal per Fact. `signal.id == sourceFactID` makes this auditable.
 *  S2: Determinism. Same Fact → same id, kind, payload, occurredAt.
 *  S3: Replay. Clearing all signals and reprocessing the same Facts reproduces
 *      the same set. Possible because Signal.id equals Fact.id.
 *  S4: Provenance completeness. Every Signal carries a SignalProvenance.
 *  S5: Read-only from Record. The Signal Engine never writes to the Record.
 */
@Serializable
data class Signal(
    /** Equal to the source Fact's id — makes the 1:1 relationship explicit. */
    val id: Uuid,
    /** The kind of this signal, derived from the source Fact's kind. */
    val kind: SignalKind,
    /** Kind-specific normalized payload. */
    val payload: SignalPayload,
    /** Full provenance chain: which Fact, when, which source, which pipeline. */
    val provenance: SignalProvenance,
    /** When the underlying event occurred (copied from Fact.occurredAt). */
    val occurredAt: Instant,
    /** When this Signal was produced by the Signal Engine. */
    val producedAt: Instant
)
