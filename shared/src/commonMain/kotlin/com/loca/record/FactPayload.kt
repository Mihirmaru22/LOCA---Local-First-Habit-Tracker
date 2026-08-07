@file:UseSerializers(UuidSerializer::class)

package com.loca.record

import kotlinx.datetime.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.UseSerializers
import kotlin.uuid.Uuid

/**
 * Discriminated union of all fact payloads.
 *
 * Every FactKind maps to exactly one FactPayload subtype.
 * No interpretation — fields are recorded exactly as provided.
 *
 * Life pillar payloads (STATE_CHECKED_IN, DIRECTION_CHANGED,
 * QUESTION_ASKED, CALENDAR_EVENT_IMPORTED) are defined but
 * deferred — present for type completeness.
 */
@Serializable
sealed interface FactPayload {

    // ── Habits pillar ─────────────────────────────────────────────────────────

    @Serializable @SerialName("habitDefined")
    data class HabitDefined(
        val habitID: Uuid,
        val name: String,
        val description: String? = null,
        val targetValue: Double = 1.0,
        val unit: String? = null,
        val frequency: HabitFrequency = HabitFrequency.DAILY
    ) : FactPayload

    @Serializable @SerialName("habitLogged")
    data class HabitLogged(
        val habitID: Uuid,
        val value: Double,
        val note: String? = null
    ) : FactPayload

    // ── Journal pillar ────────────────────────────────────────────────────────

    @Serializable @SerialName("reflectionWritten")
    data class ReflectionWritten(
        val text: String,
        val promptText: String? = null,
        val seedFactID: Uuid? = null
    ) : FactPayload

    @Serializable @SerialName("memorableMomentCaptured")
    data class MemorableMomentCaptured(
        val text: String,
        val tags: List<String> = emptyList()
    ) : FactPayload

    @Serializable @SerialName("intentionSet")
    data class IntentionSet(
        val text: String,
        val period: IntentionPeriod = IntentionPeriod.DAILY,
        val expiresAt: Instant? = null
    ) : FactPayload

    // ── Todo pillar ───────────────────────────────────────────────────────────

    @Serializable @SerialName("todoCreated")
    data class TodoCreated(
        val todoID: Uuid,
        val title: String,
        val dueDate: Instant? = null,
        val notes: String? = null
    ) : FactPayload

    @Serializable @SerialName("todoCompleted")
    data class TodoCompleted(
        val todoID: Uuid
    ) : FactPayload

    // ── Infrastructure ────────────────────────────────────────────────────────

    @Serializable @SerialName("healthSampleImported")
    data class HealthSampleImported(
        val sampleType: String,
        val value: Double,
        val unit: String,
        val startDate: Instant,
        val endDate: Instant
    ) : FactPayload

    /**
     * Corrects a previously recorded fact.
     * Also used to edit a Todo (title, dueDate) — no separate TODO_UPDATED kind.
     * field = "title" | "dueDate" | "notes" | "value" | etc.
     */
    @Serializable @SerialName("correctionSubmitted")
    data class CorrectionSubmitted(
        val targetFactID: Uuid,
        val field: String,
        val correctedValue: String,
        val reason: String? = null
    ) : FactPayload

    @Serializable @SerialName("confirmationSubmitted")
    data class ConfirmationSubmitted(
        val targetFactID: Uuid,
        val confirmationType: String
    ) : FactPayload

    @Serializable @SerialName("deletionRequested")
    data class DeletionRequested(
        val targetFactID: Uuid,
        val reason: String? = null,
        val scope: DeletionScope = DeletionScope.SINGLE_FACT
    ) : FactPayload

    @Serializable @SerialName("permissionChanged")
    data class PermissionChanged(
        val permission: String,
        val granted: Boolean
    ) : FactPayload

    @Serializable @SerialName("consentChanged")
    data class ConsentChanged(
        val source: String,
        val granted: Boolean
    ) : FactPayload

    // ── Life pillar (deferred) ────────────────────────────────────────────────

    @Serializable @SerialName("stateCheckedIn")
    data class StateCheckedIn(
        val mood: Int? = null,
        val energy: Int? = null,
        val focus: Int? = null,
        val stress: Int? = null,
        val note: String? = null
    ) : FactPayload

    @Serializable @SerialName("directionChanged")
    data class DirectionChanged(
        val directionID: Uuid,
        val title: String,
        val description: String? = null,
        val isArchived: Boolean = false
    ) : FactPayload

    @Serializable @SerialName("questionAsked")
    data class QuestionAsked(
        val text: String,
        val contextHint: String? = null
    ) : FactPayload

    @Serializable @SerialName("calendarEventImported")
    data class CalendarEventImported(
        val externalID: String,
        val title: String,
        val startDate: Instant,
        val endDate: Instant? = null,
        val isAllDay: Boolean = false,
        val calendarName: String? = null
    ) : FactPayload
}

// ── Supporting enums ──────────────────────────────────────────────────────────

@Serializable
enum class HabitFrequency {
    DAILY, WEEKLY, MONTHLY
}

@Serializable
enum class IntentionPeriod {
    DAILY, WEEKLY, MONTHLY
}

@Serializable
enum class DeletionScope {
    SINGLE_FACT,
    ALL_FACTS_OF_KIND
}
