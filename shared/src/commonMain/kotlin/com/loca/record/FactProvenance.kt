package com.loca.record

import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable

// ── FactSource ────────────────────────────────────────────────────────────────

@Serializable
enum class FactSource {
    USER_ENTRY,
    HEALTH_KIT,
    CALENDAR,
    SIRI,
    SHORTCUT,
    WIDGET,
    BACKGROUND,
    MIGRATION
}

// ── FactAuthor ────────────────────────────────────────────────────────────────

@Serializable
enum class FactAuthor {
    PERSON,
    SENSOR,
    SYSTEM
}

// ── EntryMethod ───────────────────────────────────────────────────────────────

@Serializable
enum class EntryMethod {
    EXPLICIT,
    IMPORTED,
    INFERRED,
    RESTORED
}

// ── FactConfidence ────────────────────────────────────────────────────────────

/**
 * Confidence ordering follows declaration order (KNOWN is highest).
 * Enums are already [Comparable] by ordinal, so `a < b` works directly —
 * no explicit compareTo is needed (and Enum.compareTo cannot be overridden).
 */
@Serializable
enum class FactConfidence {
    KNOWN,
    HIGH,
    MEDIUM,
    LOW,
    ESTIMATED
}

// ── FactProvenance ────────────────────────────────────────────────────────────

/**
 * Full audit trail for a Fact.
 * Answers: who, how, where, and how certain.
 */
@Serializable
data class FactProvenance(
    val source: FactSource,
    val author: FactAuthor,
    val entryMethod: EntryMethod,
    val confidence: FactConfidence,
    val sourceIdentifier: String? = null,
    val externalTimestamp: Instant? = null
)
