package com.loca.derive.habits

import com.loca.record.HabitFrequency
import com.loca.signal.Signal
import com.loca.signal.SignalKind
import com.loca.signal.SignalPayload
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.minus
import kotlinx.datetime.plus
import kotlinx.datetime.toLocalDateTime
import kotlinx.datetime.until
import kotlin.uuid.Uuid

/**
 * Pure derivation of habit summaries from a flat signal list.
 *
 * Invariants:
 *  - Latest HABIT_DEFINITION signal wins (name, target, frequency can be updated).
 *  - Habits with no HABIT_COMPLETION signals still appear if a definition exists.
 *  - All outputs are deterministic: same signals + same `today` → same result.
 *  - No signals are written; this is a read-only computation.
 */
object HabitDeriver {

    /**
     * Derive summaries for every defined habit.
     *
     * @param signals  All signals from the Signal store (unfiltered).
     * @param today    Reference date for streaks and grid (normally Clock.System.todayIn(tz)).
     * @param tz       Timezone used to convert Instant → LocalDate.
     */
    fun deriveAll(
        signals: List<Signal>,
        today: LocalDate,
        tz: TimeZone = TimeZone.currentSystemDefault()
    ): List<HabitSummary> {
        val definitions: Map<Uuid, SignalPayload.HabitDefinition> = signals
            .filter { it.kind == SignalKind.HABIT_DEFINITION }
            .mapNotNull { signal ->
                (signal.payload as? SignalPayload.HabitDefinition)?.let { signal to it }
            }
            // Latest edit wins by when it OCCURRED, not by signal-list order
            // (which reflects pipeline processing time and is unstable after replay).
            .groupBy { it.second.habitID }
            .mapValues { (_, pairs) -> pairs.maxBy { it.first.occurredAt }.second }

        // Creation date per habit = earliest definition. Used to fairly window
        // completion rate so a brand-new habit isn't scored against days it
        // didn't yet exist.
        val habitStartByID: Map<Uuid, LocalDate> = signals
            .filter { it.kind == SignalKind.HABIT_DEFINITION }
            .mapNotNull { signal ->
                val p = signal.payload as? SignalPayload.HabitDefinition ?: return@mapNotNull null
                p.habitID to signal.occurredAt.toLocalDateTime(tz).date
            }
            .groupBy({ it.first }, { it.second })
            .mapValues { (_, dates) -> dates.min() }

        val completionsByHabit: Map<Uuid, List<Pair<LocalDate, Double>>> = signals
            .filter { it.kind == SignalKind.HABIT_COMPLETION }
            .mapNotNull { signal ->
                val p = signal.payload as? SignalPayload.HabitCompletion ?: return@mapNotNull null
                val date = signal.occurredAt.toLocalDateTime(tz).date
                Triple(p.habitID, date, p.value)
            }
            .groupBy { it.first }
            .mapValues { (_, triples) -> triples.map { Pair(it.second, it.third) } }

        return definitions.entries
            .map { (habitID, def) ->
                val completions = completionsByHabit[habitID] ?: emptyList()
                val habitStart = habitStartByID[habitID] ?: today
                derive(habitID, def, completions, today, habitStart)
            }
            // Case-insensitive so "Zebra" doesn't sort before "apple".
            .sortedBy { it.name.lowercase() }
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private fun derive(
        habitID: Uuid,
        def: SignalPayload.HabitDefinition,
        completions: List<Pair<LocalDate, Double>>,
        today: LocalDate,
        habitStart: LocalDate
    ): HabitSummary {
        val dates = completions.map { it.first }
        val distinctDays = dates.toHashSet()
        return HabitSummary(
            habitID = habitID,
            name = def.name,
            targetValue = def.targetValue,
            unit = def.unit,
            frequency = def.frequency,
            streak = computeStreak(dates, today),
            completionRate = minOf(completionRate(distinctDays, def.frequency, today, habitStart), 1.0),
            // Distinct days completed — consistent with how streak and rate count.
            totalCompletions = distinctDays.size,
            grid = buildGrid(completions, today)
        )
    }

    fun computeStreak(dates: List<LocalDate>, today: LocalDate): StreakResult {
        if (dates.isEmpty()) return StreakResult(0, 0, null)
        val sorted = dates.distinct().sorted()
        val last = sorted.last()
        val yesterday = today.minus(1, DateTimeUnit.DAY)

        val current = if (last == today || last == yesterday) {
            countConsecutiveBackward(sorted.toHashSet(), last)
        } else {
            0
        }

        val longest = longestRun(sorted)
        return StreakResult(
            current = current,
            longest = maxOf(longest, current),
            lastDate = last
        )
    }

    private fun countConsecutiveBackward(days: HashSet<LocalDate>, from: LocalDate): Int {
        var count = 1
        var cursor = from
        while (true) {
            val prev = cursor.minus(1, DateTimeUnit.DAY)
            if (prev in days) { count++; cursor = prev } else break
        }
        return count
    }

    private fun longestRun(sorted: List<LocalDate>): Int {
        if (sorted.isEmpty()) return 0
        var longest = 1
        var run = 1
        for (i in 1 until sorted.size) {
            if (sorted[i] == sorted[i - 1].plus(1, DateTimeUnit.DAY)) {
                run++
                if (run > longest) longest = run
            } else {
                run = 1
            }
        }
        return longest
    }

    /**
     * Fraction of expected occurrences completed, windowed by frequency and
     * clamped to the habit's lifetime.
     *
     * The denominator is the number of *buckets* (days / weeks / months) that
     * have actually elapsed since the habit was created, within a frequency-
     * appropriate window — so a 3-day-old daily habit is scored out of 3, not
     * 30, and a weekly habit isn't scored against a hard-coded 4 weeks.
     *
     * @param habitStart date the habit was created (earliest definition).
     */
    fun completionRate(
        days: Set<LocalDate>,
        frequency: HabitFrequency,
        today: LocalDate,
        habitStart: LocalDate
    ): Double {
        val windowLength = when (frequency) {
            HabitFrequency.DAILY   -> 30   // ~1 month of days
            HabitFrequency.WEEKLY  -> 84   // 12 weeks
            HabitFrequency.MONTHLY -> 365  // ~12 months
        }
        val windowStart = today.minus(windowLength - 1, DateTimeUnit.DAY)
        val start = maxOf(windowStart, habitStart)
        if (start > today) return 0.0
        val inWindow = days.filter { it >= start && it <= today }

        return when (frequency) {
            HabitFrequency.DAILY -> {
                val totalDays = start.until(today, DateTimeUnit.DAY) + 1
                if (totalDays <= 0) 0.0 else inWindow.size.toDouble() / totalDays
            }
            HabitFrequency.WEEKLY -> {
                // 7-day buckets from a fixed epoch Monday.
                val epoch = LocalDate(1970, 1, 5)
                fun weekIndex(d: LocalDate) = epoch.until(d, DateTimeUnit.DAY) / 7
                val completedWeeks = inWindow.map { weekIndex(it) }.distinct().size
                val totalWeeks = (weekIndex(today) - weekIndex(start)) + 1
                if (totalWeeks <= 0) 0.0 else completedWeeks.toDouble() / totalWeeks
            }
            HabitFrequency.MONTHLY -> {
                fun monthIndex(d: LocalDate) = d.year * 12 + (d.monthNumber - 1)
                val completedMonths = inWindow.map { monthIndex(it) }.distinct().size
                val totalMonths = (monthIndex(today) - monthIndex(start)) + 1
                if (totalMonths <= 0) 0.0 else completedMonths.toDouble() / totalMonths
            }
        }
    }

    fun buildGrid(completions: List<Pair<LocalDate, Double>>, today: LocalDate): List<HabitGridDay> {
        val gridStart = today.minus(364, DateTimeUnit.DAY)
        val byDate = mutableMapOf<LocalDate, Pair<Int, Double>>()
        for ((date, value) in completions) {
            if (date >= gridStart && date <= today) {
                val (cnt, total) = byDate[date] ?: Pair(0, 0.0)
                byDate[date] = Pair(cnt + 1, total + value)
            }
        }
        return (0..364).map { offset ->
            val date = gridStart.plus(offset, DateTimeUnit.DAY)
            val (cnt, total) = byDate[date] ?: Pair(0, 0.0)
            HabitGridDay(date = date, count = cnt, totalValue = total)
        }
    }
}
