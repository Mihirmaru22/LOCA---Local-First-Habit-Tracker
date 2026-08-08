package com.loca.derive.health

import kotlinx.datetime.LocalDate

data class DailyHealthSummary(
    val date: LocalDate,
    /** Sum of all step-record counts for this day. Null if no step data. */
    val steps: Double?,
    /** Average of all heart-rate readings for this day. Null if no HR data. */
    val avgHeartRateBpm: Double?,
    /** Total sleep time in hours across all sessions for this day. Null if no sleep data. */
    val sleepHours: Double?,
)

data class HealthOverview(
    /** Days with any health data, newest first. */
    val days: List<DailyHealthSummary>,
    /** Average daily steps across days that have step data. Null if none. */
    val avgSteps: Double?,
    /** Average heart rate across days that have HR data. Null if none. */
    val avgHeartRateBpm: Double?,
    /** Average sleep hours across days that have sleep data. Null if none. */
    val avgSleepHours: Double?,
)
