import Foundation

// MARK: - SignalValidationResult

/// The result of a Signal layer invariant check.
struct SignalValidationResult: Sendable {

    /// Signals whose sourceFactID does not appear in the provided fact set (S6).
    let orphanSignals: [Signal]

    /// Signals where more than one Signal references the same sourceFactID (S1).
    let duplicateSignals: [Signal]

    /// Signals with impossible or incoherent timestamps.
    let malformedSignals: [Signal]

    /// Signals produced by an older pipeline version (candidates for replay).
    let staleVersionSignals: [Signal]

    /// True only when orphan, duplicate, and malformed sets are all empty.
    var isValid: Bool {
        orphanSignals.isEmpty &&
        duplicateSignals.isEmpty &&
        malformedSignals.isEmpty
    }
}

// MARK: - SignalValidator

/// Validates Signal layer invariants against the Record.
///
/// Used by SignalContract.validateInvariants(_:against:expectedCount:) and
/// directly in tests to verify the signal set after replay.
struct SignalValidator: Sendable {

    func validate(signals: [Signal], against facts: [Fact]) -> SignalValidationResult {
        let factIDs = Set(facts.map(\.id))
        return SignalValidationResult(
            orphanSignals: detectOrphans(in: signals, knownFactIDs: factIDs),
            duplicateSignals: detectDuplicates(in: signals),
            malformedSignals: detectMalformed(in: signals),
            staleVersionSignals: detectStaleVersions(in: signals)
        )
    }

    // MARK: - Private checks

    private func detectOrphans(in signals: [Signal], knownFactIDs: Set<UUID>) -> [Signal] {
        signals.filter { !knownFactIDs.contains($0.provenance.sourceFactID) }
    }

    private func detectDuplicates(in signals: [Signal]) -> [Signal] {
        var seen: Set<UUID> = []
        var duplicates: [Signal] = []
        for signal in signals {
            let fid = signal.provenance.sourceFactID
            if seen.contains(fid) {
                duplicates.append(signal)
            } else {
                seen.insert(fid)
            }
        }
        return duplicates
    }

    private func detectMalformed(in signals: [Signal]) -> [Signal] {
        let oneDayFromNow = Date().addingTimeInterval(86_400)
        return signals.filter { signal in
            if signal.occurredAt > oneDayFromNow { return true }
            if signal.provenance.transformedAt < signal.provenance.factRecordedAt { return true }
            return false
        }
    }

    private func detectStaleVersions(in signals: [Signal]) -> [Signal] {
        signals.filter { $0.provenance.pipelineVersion != SignalPipeline.version }
    }
}
