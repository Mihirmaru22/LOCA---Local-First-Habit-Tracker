import Foundation

// MARK: - SignalContract

/// Documents and enforces the Signal Engine's contract.
///
/// The Signal Engine (Build2) sits between the Record (Build1) and the
/// Derivation layer (Build3). It transforms immutable Facts into normalized
/// Signals without adding interpretation.
///
/// ## Ownership
///
/// The Signal Engine owns the Signal layer exclusively:
///  - Only SignalEngine writes Signals.
///  - All other consumers read Signals only.
///  - The Record is upstream; the Signal layer is downstream.
///  - Derivation (Build3) reads Signals; it never reads Facts directly.
///
/// ## Responsibilities
///
/// The Signal Engine:
///  - Reads Facts from the Record.
///  - Transforms each Fact into exactly one normalized Signal.
///  - Stores Signals in the Signal Store.
///  - Supports replay: clears and regenerates all Signals from the Record.
///  - Validates Signal layer invariants on demand.
///
/// ## Explicitly NOT the Signal Engine's job
///
/// The Signal Engine does NOT:
///  - Infer meaning, score values, detect patterns, or correlate signals.
///  - Write to or modify the Record.
///  - Emit notifications, schedule timers, or drive UI.
///  - Add fields that do not come from the source Fact.
///  - Perform AI or LLM integration.
///
/// ## Invariants
///
/// S1: One Signal per Fact. Each Fact produces at most one Signal.
///     Processing the same Fact twice is idempotent (not an error).
///
/// S2: Determinism. The same Fact always produces the same Signal:
///     same id, same kind, same payload. (transformedAt will differ on replay,
///     but Signal.id and Signal.payload are identical.)
///
/// S3: Replay completeness. Clearing all Signals and replaying the Record's
///     replayableFacts() reproduces the same set of Signals.
///
/// S4: Provenance completeness. Every Signal carries a fully populated
///     SignalProvenance. No Signal is anonymous.
///
/// S5: Read-only from Record. SignalEngine never calls any write method
///     on the Record or on any Fact.
///
/// S6: No orphan Signals. Every Signal's sourceFactID must correspond to a
///     Fact in the Record. Orphan Signals indicate a replay or store fault.
///
/// ## Runtime behavior
///
/// The Signal Engine updates incrementally:
///  - After a new Fact is written: process the new Fact.
///  - After a replay: replay(from: recordEngine.replayableFacts()).
///  - After a correction: process the correction Fact.
///  - After a bulk import: processAll(importedFacts).
///
/// The Signal Engine is NEVER driven by timers or schedules.
/// Updates happen only when new Facts exist to process.
enum SignalContract {

    // MARK: - Invariant tags

    enum Invariant: String, CaseIterable {
        case oneSignalPerFact       = "S1"
        case determinism            = "S2"
        case replayCompleteness     = "S3"
        case provenanceCompleteness = "S4"
        case readOnlyFromRecord     = "S5"
        case noOrphanSignals        = "S6"
    }

    // MARK: - Runtime validation

    /// Validates all Signal layer invariants.
    ///
    /// - Parameters:
    ///   - signals: All Signals currently in the Signal Store.
    ///   - facts: All Facts currently in the Record (used for orphan check).
    ///   - expectedCount: If provided, verifies total signal count matches.
    ///
    /// - Throws: `SignalContractError` if any invariant is violated.
    static func validateInvariants(
        signals: [Signal],
        facts: [Fact],
        expectedCount: Int? = nil
    ) throws {
        if let expected = expectedCount, signals.count != expected {
            throw SignalContractError.countMismatch(expected: expected, actual: signals.count)
        }

        let result = SignalValidator().validate(signals: signals, against: facts)

        if !result.orphanSignals.isEmpty {
            throw SignalContractError.orphanSignals(count: result.orphanSignals.count)
        }
        if !result.duplicateSignals.isEmpty {
            throw SignalContractError.duplicateSignals(count: result.duplicateSignals.count)
        }
        if !result.malformedSignals.isEmpty {
            throw SignalContractError.malformedSignals(count: result.malformedSignals.count)
        }
    }
}

// MARK: - SignalContractError

enum SignalContractError: Error, Sendable {
    case countMismatch(expected: Int, actual: Int)
    case orphanSignals(count: Int)
    case duplicateSignals(count: Int)
    case malformedSignals(count: Int)
}
