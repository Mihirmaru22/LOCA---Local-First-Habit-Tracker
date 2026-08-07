package com.loca.signal

import kotlin.uuid.Uuid

/**
 * The persistence contract for the Signal layer.
 *
 * SignalEngine is the ONLY caller of append() and clear().
 * All reads are available to any consumer.
 * Implementations must be safe for concurrent suspend calls.
 */
interface SignalStoring {
    /** Store a signal. Called only by SignalEngine. */
    suspend fun append(signal: Signal)

    /** Return all signals in insertion order. */
    suspend fun allSignals(): List<Signal>

    /** Return the signal produced from the given Fact, or null if none exists. */
    suspend fun signal(forFactID: Uuid): Signal?

    /**
     * Return the set of all source Fact IDs for which signals exist.
     * Used by SignalEngine to rebuild dedup state on init.
     */
    suspend fun existingFactIDs(): Set<Uuid>

    /** Remove all signals. Called exclusively during replay. */
    suspend fun clear()

    /** Total number of signals in the store. */
    suspend fun count(): Int
}

/**
 * An in-memory SignalStoring implementation for testing and replay.
 *
 * Properties:
 *  - Append-only: clear() is the only bulk write; append() is the single write.
 *  - Deterministic: allSignals() returns signals in insertion order.
 *  - O(1) lookup: signal(forFactID:) uses a map index.
 *  - Not thread-safe by itself — SignalEngine's Mutex serializes all writes.
 */
class InMemorySignalStore : SignalStoring {

    private val storage = mutableListOf<Signal>()
    private val factIDIndex = mutableMapOf<Uuid, Int>()

    override suspend fun append(signal: Signal) {
        val index = storage.size
        storage.add(signal)
        factIDIndex[signal.provenance.sourceFactID] = index
    }

    override suspend fun allSignals(): List<Signal> = storage.toList()

    override suspend fun signal(forFactID: Uuid): Signal? =
        factIDIndex[forFactID]?.let { storage[it] }

    override suspend fun existingFactIDs(): Set<Uuid> = factIDIndex.keys.toSet()

    override suspend fun clear() {
        storage.clear()
        factIDIndex.clear()
    }

    override suspend fun count(): Int = storage.size
}
