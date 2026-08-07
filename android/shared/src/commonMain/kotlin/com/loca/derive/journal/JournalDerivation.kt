package com.loca.derive.journal

import com.loca.record.IntentionPeriod
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDate
import kotlin.uuid.Uuid

data class ReflectionEntry(
    val id: Uuid,
    val date: LocalDate,
    val text: String,
    val promptText: String?
)

data class MomentEntry(
    val id: Uuid,
    val date: LocalDate,
    val text: String,
    val tags: List<String>
)

data class IntentionEntry(
    val id: Uuid,
    val date: LocalDate,
    val text: String,
    val period: IntentionPeriod,
    val expiresAt: Instant?,
    /** True when expiresAt is null or expiresAt is in the future relative to the reference Instant. */
    val isActive: Boolean
)

data class JournalSummary(
    /** All reflections, newest first. */
    val reflections: List<ReflectionEntry>,
    /** All memorable moments, newest first. */
    val moments: List<MomentEntry>,
    /** Intentions not yet expired, newest first. */
    val activeIntentions: List<IntentionEntry>,
    /** Intentions whose expiresAt has passed, newest first. */
    val expiredIntentions: List<IntentionEntry>,
    /** Consecutive days ending today (or yesterday) with at least one reflection or moment. */
    val journalStreak: Int,
    /** Total count of reflections + moments. */
    val totalEntries: Int,
    /** Tag → occurrence count across all moments. Empty when no moments have tags. */
    val tagCloud: Map<String, Int>
)
