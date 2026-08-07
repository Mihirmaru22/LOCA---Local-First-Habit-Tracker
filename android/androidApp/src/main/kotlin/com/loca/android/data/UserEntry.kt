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
import kotlinx.datetime.Clock
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atStartOfDayIn
import kotlinx.datetime.isoDayNumber
import kotlinx.datetime.plus
import kotlinx.datetime.todayIn
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

    /**
     * Set an intention. If no explicit expiry is given, it is derived from the
     * period so the intention naturally expires at the end of its window —
     * daily at the start of tomorrow, weekly at the start of next Monday,
     * monthly at the start of next month.
     */
    fun intention(text: String, period: IntentionPeriod, expiresAt: Instant? = null): FactDraft = draft(
        FactKind.INTENTION_SET,
        FactPayload.IntentionSet(
            text = text,
            period = period,
            expiresAt = expiresAt ?: expiryFor(period),
        ),
    )

    private fun expiryFor(period: IntentionPeriod): Instant {
        val tz = TimeZone.currentSystemDefault()
        val today = Clock.System.todayIn(tz)
        val boundary: LocalDate = when (period) {
            IntentionPeriod.DAILY ->
                today.plus(1, DateTimeUnit.DAY)
            IntentionPeriod.WEEKLY ->
                // isoDayNumber: Mon=1..Sun=7 → days until the next Monday
                today.plus(8 - today.dayOfWeek.isoDayNumber, DateTimeUnit.DAY)
            IntentionPeriod.MONTHLY ->
                LocalDate(today.year, today.monthNumber, 1).plus(1, DateTimeUnit.MONTH)
        }
        return boundary.atStartOfDayIn(tz)
    }

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

    /**
     * Correct a field of the creation fact (edit a task). [factID] is the
     * todo's creation Fact id (TodoItem.factID). Field names match what
     * TodoDeriver applies: "title", "dueDate", "notes". An empty
     * correctedValue clears the field (null due date / notes).
     */
    fun correctTodoField(factID: Uuid, field: String, correctedValue: String): FactDraft = draft(
        FactKind.CORRECTION_SUBMITTED,
        FactPayload.CorrectionSubmitted(
            targetFactID = factID,
            field = field,
            correctedValue = correctedValue,
        ),
    )

    /** Delete a task by targeting its creation fact id (TodoItem.factID). */
    fun deleteTodo(factID: Uuid): FactDraft = draft(
        FactKind.DELETION_REQUESTED,
        FactPayload.DeletionRequested(targetFactID = factID),
    )
}
