package com.loca.signal

import com.loca.record.Fact
import kotlinx.datetime.Clock
import kotlin.time.Duration.Companion.days
import kotlin.uuid.Uuid

/** The result of a Signal layer invariant check. */
data class SignalValidationResult(
    /** Signals whose sourceFactID does not appear in the provided fact set (S6). */
    val orphanSignals: List<Signal>,
    /** Signals where more than one Signal references the same sourceFactID (S1). */
    val duplicateSignals: List<Signal>,
    /** Signals with impossible or incoherent timestamps. */
    val malformedSignals: List<Signal>,
    /** Signals produced by an older pipeline version (candidates for replay). */
    val staleVersionSignals: List<Signal>
) {
    /** True only when orphan, duplicate, and malformed sets are all empty. */
    val isValid: Boolean
        get() = orphanSignals.isEmpty() &&
            duplicateSignals.isEmpty() &&
            malformedSignals.isEmpty()
}

/**
 * Validates Signal layer invariants against the Record.
 *
 * Used by SignalContract.validateInvariants and directly in tests to verify
 * the signal set after replay.
 */
class SignalValidator {

    fun validate(signals: List<Signal>, facts: List<Fact>): SignalValidationResult {
        val factIDs = facts.map { it.id }.toSet()
        return SignalValidationResult(
            orphanSignals       = detectOrphans(signals, factIDs),
            duplicateSignals    = detectDuplicates(signals),
            malformedSignals    = detectMalformed(signals),
            staleVersionSignals = detectStaleVersions(signals)
        )
    }

    private fun detectOrphans(signals: List<Signal>, knownFactIDs: Set<Uuid>): List<Signal> =
        signals.filter { it.provenance.sourceFactID !in knownFactIDs }

    private fun detectDuplicates(signals: List<Signal>): List<Signal> {
        val seen = mutableSetOf<Uuid>()
        val duplicates = mutableListOf<Signal>()
        for (signal in signals) {
            val fid = signal.provenance.sourceFactID
            if (!seen.add(fid)) duplicates.add(signal)
        }
        return duplicates
    }

    private fun detectMalformed(signals: List<Signal>): List<Signal> {
        val oneDayFromNow = Clock.System.now().plus(1.days)
        return signals.filter { signal ->
            signal.occurredAt > oneDayFromNow ||
                signal.provenance.transformedAt < signal.provenance.factRecordedAt
        }
    }

    private fun detectStaleVersions(signals: List<Signal>): List<Signal> =
        signals.filter { it.provenance.pipelineVersion != SignalPipeline.VERSION }
}
