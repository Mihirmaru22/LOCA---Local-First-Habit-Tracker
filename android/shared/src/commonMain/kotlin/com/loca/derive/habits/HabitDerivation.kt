package com.loca.derive.habits

import com.loca.record.HabitFrequency
import kotlinx.datetime.LocalDate
import kotlin.uuid.Uuid

/**
 * Per-habit derived state computed from HABIT_DEFINITION + HABIT_COMPLETION signals.
 * All fields are deterministic given the same signal set and reference date.
 */
data class HabitSummary(
    val habitID: Uuid,
    val name: String,
    val targetValue: Double,
    val unit: String?,
    val frequency: HabitFrequency,
    val streak: StreakResult,
    /** Completion rate 0.0–1.0 over the trailing 30 days (capped at 1.0). */
    val completionRate: Double,
    val totalCompletions: Int,
    /** 365-day grid ending today, zero-filled for days with no completions. */
    val grid: List<HabitGridDay>
)

/** Current and longest consecutive-day streaks. */
data class StreakResult(
    val current: Int,
    val longest: Int,
    /** Calendar date of the most recent completion, or null if none. */
    val lastDate: LocalDate?
)

/** One cell in the 365-day completion grid. */
data class HabitGridDay(
    val date: LocalDate,
    /** Number of completions logged on this day. */
    val count: Int,
    /** Sum of all logged values on this day. */
    val totalValue: Double
)
