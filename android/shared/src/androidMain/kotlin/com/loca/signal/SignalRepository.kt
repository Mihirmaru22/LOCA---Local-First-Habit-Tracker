package com.loca.signal

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.Json

/**
 * Reactive signal store.
 *
 * Exposes a [Flow] that Room re-emits on every insert — consumers do not
 * need to poll or use a reload-key; any write to the signals table
 * propagates automatically.
 */
class SignalRepository(private val dao: SignalDao) {

    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    val signals: Flow<List<Signal>> = dao.observeAll().map { entities ->
        entities.map { json.decodeFromString(Signal.serializer(), it.json) }
    }
}
