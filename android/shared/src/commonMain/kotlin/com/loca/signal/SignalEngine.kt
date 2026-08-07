package com.loca.signal

import com.loca.record.Fact
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.uuid.Uuid

/**
 * The single gatekeeper for all writes to the Signal layer.
 *
 * SignalEngine consumes Facts and produces Signals.
 * It is the Signal layer's analogue to RecordEngine.
 * A Mutex replaces Swift actor isolation — only one coroutine writes at a time.
 *
 * Enforced invariants:
 *  S1: One Signal per Fact. Processing the same Fact twice is idempotent.
 *  S2: Determinism. Same Fact → same Signal (id, kind, payload).
 *  S3: Replay. clear() + process(same facts) = same signals.
 *  S4: Provenance completeness. Every Signal carries full SignalProvenance.
 *  S5: Read-only from Record. SignalEngine never writes to the Record.
 */
class SignalEngine(private val store: SignalStoring) {

    private val mutex = Mutex()
    private val knownFactIDs = mutableSetOf<Uuid>()

    /**
     * Must be called once after construction to restore dedup state
     * from a warm store (e.g. after process restart).
     */
    suspend fun initialize() {
        val existing = store.existingFactIDs()
        mutex.withLock { knownFactIDs.addAll(existing) }
    }

    /**
     * Transform a Fact into a Signal and store it.
     *
     * Returns the produced Signal, or null if the Fact was already processed
     * (idempotent — not an error).
     *
     * @throws SignalError.PipelineFailure if transformation fails.
     * @throws SignalError.StorageFailure if the store fails.
     */
    suspend fun process(fact: Fact): Signal? = mutex.withLock {
        if (knownFactIDs.contains(fact.id)) return@withLock null

        val signal = try {
            SignalPipeline.transform(fact)
        } catch (e: SignalPipelineError) {
            throw SignalError.PipelineFailure(e)
        }

        try {
            store.append(signal)
        } catch (e: Exception) {
            throw SignalError.StorageFailure(e)
        }

        knownFactIDs.add(fact.id)
        signal
    }

    /**
     * Process a sequence of Facts in order.
     * Facts already processed are silently skipped.
     * Returns only the newly produced Signals.
     */
    suspend fun processAll(facts: List<Fact>): List<Signal> {
        val produced = mutableListOf<Signal>()
        for (fact in facts) {
            process(fact)?.let { produced.add(it) }
        }
        return produced
    }

    /**
     * Clear all Signals and reprocess every Fact in the given sequence.
     *
     * Replay guarantee: given the same ordered sequence of Facts, replay
     * always produces the same set of Signals (same IDs, same payloads).
     * This holds because Signal.id == source Fact.id.
     *
     * Pass RecordEngine.replayableFacts() for the canonical sequence.
     */
    suspend fun replay(from: List<Fact>): List<Signal> {
        mutex.withLock {
            try {
                store.clear()
            } catch (e: Exception) {
                throw SignalError.ReplayFailure("Store clear failed: ${e.message}")
            }
            knownFactIDs.clear()
        }
        return processAll(from)
    }

    // ── Reads ─────────────────────────────────────────────────────────────────

    suspend fun allSignals(): List<Signal> = store.allSignals()

    suspend fun signal(forFactID: Uuid): Signal? = store.signal(forFactID)

    suspend fun count(): Int = store.count()
}
