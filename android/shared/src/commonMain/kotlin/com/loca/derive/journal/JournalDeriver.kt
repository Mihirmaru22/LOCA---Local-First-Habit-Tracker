package com.loca.derive.journal

import com.loca.signal.Signal
import com.loca.signal.SignalKind
import com.loca.signal.SignalPayload
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.minus
import kotlinx.datetime.toLocalDateTime

/**
 * Pure derivation of journal state from a flat signal list.
 *
 * Invariants:
 *  - All signals are read; none are written.
 *  - Same signals + same (today, now) → same result.
 *  - Entries are ordered newest-first within each list.
 *  - An intention with no expiresAt is always active.
 */
object JournalDeriver {

    /**
     * Derive a full JournalSummary from the signal store.
     *
     * @param signals  All signals from the Signal store (unfiltered).
     * @param today    Reference date for streak computation.
     * @param now      Reference instant for intention expiry checks.
     * @param tz       Timezone used to convert Instant → LocalDate.
     */
    fun deriveAll(
        signals: List<Signal>,
        today: LocalDate,
        now: Instant,
        tz: TimeZone = TimeZone.currentSystemDefault()
    ): JournalSummary {
        val reflections = signals
            .filter { it.kind == SignalKind.REFLECTION }
            .sortedByDescending { it.occurredAt }
            .mapNotNull { signal ->
                val p = signal.payload as? SignalPayload.Reflection ?: return@mapNotNull null
                ReflectionEntry(
                    id = signal.id,
                    date = signal.occurredAt.toLocalDateTime(tz).date,
                    text = p.text,
                    promptText = p.promptText
                )
            }

        val moments = signals
            .filter { it.kind == SignalKind.MEMORABLE_MOMENT }
            .sortedByDescending { it.occurredAt }
            .mapNotNull { signal ->
                val p = signal.payload as? SignalPayload.MemorableMoment ?: return@mapNotNull null
                MomentEntry(
                    id = signal.id,
                    date = signal.occurredAt.toLocalDateTime(tz).date,
                    text = p.text,
                    tags = p.tags
                )
            }

        val (activeIntentions, expiredIntentions) = signals
            .filter { it.kind == SignalKind.INTENTION }
            .sortedByDescending { it.occurredAt }
            .mapNotNull { signal ->
                val p = signal.payload as? SignalPayload.Intention ?: return@mapNotNull null
                IntentionEntry(
                    id = signal.id,
                    date = signal.occurredAt.toLocalDateTime(tz).date,
                    text = p.text,
                    period = p.period,
                    expiresAt = p.expiresAt,
                    isActive = p.expiresAt == null || p.expiresAt > now
                )
            }
            .partition { it.isActive }

        val entryDates: Set<LocalDate> =
            (reflections.map { it.date } + moments.map { it.date }).toHashSet()

        val tagCloud: Map<String, Int> = moments
            .flatMap { it.tags }
            .groupingBy { it }
            .eachCount()

        return JournalSummary(
            reflections = reflections,
            moments = moments,
            activeIntentions = activeIntentions,
            expiredIntentions = expiredIntentions,
            journalStreak = computeStreak(entryDates, today),
            totalEntries = reflections.size + moments.size,
            tagCloud = tagCloud
        )
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private fun computeStreak(days: Set<LocalDate>, today: LocalDate): Int {
        if (days.isEmpty()) return 0
        val yesterday = today.minus(1, DateTimeUnit.DAY)
        val anchor = when {
            today in days -> today
            yesterday in days -> yesterday
            else -> return 0
        }
        var count = 1
        var cursor = anchor
        while (true) {
            val prev = cursor.minus(1, DateTimeUnit.DAY)
            if (prev in days) { count++; cursor = prev } else break
        }
        return count
    }
}
