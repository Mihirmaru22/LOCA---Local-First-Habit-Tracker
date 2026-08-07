package com.loca.android.data

import com.loca.record.EntryMethod
import com.loca.record.FactAuthor
import com.loca.record.FactConfidence
import com.loca.record.FactDraft
import com.loca.record.FactKind
import com.loca.record.FactPayload
import com.loca.record.FactSource
import com.loca.record.HabitFrequency
import com.loca.record.IntentionPeriod
import kotlinx.datetime.Instant
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

/**
 * Builds FactDrafts for facts the person authors directly in the app.
 *
 * Every draft here carries the same provenance: entered by a PERSON,
 * EXPLICIT method, from USER_ENTRY, with KNOWN confidence — the highest.
 * Only the payload differs per entry type.
 */
@OptIn(ExperimentalUuidApi::class)
object UserEntry {

    private fun draft(kind: FactKind, payload: FactPayload): FactDraft = FactDraft(
        kind = kind,
        payload = payload,
        source = FactSource.USER_ENTRY,
        author = FactAuthor.PERSON,
        entryMethod = EntryMethod.EXPLICIT,
        confidence = FactConfidence.KNOWN,
    )

    // ── Habits ──────────────────────────────────────────────────────────────

    fun defineHabit(
        name: String,
        frequency: HabitFrequency,
        targetValue: Double = 1.0,
        unit: String? = null,
    ): FactDraft = draft(
        FactKind.HABIT_DEFINED,
        FactPayload.HabitDefined(
            habitID = Uuid.random(),
            name = name,
            targetValue = targetValue,
            unit = unit,
            frequency = frequency,
        ),
    )

    fun logHabit(habitID: Uuid, value: Double = 1.0, note: String? = null): FactDraft = draft(
        FactKind.HABIT_LOGGED,
        FactPayload.HabitLogged(habitID = habitID, value = value, note = note),
    )

    // ── Journal ─────────────────────────────────────────────────────────────

    fun reflection(text: String, promptText: String? = null): FactDraft = draft(
        FactKind.REFLECTION_WRITTEN,
        FactPayload.ReflectionWritten(text = text, promptText = promptText),
    )

    fun moment(text: String, tags: List<String> = emptyList()): FactDraft = draft(
        FactKind.MEMORABLE_MOMENT_CAPTURED,
        FactPayload.MemorableMomentCaptured(text = text, tags = tags),
    )

    fun intention(text: String, period: IntentionPeriod, expiresAt: Instant? = null): FactDraft = draft(
        FactKind.INTENTION_SET,
        FactPayload.IntentionSet(text = text, period = period, expiresAt = expiresAt),
    )

    // ── Todo ────────────────────────────────────────────────────────────────

    fun createTodo(title: String, dueDate: Instant? = null, notes: String? = null): FactDraft = draft(
        FactKind.TODO_CREATED,
        FactPayload.TodoCreated(
            todoID = Uuid.random(),
            title = title,
            dueDate = dueDate,
            notes = notes,
        ),
    )

    fun completeTodo(todoID: Uuid): FactDraft = draft(
        FactKind.TODO_COMPLETED,
        FactPayload.TodoCompleted(todoID = todoID),
    )
}
