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

@Serializable
enum class FactConfidence {
    KNOWN,
    HIGH,
    MEDIUM,
    LOW,
    ESTIMATED;

    operator fun compareTo(other: FactConfidence): Int =
        this.ordinal.compareTo(other.ordinal)
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
