package com.loca.record

import kotlinx.datetime.Instant

// ── RecordDateRange ───────────────────────────────────────────────────────────

data class RecordDateRange(
    val start: Instant,
    val end: Instant
) {
    fun contains(instant: Instant): Boolean =
        instant >= start && instant <= end
}

// ── RecordOrder ───────────────────────────────────────────────────────────────

enum class RecordOrder {
    RECORDED_AT_ASCENDING,
    RECORDED_AT_DESCENDING,
    OCCURRED_AT_ASCENDING,
    OCCURRED_AT_DESCENDING
}

// ── RecordQuery ───────────────────────────────────────────────────────────────

/**
 * Declarative query against the Record.
 * All fields are optional — omitting a field means "no filter on that dimension".
 */
data class RecordQuery(
    val kinds: Set<FactKind>? = null,
    val dateRange: RecordDateRange? = null,
    val sources: Set<FactSource>? = null,
    val order: RecordOrder = RecordOrder.RECORDED_AT_ASCENDING,
    val limit: Int? = null,
    val offset: Int = 0
) {
    companion object {
        val all = RecordQuery()
        fun forKind(kind: FactKind) = RecordQuery(kinds = setOf(kind))
        fun forPillar(pillar: Pillar) = RecordQuery(
            kinds = FactKind.entries.filter { it.pillar == pillar }.toSet()
        )
    }
}
