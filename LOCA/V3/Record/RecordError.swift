import Foundation

// MARK: - RecordError

/// Errors the Record layer surfaces. Never silently repaired — every failure
/// is an explicit, named outcome the caller must handle.
enum RecordError: Error, Sendable {

    /// A fact with this ID already exists in the Record. Append-only means
    /// the same ID may never be written twice (idempotency of retries: the
    /// first write wins and the caller treats the duplicate as success).
    case duplicateFact(existingID: UUID)

    /// A sensed/imported fact with this deduplication key already exists.
    /// Prevents double-counting sensor samples (Build2 dedup contract).
    case duplicateDedupKey(key: String)

    /// The underlying persistent store returned an error.
    case storageFailure(underlying: any Error)

    /// The caller attempted an operation the Record forbids —
    /// e.g. mutation of a prior fact, or direct deletion without a deletion fact.
    case immutabilityViolation(message: String)

    /// The fact failed validation. Validation errors are never silently repaired;
    /// the invalid draft is returned to the caller for correction.
    case invalidFact(ValidationError)
}

// MARK: - ValidationError

/// Reasons a FactDraft is rejected before it can enter the Record.
/// Every rejection is explicit — the caller receives the reason and the field.
enum ValidationError: Error, Sendable {

    /// A field required for this fact kind was absent or empty.
    case missingRequiredField(field: String)

    /// A field's value fell outside the allowed range.
    case fieldOutOfBounds(field: String, allowed: String)

    /// The payload type does not match the declared FactKind.
    case malformedPayload(String)
}
