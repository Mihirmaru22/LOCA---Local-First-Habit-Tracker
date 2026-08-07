package com.loca.record

import kotlinx.serialization.json.Json
import kotlin.uuid.Uuid

class RoomRecordStore(private val dao: FactDao) : RecordStoring {

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    override suspend fun append(fact: Fact) {
        dao.insert(
            FactEntity(
                id = fact.id.toString(),
                kind = fact.kind.name,
                source = fact.provenance.source.name,
                recordedAt = fact.recordedAt.toEpochMilliseconds(),
                occurredAt = fact.occurredAt.toEpochMilliseconds(),
                json = json.encodeToString(Fact.serializer(), fact)
            )
        )
    }

    override suspend fun allFacts(): List<Fact> = dao.getAll().map { decode(it) }

    override suspend fun facts(matching: RecordQuery): List<Fact> {
        var result = allFacts()
        if (matching.kinds != null) result = result.filter { it.kind in matching.kinds }
        if (matching.dateRange != null) result = result.filter { matching.dateRange.contains(it.occurredAt) }
        if (matching.sources != null) result = result.filter { it.provenance.source in matching.sources }
        result = sorted(result, matching.order)
        if (matching.offset > 0) result = result.drop(matching.offset)
        if (matching.limit != null) result = result.take(matching.limit)
        return result
    }

    override suspend fun count(matching: RecordQuery): Int = facts(matching).size

    override suspend fun existingIDs(): Set<Uuid> =
        dao.getAllIds().mapTo(mutableSetOf()) { Uuid.parse(it) }

    private fun decode(entity: FactEntity): Fact =
        json.decodeFromString(Fact.serializer(), entity.json)

    private fun sorted(facts: List<Fact>, order: RecordOrder): List<Fact> = when (order) {
        RecordOrder.RECORDED_AT_ASCENDING   -> facts.sortedBy { it.recordedAt }
        RecordOrder.RECORDED_AT_DESCENDING  -> facts.sortedByDescending { it.recordedAt }
        RecordOrder.OCCURRED_AT_ASCENDING   -> facts.sortedBy { it.occurredAt }
        RecordOrder.OCCURRED_AT_DESCENDING  -> facts.sortedByDescending { it.occurredAt }
    }
}
