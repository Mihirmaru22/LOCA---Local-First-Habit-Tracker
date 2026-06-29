import Foundation

// MARK: - PersistenceError

/// Domain-specific errors arising from SwiftData persistence and container operations.
///
/// All cases conform to `LocalizedError` and provide descriptions suitable for
/// structured `os.Logger` output. These strings are written to logs and are
/// **never** shown directly to the user. User-facing error presentation uses a
/// non-blocking in-app notification overlay, implemented in Phase 10.
///
/// ## Usage
/// ```swift
/// do {
///     try context.save()
/// } catch {
///     throw PersistenceError.saveFailed(underlying: error)
/// }
/// ```
///
/// ## Rollback Requirement
/// Callers that mutate in-memory model state before a save must roll back
/// those mutations in their `catch` block before re-throwing. See
/// `HabitBoard.archive(in:)` for the canonical pattern.
enum PersistenceError: LocalizedError {

    /// The App Group container URL could not be resolved from the given identifier.
    ///
    /// Common causes:
    /// - The App Group capability is missing from the target's entitlements.
    /// - The identifier string does not match the one in the entitlements file.
    /// - The entitlements file is not included in the current build configuration.
    case containerURLNotFound(identifier: String)

    /// `ModelContainer` initialisation failed.
    ///
    /// Common causes:
    /// - The on-disk store schema is incompatible with the current `VersionedSchema`
    ///   and no `MigrationPlan` covers the gap.
    /// - An entitlements or App Group configuration error prevents store access.
    /// - A `@Model` type is missing from `RippleSchemaV1.models`.
    case containerInitFailed(underlying: Error)

    /// A `ModelContext.save()` call failed.
    ///
    /// The caller is responsible for rolling back any in-memory model mutations
    /// before re-throwing. See `HabitBoard.archive(in:)` for the canonical rollback
    /// pattern.
    case saveFailed(underlying: Error)

    /// A `SchemaMigrationPlan` stage failed during container initialisation.
    ///
    /// - Parameters:
    ///   - fromVersion: Human-readable version string of the source schema
    ///                  (e.g., `"1.0.0"`).
    ///   - toVersion:   Human-readable version string of the target schema.
    ///   - underlying:  The error produced by the failing migration stage.
    case migrationFailed(fromVersion: String, toVersion: String, underlying: Error)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {

        case .containerURLNotFound(let identifier):
            return """
                App Group container URL not found for identifier '\(identifier)'. \
                Verify that the App Group capability is configured on both the \
                Main App and Widget Extension targets and that the identifier \
                matches exactly — a single-character mismatch produces an empty \
                widget database with no crash or warning (ADR-004).
                """

        case .containerInitFailed(let error):
            return "ModelContainer initialisation failed: \(error.localizedDescription)"

        case .saveFailed(let error):
            return "ModelContext save failed: \(error.localizedDescription)"

        case .migrationFailed(let from, let to, let error):
            return """
                Schema migration from v\(from) to v\(to) failed: \
                \(error.localizedDescription)
                """
        }
    }
}
