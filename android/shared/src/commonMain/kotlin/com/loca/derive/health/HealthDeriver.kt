package com.loca.derive.health

import com.loca.signal.Signal
import com.loca.signal.SignalKind
import com.loca.signal.SignalPayload
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime

/**
 * Pure derivation of health overview from a flat signal list.
 *
 * Each HEALTH_SAMPLE signal carries a sampleType ("steps", "heart_rate_bpm",
 * "sleep_duration_hours"). Daily totals/averages are computed per type:
 *  - steps: summed (each signal is a contiguous segment)
 *  - heart_rate_bpm: averaged (each signal is an average for that session)
 *  - sleep_duration_hours: summed (multiple sessions in one night)
 */
object HealthDeriver {

    fun deriveOverview(
        signals: List<Signal>,
        tz: TimeZone = TimeZone.currentSystemDefault()
    ): HealthOverview {
        data class Key(val date: LocalDate, val sampleType: String)

        val grouped = mutableMapOf<Key, MutableList<Double>>()
        for (signal in signals) {
            if (signal.kind != SignalKind.HEALTH_SAMPLE) continue
            val p = signal.payload as? SignalPayload.HealthSample ?: continue
            val date = signal.occurredAt.toLocalDateTime(tz).date
            grouped.getOrPut(Key(date, p.sampleType)) { mutableListOf() }.add(p.value)
        }

        val allDates = grouped.keys.map { it.date }.distinct().sortedDescending()

        val days = allDates.map { date ->
            DailyHealthSummary(
                date = date,
                steps = grouped[Key(date, "steps")]?.sum(),
                avgHeartRateBpm = grouped[Key(date, "heart_rate_bpm")]?.average(),
                sleepHours = grouped[Key(date, "sleep_duration_hours")]?.sum(),
            )
        }

        fun List<Double>.avgOrNull() = takeIf { isNotEmpty() }?.average()

        return HealthOverview(
            days = days,
            avgSteps = days.mapNotNull { it.steps }.avgOrNull(),
            avgHeartRateBpm = days.mapNotNull { it.avgHeartRateBpm }.avgOrNull(),
            avgSleepHours = days.mapNotNull { it.sleepHours }.avgOrNull(),
        )
    }
}
