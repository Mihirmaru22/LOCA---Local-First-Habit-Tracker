package com.loca.record

import kotlin.uuid.Uuid

// ── RecordStoring interface ───────────────────────────────────────────────────

/**
 * Persistence contract for the Record layer.
 *
 * RecordEngine is the ONLY caller of append().
 * All reads are available to any consumer.
 * Implementations must be safe for concurrent suspend calls.
 */
interface RecordStoring {
    suspend fun append(fact: Fact)
    suspend fun allFacts(): List<Fact>
    suspend fun facts(matching: RecordQuery): List<Fact>
    suspend fun count(matching: RecordQuery): Int
    suspend fun existingIDs(): Set<Uuid>
}

// ── InMemoryRecordStore ───────────────────────────────────────────────────────

/**
 * In-memory RecordStoring for testing and replay.
 *
 * Properties:
 *  - Append-only: no update or delete.
 *  - Deterministic: allFacts() returns facts in insertion order.
 *  - Not thread-safe by itself — RecordEngine's Mutex serializes all writes.
 */
class InMemoryRecordStore : RecordStoring {

    private val storage = mutableListOf<Fact>()
    private val idSet = mutableSetOf<Uuid>()

    override suspend fun append(fact: Fact) {
        storage.add(fact)
        idSet.add(fact.id)
    }

    override suspend fun allFacts(): List<Fact> = storage.toList()

    override suspend fun facts(matching: RecordQuery): List<Fact> {
        var result = filtered(matching)
        result = sorted(result, matching.order)
        if (matching.offset > 0) result = result.drop(matching.offset)
        if (matching.limit != null) result = result.take(matching.limit)
        return result
    }

    override suspend fun count(matching: RecordQuery): Int = filtered(matching).size

    override suspend fun existingIDs(): Set<Uuid> = idSet.toSet()

    // ── Private helpers ───────────────────────────────────────────────────────

    private fun filtered(query: RecordQuery): List<Fact> =
        storage.filter { fact ->
            if (query.kinds != null && fact.kind !in query.kinds) return@filter false
            if (query.dateRange != null && !query.dateRange.contains(fact.occurredAt)) return@filter false
            if (query.sources != null && fact.provenance.source !in query.sources) return@filter false
            true
        }

    private fun sorted(facts: List<Fact>, order: RecordOrder): List<Fact> = when (order) {
        RecordOrder.RECORDED_AT_ASCENDING   -> facts.sortedBy { it.recordedAt }
        RecordOrder.RECORDED_AT_DESCENDING  -> facts.sortedByDescending { it.recordedAt }
        RecordOrder.OCCURRED_AT_ASCENDING   -> facts.sortedBy { it.occurredAt }
        RecordOrder.OCCURRED_AT_DESCENDING  -> facts.sortedByDescending { it.occurredAt }
    }
}
