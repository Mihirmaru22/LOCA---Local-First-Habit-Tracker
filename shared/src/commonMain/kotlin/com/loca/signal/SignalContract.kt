package com.loca.signal

import com.loca.record.Fact

/**
 * Documents and enforces the Signal Engine's contract.
 *
 * The Signal Engine (Build2) sits between the Record (Build1) and the
 * Derivation layer (Build3). It transforms immutable Facts into normalized
 * Signals without adding interpretation.
 *
 * ## Ownership
 *  - Only SignalEngine writes Signals.
 *  - All other consumers read Signals only.
 *  - The Record is upstream; the Signal layer is downstream.
 *  - Derivation (Build3) reads Signals; it never reads Facts directly.
 *
 * ## Responsibilities
 *  - Reads Facts from the Record.
 *  - Transforms each Fact into exactly one normalized Signal.
 *  - Stores Signals in the Signal Store.
 *  - Supports replay: clears and regenerates all Signals from the Record.
 *  - Validates Signal layer invariants on demand.
 *
 * ## Explicitly NOT the Signal Engine's job
 *  - Infer meaning, score values, detect patterns, or correlate signals.
 *  - Write to or modify the Record.
 *  - Emit notifications, schedule timers, or drive UI.
 *  - Add fields that do not come from the source Fact.
 *  - Perform AI or LLM integration.
 *
 * ## Invariants
 *  S1: One Signal per Fact. Processing the same Fact twice is idempotent.
 *  S2: Determinism. Same Fact → same id, kind, payload (transformedAt differs).
 *  S3: Replay completeness. Clearing and replaying reproduces the same Signals.
 *  S4: Provenance completeness. Every Signal carries full SignalProvenance.
 *  S5: Read-only from Record. SignalEngine never writes to the Record.
 *  S6: No orphan Signals. Every sourceFactID corresponds to a Fact in the Record.
 *
 * The Signal Engine is NEVER driven by timers or schedules.
 * Updates happen only when new Facts exist to process.
 */
object SignalContract {

    /** Invariant tags. */
    enum class Invariant(val tag: String) {
        ONE_SIGNAL_PER_FACT("S1"),
        DETERMINISM("S2"),
        REPLAY_COMPLETENESS("S3"),
        PROVENANCE_COMPLETENESS("S4"),
        READ_ONLY_FROM_RECORD("S5"),
        NO_ORPHAN_SIGNALS("S6")
    }

    /**
     * Validates all Signal layer invariants.
     *
     * @param signals All Signals currently in the Signal Store.
     * @param facts All Facts currently in the Record (used for orphan check).
     * @param expectedCount If provided, verifies total signal count matches.
     *
     * @throws SignalContractError if any invariant is violated.
     */
    fun validateInvariants(
        signals: List<Signal>,
        facts: List<Fact>,
        expectedCount: Int? = null
    ) {
        if (expectedCount != null && signals.size != expectedCount) {
            throw SignalContractError.CountMismatch(expectedCount, signals.size)
        }

        val result = SignalValidator().validate(signals, facts)

        if (result.orphanSignals.isNotEmpty()) {
            throw SignalContractError.OrphanSignals(result.orphanSignals.size)
        }
        if (result.duplicateSignals.isNotEmpty()) {
            throw SignalContractError.DuplicateSignals(result.duplicateSignals.size)
        }
        if (result.malformedSignals.isNotEmpty()) {
            throw SignalContractError.MalformedSignals(result.malformedSignals.size)
        }
    }
}

/** Contract violations detected by SignalContract.validateInvariants. */
sealed class SignalContractError(message: String) : Exception(message) {
    class CountMismatch(val expected: Int, val actual: Int) :
        SignalContractError("Count mismatch: expected $expected, got $actual")
    class OrphanSignals(val count: Int) :
        SignalContractError("$count orphan signal(s)")
    class DuplicateSignals(val count: Int) :
        SignalContractError("$count duplicate signal(s)")
    class MalformedSignals(val count: Int) :
        SignalContractError("$count malformed signal(s)")
}
