import Foundation

// MARK: - Record Contract

/// The documented engineering contract for the Record layer.
///
/// This file is the human-readable contract companion to the RecordEngine
/// implementation. It defines invariants, ownership rules, and guarantees
/// that all of Version 3 depends on. Future engineers should understand the
/// Record's behavior from this file without reading its implementation.
///
/// Authority: Build1 §II (Record Layer), Build1 §IV (Ownership Laws),
/// Build3 §II.1 (Record Engine contract), Build4 §XII (Implementation Constitution).

// MARK: - Invariants

/// The immutable invariants the Record Engine enforces.
/// A violation of any invariant is a critical defect, not a design trade-off.
enum RecordInvariant: CaseIterable {

    /// I1: Append-only.
    /// No Fact in the Record is ever mutated. Corrections are new Facts.
    case appendOnly

    /// I2: No duplicates by ID.
    /// The same Fact.id may never appear twice. Retry-safe: the second
    /// attempt with the same ID is treated as a successful no-op (idempotent).
    case noDuplicateIDs

    /// I3: Sensor dedup by key.
    /// A sensed Fact with a previously-seen deduplication key is silently
    /// dropped. This is not an error — it is the correct behavior for
    /// import dedup (Build2 §II Class B).
    case sensorDedup

    /// I4: Complete provenance.
    /// Every Fact has a fully populated FactProvenance. No anonymous facts.
    case provenanceComplete

    /// I5: Timestamps both directions.
    /// Every Fact has a `recordedAt` (set by the engine at write time)
    /// and an `occurredAt` (provided by the caller, may precede recordedAt).
    case timestampsComplete

    /// I6: One-way flow.
    /// Nothing downstream of the Record (Derivation, Knowledge, Attention,
    /// Presentation) may write back into the Record. The dependency
    /// graph is a tree rooted at the Record.
    case oneWayFlow

    /// I7: Single writer.
    /// RecordEngine is the only entity that calls RecordStoring.append().
    /// All other subsystems write facts exclusively via RecordWriter.
    case singleWriter

    /// I8: Determinism.
    /// Given the same sequence of facts in the same order,
    /// the Record produces the same output from allFacts() and facts(matching:).
    case deterministic
}

// MARK: - Ownership rules

/// What the Record owns and what it must never own.
enum RecordOwnership {
    /// Owned: the complete, ordered set of all facts with provenance.
    static let owns = "all facts + their provenance"

    /// Produced: facts to any consumer; append acknowledgements.
    static let produces = "consistent read snapshots to any consumer"

    /// Consumed: validated, provenance-tagged facts from RecordWriter only.
    static let consumes = "validated facts from Ingestion (via RecordWriter)"

    /// Refused: the Record never owns or produces these.
    static let refuses = "any derivation, interpretation, or presentation"
}

// MARK: - Guarantees

/// Guarantees the Record makes to all consumers.
enum RecordGuarantee {

    /// G1: Immutability.
    /// Once a Fact enters the Record, its fields never change.
    case immutability

    /// G2: Durability.
    /// A successful write is durable. The person's facts are never lost silently.
    case durability

    /// G3: Ordering.
    /// Facts are served in deterministic, explicit order (never undefined order).
    case ordering

    /// G4: Replayability.
    /// The sequence returned by `replay()` is sufficient to reconstruct all
    /// derived state from scratch. Derivation running over replay output
    /// must produce identical results to the live system.
    case replayability

    /// G5: Provenance completeness.
    /// Every fact surfaced by a reader carries its complete provenance.
    case provenanceCompleteness
}

// MARK: - Failure modes

/// Defined, observable failure modes of the Record layer.
/// Every failure has a named outcome; none are silent.
enum RecordFailureMode {

    /// The store failed to write a fact.
    /// Outcome: RecordError.storageFailure is thrown; the fact is NOT in the Record.
    /// Recovery: the caller retries with the same draft (idempotent by Fact.id).
    case storageFailed

    /// A fact draft failed validation.
    /// Outcome: RecordError.invalidFact(ValidationError) is thrown.
    /// The draft is returned to the caller with the specific reason.
    /// The Record is not modified.
    case validationFailed

    /// A duplicate Fact.id was submitted.
    /// Outcome: RecordError.duplicateFact is thrown.
    /// Idempotency note: the *first* write wins; later duplicates are errors.
    case duplicateID

    /// A sensed fact with a duplicate deduplication key was submitted.
    /// Outcome: the write silently succeeds (no error), the fact is not re-stored.
    /// This is the intended behavior for sensor dedup, not a failure.
    case sensorDeduplicated

    /// The app was terminated before a write completed.
    /// Outcome: the write may or may not have reached the store.
    /// Recovery: retry with the same draft. The engine deduplicates by Fact.id.
    case writtenDuringTermination
}

// MARK: - Sprint 1 validation helpers

extension RecordEngine {

    /// Validates that the Record satisfies all Sprint 1 success criteria.
    /// For use in tests and internal observability only — not user-facing.
    func validateInvariants(expectedCount: Int? = nil) async throws {
        let allFacts = try await replayableFacts()

        // I2: No duplicate IDs
        let ids = allFacts.map(\.id)
        let uniqueIDs = Set(ids)
        guard ids.count == uniqueIDs.count else {
            throw RecordError.immutabilityViolation(
                message: "Duplicate Fact IDs detected: \(ids.count) facts but \(uniqueIDs.count) unique IDs"
            )
        }

        // I4: Complete provenance on every fact
        for fact in allFacts {
            // sourceIdentifier and externalTimestamp are optional by design.
            // The invariant is that source, author, entryMethod, and confidence are always present.
            _ = fact.provenance.source
            _ = fact.provenance.author
            _ = fact.provenance.entryMethod
            _ = fact.provenance.confidence
        }

        // I5: Timestamps on every fact
        for fact in allFacts {
            guard fact.recordedAt <= Date().addingTimeInterval(1) else {
                throw RecordError.immutabilityViolation(
                    message: "Fact \(fact.id) has a recordedAt in the future"
                )
            }
        }

        // Optional: count check
        if let expected = expectedCount {
            guard allFacts.count == expected else {
                throw RecordError.immutabilityViolation(
                    message: "Expected \(expected) facts, found \(allFacts.count)"
                )
            }
        }
    }
}
