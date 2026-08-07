package com.loca.android.health

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import kotlinx.datetime.Instant
import kotlinx.datetime.toJavaInstant

class HealthConnectManager(private val context: Context) {

    companion object {
        val PERMISSIONS: Set<String> = setOf(
            HealthPermission.getReadPermission(StepsRecord::class),
            HealthPermission.getReadPermission(HeartRateRecord::class),
            HealthPermission.getReadPermission(SleepSessionRecord::class),
        )
    }

    fun isAvailable(): Boolean = try {
        HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE
    } catch (e: Exception) {
        false
    }

    private fun client(): HealthConnectClient = HealthConnectClient.getOrCreate(context)

    suspend fun hasPermissions(): Boolean {
        if (!isAvailable()) return false
        return client().permissionController.getGrantedPermissions().containsAll(PERMISSIONS)
    }

    suspend fun readSteps(start: Instant, end: Instant): List<StepsRecord> =
        client().readRecords(
            ReadRecordsRequest(
                recordType = StepsRecord::class,
                timeRangeFilter = TimeRangeFilter.between(start.toJavaInstant(), end.toJavaInstant())
            )
        ).records

    suspend fun readHeartRate(start: Instant, end: Instant): List<HeartRateRecord> =
        client().readRecords(
            ReadRecordsRequest(
                recordType = HeartRateRecord::class,
                timeRangeFilter = TimeRangeFilter.between(start.toJavaInstant(), end.toJavaInstant())
            )
        ).records

    suspend fun readSleep(start: Instant, end: Instant): List<SleepSessionRecord> =
        client().readRecords(
            ReadRecordsRequest(
                recordType = SleepSessionRecord::class,
                timeRangeFilter = TimeRangeFilter.between(start.toJavaInstant(), end.toJavaInstant())
            )
        ).records
}
