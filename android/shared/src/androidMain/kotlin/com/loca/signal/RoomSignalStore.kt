package com.loca.signal

import kotlinx.serialization.json.Json
import kotlin.uuid.Uuid

class RoomSignalStore(private val dao: SignalDao) : SignalStoring {

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    override suspend fun append(signal: Signal) {
        dao.insert(
            SignalEntity(
                id = signal.id.toString(),
                kind = signal.kind.name,
                sourceFactId = signal.provenance.sourceFactID.toString(),
                occurredAt = signal.occurredAt.toEpochMilliseconds(),
                producedAt = signal.producedAt.toEpochMilliseconds(),
                json = json.encodeToString(Signal.serializer(), signal)
            )
        )
    }

    override suspend fun allSignals(): List<Signal> = dao.getAll().map { decode(it) }

    override suspend fun signal(forFactID: Uuid): Signal? =
        dao.getByFactId(forFactID.toString())?.let { decode(it) }

    override suspend fun existingFactIDs(): Set<Uuid> =
        dao.getAllFactIds().mapTo(mutableSetOf()) { Uuid.parse(it) }

    override suspend fun clear() = dao.deleteAll()

    override suspend fun count(): Int = dao.count()

    private fun decode(entity: SignalEntity): Signal =
        json.decodeFromString(Signal.serializer(), entity.json)
}
