import Foundation

// MARK: - RecordError

/// Errors the Record layer surfaces. Never silently repaired — every failure
/// is an explicit, named outcome the caller must handle.
enum RecordError: Error, Sendable {

    /// A fact with this ID already exists in the Record. The first write wins;
    /// subsequent writes with the same ID are hard errors (not silent no-ops).
    /// Callers should not retry with the same ID unless the first write is
    /// known to have failed (e.g. storageFailure).
    case duplicateFact(existingID: UUID)

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
