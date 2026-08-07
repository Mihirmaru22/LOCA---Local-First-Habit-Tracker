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
            .mapNotNull { it.payload as? SignalPayload.HabitDefinition }
            .groupBy { it.habitID }
            .mapValues { (_, defs) -> defs.last() }

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
                derive(habitID, def, completions, today)
            }
            .sortedBy { it.name }
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private fun derive(
        habitID: Uuid,
        def: SignalPayload.HabitDefinition,
        completions: List<Pair<LocalDate, Double>>,
        today: LocalDate
    ): HabitSummary {
        val dates = completions.map { it.first }
        return HabitSummary(
            habitID = habitID,
            name = def.name,
            targetValue = def.targetValue,
            unit = def.unit,
            frequency = def.frequency,
            streak = computeStreak(dates, today),
            completionRate = minOf(completionRate(dates.toHashSet(), def.frequency, today), 1.0),
            totalCompletions = dates.size,
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

    fun completionRate(days: Set<LocalDate>, frequency: HabitFrequency, today: LocalDate): Double {
        val windowStart = today.minus(29, DateTimeUnit.DAY)
        val inWindow = days.filter { it >= windowStart && it <= today }
        return when (frequency) {
            HabitFrequency.DAILY -> inWindow.size / 30.0
            HabitFrequency.WEEKLY -> {
                // Group by 7-day bucket from a fixed epoch Monday
                val epoch = LocalDate(1970, 1, 5)
                val weeks = inWindow.map { epoch.until(it, DateTimeUnit.DAY) / 7 }.distinct().size
                weeks / 4.0
            }
            HabitFrequency.MONTHLY -> {
                val hasThisMonth = days.any { it.year == today.year && it.monthNumber == today.monthNumber }
                if (hasThisMonth) 1.0 else 0.0
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
