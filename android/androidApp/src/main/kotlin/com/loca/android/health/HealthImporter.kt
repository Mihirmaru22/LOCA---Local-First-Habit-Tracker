package com.loca.android.health

import com.loca.record.EntryMethod
import com.loca.record.FactAuthor
import com.loca.record.FactConfidence
import com.loca.record.FactDraft
import com.loca.record.FactKind
import com.loca.record.FactPayload
import com.loca.record.FactSource
import com.loca.record.RecordEngine
import com.loca.record.RecordError
import com.loca.signal.SignalEngine
import kotlinx.datetime.Clock
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.Instant
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atStartOfDayIn
import kotlinx.datetime.minus
import kotlinx.datetime.toKotlinInstant
import kotlinx.datetime.toLocalDateTime
import java.util.UUID as JavaUUID
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

@OptIn(ExperimentalUuidApi::class)
class HealthImporter(
    private val manager: HealthConnectManager,
    private val recordEngine: RecordEngine,
    private val signalEngine: SignalEngine,
) {

    suspend fun importRecentData() {
        if (!manager.hasPermissions()) return

        val now = Clock.System.now()
        val tz = TimeZone.currentSystemDefault()
        val start = now.toLocalDateTime(tz).date
            .minus(30, DateTimeUnit.DAY)
            .atStartOfDayIn(tz)

        importSteps(start, now)
        importHeartRate(start, now)
        importSleep(start, now)
    }

    private suspend fun importSteps(start: Instant, end: Instant) {
        val records = manager.readSteps(start, end)
        for (record in records) {
            val startInstant = record.startTime.toKotlinInstant()
            val draft = FactDraft(
                id = deterministicUuid(record.metadata.id),
                kind = FactKind.HEALTH_SAMPLE_IMPORTED,
                payload = FactPayload.HealthSampleImported(
                    sampleType = "steps",
                    value = record.count.toDouble(),
                    unit = "steps",
                    startDate = startInstant,
                    endDate = record.endTime.toKotlinInstant(),
                ),
                occurredAt = startInstant,
                source = FactSource.HEALTH_KIT,
                author = FactAuthor.SENSOR,
                entryMethod = EntryMethod.IMPORTED,
                confidence = FactConfidence.HIGH,
                sourceIdentifier = record.metadata.id,
                externalTimestamp = startInstant,
            )
            appendIfNew(draft)
        }
    }

    private suspend fun importHeartRate(start: Instant, end: Instant) {
        val records = manager.readHeartRate(start, end)
        for (record in records) {
            if (record.samples.isEmpty()) continue
            val avgBpm = record.samples.map { it.beatsPerMinute }.average()
            val startInstant = record.startTime.toKotlinInstant()
            val draft = FactDraft(
                id = deterministicUuid(record.metadata.id),
                kind = FactKind.HEALTH_SAMPLE_IMPORTED,
                payload = FactPayload.HealthSampleImported(
                    sampleType = "heart_rate_bpm",
                    value = avgBpm,
                    unit = "bpm",
                    startDate = startInstant,
                    endDate = record.endTime.toKotlinInstant(),
                ),
                occurredAt = startInstant,
                source = FactSource.HEALTH_KIT,
                author = FactAuthor.SENSOR,
                entryMethod = EntryMethod.IMPORTED,
                confidence = FactConfidence.HIGH,
                sourceIdentifier = record.metadata.id,
                externalTimestamp = startInstant,
            )
            appendIfNew(draft)
        }
    }

    private suspend fun importSleep(start: Instant, end: Instant) {
        val records = manager.readSleep(start, end)
        for (record in records) {
            val startInstant = record.startTime.toKotlinInstant()
            val endInstant = record.endTime.toKotlinInstant()
            val durationHours = java.time.Duration.between(record.startTime, record.endTime)
                .toSeconds() / 3600.0
            val draft = FactDraft(
                id = deterministicUuid(record.metadata.id),
                kind = FactKind.HEALTH_SAMPLE_IMPORTED,
                payload = FactPayload.HealthSampleImported(
                    sampleType = "sleep_duration_hours",
                    value = durationHours,
                    unit = "hours",
                    startDate = startInstant,
                    endDate = endInstant,
                ),
                occurredAt = startInstant,
                source = FactSource.HEALTH_KIT,
                author = FactAuthor.SENSOR,
                entryMethod = EntryMethod.IMPORTED,
                confidence = FactConfidence.HIGH,
                sourceIdentifier = record.metadata.id,
                externalTimestamp = startInstant,
            )
            appendIfNew(draft)
        }
    }

    private suspend fun appendIfNew(draft: FactDraft) {
        try {
            val fact = recordEngine.append(draft)
            signalEngine.process(fact)
        } catch (_: RecordError.DuplicateFact) {
            // already imported — skip silently
        }
    }

    private fun deterministicUuid(hcId: String): Uuid =
        Uuid.parse(JavaUUID.nameUUIDFromBytes(hcId.toByteArray()).toString())
}
