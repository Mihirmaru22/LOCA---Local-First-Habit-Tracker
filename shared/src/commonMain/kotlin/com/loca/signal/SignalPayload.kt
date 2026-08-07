package com.loca.signal

import com.loca.record.DeletionScope
import com.loca.record.HabitFrequency
import com.loca.record.IntentionPeriod
import kotlinx.datetime.Instant
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlin.uuid.Uuid

/**
 * Signal payloads carry the same fields as their source Fact payloads,
 * validated and structured for Signal layer consumers.
 *
 * No inference is applied — values are passed through from the Fact.
 * Normalization is structural (typed, layer-specific), not interpretive.
 */
@Serializable
sealed interface SignalPayload {

    // ── Habits ──────────────────────────────────────────────────────────────

    @Serializable @SerialName("habitDefinition")
    data class HabitDefinition(
        val habitID: Uuid,
        val name: String,
        val description: String? = null,
        val targetValue: Double,
        val unit: String? = null,
        val frequency: HabitFrequency
    ) : SignalPayload

    @Serializable @SerialName("habitCompletion")
    data class HabitCompletion(
        val habitID: Uuid,
        val value: Double,
        val note: String? = null
    ) : SignalPayload

    // ── Journal ─────────────────────────────────────────────────────────────

    @Serializable @SerialName("reflection")
    data class Reflection(
        val text: String,
        val promptText: String? = null,
        val seedFactID: Uuid? = null
    ) : SignalPayload

    @Serializable @SerialName("memorableMoment")
    data class MemorableMoment(
        val text: String,
        val tags: List<String> = emptyList()
    ) : SignalPayload

    @Serializable @SerialName("intention")
    data class Intention(
        val text: String,
        val period: IntentionPeriod,
        val expiresAt: Instant? = null
    ) : SignalPayload

    // ── Todo ────────────────────────────────────────────────────────────────

    @Serializable @SerialName("todoCreation")
    data class TodoCreation(
        val todoID: Uuid,
        val title: String,
        val dueDate: Instant? = null,
        val notes: String? = null
    ) : SignalPayload

    @Serializable @SerialName("todoCompletion")
    data class TodoCompletion(
        val todoID: Uuid
    ) : SignalPayload

    // ── Infrastructure ──────────────────────────────────────────────────────

    @Serializable @SerialName("healthSample")
    data class HealthSample(
        val sampleType: String,
        val value: Double,
        val unit: String,
        val startDate: Instant,
        val endDate: Instant
    ) : SignalPayload

    @Serializable @SerialName("correction")
    data class Correction(
        val targetFactID: Uuid,
        val field: String,
        val correctedValue: String,
        val reason: String? = null
    ) : SignalPayload

    @Serializable @SerialName("confirmation")
    data class Confirmation(
        val targetFactID: Uuid,
        val confirmationType: String
    ) : SignalPayload

    @Serializable @SerialName("deletionRequested")
    data class Deletion(
        val targetFactID: Uuid,
        val reason: String? = null,
        val scope: DeletionScope
    ) : SignalPayload

    @Serializable @SerialName("permission")
    data class Permission(
        val permission: String,
        val granted: Boolean
    ) : SignalPayload

    @Serializable @SerialName("consent")
    data class Consent(
        val source: String,
        val granted: Boolean
    ) : SignalPayload

    // ── Life (deferred) ─────────────────────────────────────────────────────

    @Serializable @SerialName("stateCheckIn")
    data class StateCheckIn(
        val mood: Int? = null,
        val energy: Int? = null,
        val focus: Int? = null,
        val stress: Int? = null,
        val note: String? = null
    ) : SignalPayload

    @Serializable @SerialName("direction")
    data class Direction(
        val directionID: Uuid,
        val title: String,
        val directionDescription: String? = null,
        val isArchived: Boolean
    ) : SignalPayload

    @Serializable @SerialName("question")
    data class Question(
        val text: String,
        val contextHint: String? = null
    ) : SignalPayload

    @Serializable @SerialName("calendarEvent")
    data class CalendarEvent(
        val externalID: String,
        val title: String,
        val startDate: Instant,
        val endDate: Instant? = null,
        val isAllDay: Boolean,
        val calendarName: String? = null
    ) : SignalPayload
}
