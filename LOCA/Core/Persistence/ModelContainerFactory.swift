import SwiftData
import Foundation
import os

// MARK: - ModelContainerFactory

/// Constructs and configures the application's `ModelContainer`.
///
/// This type is a pure namespace of static factory methods — it is never instantiated.
///
/// ## Single Call Site Rule
/// `makeSharedContainer()` is called **exactly once**, in `LOCAApp.swift`.
/// No other file in the Main App target holds a reference to the `ModelContainer`
/// or invokes this factory. Views access the model context exclusively via
/// `@Environment(\.modelContext)` and `@Query`.
///
/// The Widget Extension creates its own container instance by calling
/// `makeSharedContainer()` inside its `TimelineProvider.getTimeline(in:completion:)`.
/// It does **not** share the main app's instance — the two processes read from the
/// same SQLite file via the shared App Group store.
///
/// ## App Group Identifier
/// Both the Main App and Widget Extension targets must have the App Group entitlement
/// configured with `appGroupIdentifier`. A mismatch between the two targets silently
/// directs each process to a different SQLite file, producing an empty widget database
/// with no error or crash (ADR-004, Risk R4).
enum ModelContainerFactory {

    // MARK: - Constants

    /// The App Group identifier shared between the Main App and Widget Extension.
    ///
    /// **Must** match the App Group entitlement in both targets verbatim.
    /// Migrated from the original project working-title placeholder
    /// (`group.com.yourdomain.ripples`) to LOCA's identifier convention in Phase 0.
    /// Confirm this matches your registered Apple Developer Team's actual App Group
    /// before the first CloudKit sync in any environment — `com.mihirmaru.loca` is
    /// a structurally correct placeholder derived from this project's GitHub
    /// identity, not a verified, registered identifier.
    static let appGroupIdentifier = "group.com.mihirmaru.loca"

    private static let logger = Logger(
        subsystem: "com.mihirmaru.loca",
        category: "Persistence"
    )

    // MARK: - Production Container

    /// The iCloud container identifier for this app's CloudKit database.
    ///
    /// Pinned explicitly rather than using `.automatic` so the binding is
    /// deterministic and auditable. Must match the container registered in the
    /// Apple Developer portal and declared in both targets' entitlements files
    /// (`com.apple.developer.icloud-container-identifiers`). [M-2]
    static let cloudKitContainerIdentifier = "iCloud.com.mihirmaru.loca"

    /// Creates a `ModelContainer` backed by the shared App Group SQLite store
    /// with CloudKit synchronisation enabled.
    ///
    /// Uses `ModelConfiguration.groupContainer` to specify the shared App Group,
    /// letting SwiftData manage the SQLite file location within the container.
    /// Both the Main App and Widget Extension pass the same `appGroupIdentifier`
    /// to ensure they address the same physical file.
    ///
    /// `cloudKitDatabase` is bound explicitly to `cloudKitContainerIdentifier`
    /// rather than `.automatic`. This guarantees the same container is used
    /// regardless of entitlement declaration order and makes the binding
    /// auditable without opening the project file. [M-2]
    ///
    /// This method is the single call site for production container construction.
    /// It must only be called from `LOCAApp.swift` in the Main App and from
    /// `TimelineProvider` in the Widget Extension.
    ///
    /// - Returns: A fully configured `ModelContainer` using the shared App Group store.
    /// - Throws: `PersistenceError.containerInitFailed` if SwiftData rejects the
    ///           schema or configuration. Common causes: a missing `MigrationPlan`
    ///           for a schema change, or an entitlements misconfiguration.
    static func makeSharedContainer() throws -> ModelContainer {
        // Schema is passed to `for:` on ModelContainer — the authoritative location.
        // ModelConfiguration specifies *where* and *how* to store the schema,
        // not *what* the schema is. Embedding the schema in ModelConfiguration
        // and also passing it to `for:` was API misuse that created an unspecified
        // reconciliation between two schema references. (H3)
        let schema = Schema(RippleSchemaV1.models)
        let configuration = ModelConfiguration(
            groupContainer: .identifier(appGroupIdentifier),
            cloudKitDatabase: .private(cloudKitContainerIdentifier)
        )
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: RippleMigrationPlan.self,
                configurations: [configuration]
            )
            logger.info("Shared ModelContainer initialised successfully.")
            return container
        } catch {
            logger.error(
                "Shared ModelContainer init failed: \(error.localizedDescription, privacy: .public)"
            )
            throw PersistenceError.containerInitFailed(underlying: error)
        }
    }

    // MARK: - Local Development Container

    // MARK: Development Configuration (ADR-009)
    //
    // Persistent on-disk, but with NO groupContainer and NO cloudKitDatabase —
    // requires neither an App Group entitlement nor a CloudKit container
    // entitlement, both of which cannot be provisioned under a Personal Team.
    // Distinct from makeInMemoryContainer(): that method is for tests/Previews
    // and deliberately wipes data every launch. This method persists to the
    // app's own sandboxed Application Support directory (the SwiftData default
    // when groupContainer: is omitted), so a local development build behaves
    // like a real, continuously-used app across multiple launches — the whole
    // point of having a working development build in the first place.

    /// Creates a persistent, on-disk `ModelContainer` with no App Group and no
    /// CloudKit backing.
    ///
    /// Used only by `makeConfiguredContainer()` when `LOCAL_DEVELOPMENT` is set.
    /// Never call this directly from `LOCAApp` or anywhere else — the whole
    /// point of `makeConfiguredContainer()` existing is that callers never need
    /// to know which container variant they're getting.
    ///
    /// - Returns: A `ModelContainer` backed by local storage only.
    /// - Throws: `PersistenceError.containerInitFailed` on schema/migration failure.
    static func makeLocalContainer() throws -> ModelContainer {
        let schema = Schema(RippleSchemaV1.models)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: RippleMigrationPlan.self,
                configurations: [configuration]
            )
            logger.info("Local development ModelContainer initialised (no App Group, no CloudKit).")
            return container
        } catch {
            logger.error(
                "Local development ModelContainer init failed: \(error.localizedDescription, privacy: .public)"
            )
            throw PersistenceError.containerInitFailed(underlying: error)
        }
    }

    // MARK: - Configured Container (Single Switch Point)

    // MARK: The Only #if In This File (ADR-009)
    //
    // This is the sole compile-time branch between production (App Group +
    // CloudKit) and local development (neither) anywhere in the codebase.
    // LOCA_LOCAL_DEVELOPMENT is a custom Active Compilation Condition set only
    // on the Debug configuration's build settings — deliberately NOT the
    // built-in DEBUG flag, since "is this an optimized build" and "does this
    // build have real entitlements" are orthogonal questions. A team member
    // with a paid account building in Debug mode should still be able to
    // exercise real CloudKit sync; hardcoding this to DEBUG would prevent that.
    //
    // To re-enable production configuration once a paid account is available:
    // remove LOCAL_DEVELOPMENT from the Debug configuration's
    // SWIFT_ACTIVE_COMPILATION_CONDITIONS build setting. Zero code changes.

    /// The single entry point every caller should use. Resolves to
    /// `makeSharedContainer()` (production: App Group + CloudKit) or
    /// `makeLocalContainer()` (local development: neither) based on the
    /// `LOCAL_DEVELOPMENT` compilation condition — never based on the identity
    /// of the caller.
    ///
    /// `LOCAApp.swift` is the only caller. Its own logic is identical
    /// regardless of which branch resolves here.
    ///
    /// - Returns: A `ModelContainer` appropriate for the current build configuration.
    /// - Throws: Whatever the resolved factory method throws.
    static func makeConfiguredContainer() throws -> ModelContainer {
        #if LOCAL_DEVELOPMENT
        return try makeLocalContainer()
        #else
        return try makeSharedContainer()
        #endif
    }

    // MARK: - Extension Process Cache (T7)

    // Constructed once per process on first access (Swift static-let guarantee).
    // Reused by every LogHabitIntent invocation and every WidgetKit timeline
    // refresh in the same App Extension process, avoiding repeated CloudKit
    // stack construction. `nonisolated(unsafe)` is correct: the value is
    // written exactly once (under Swift's lazy-init guarantee) then read-only.
    nonisolated(unsafe) static let extensionContainer: ModelContainer? =
        try? makeConfiguredContainer()

    // MARK: - In-Memory Container

    /// Creates an in-memory `ModelContainer` for use in `XCTest` suites and SwiftUI Previews.
    ///
    /// This container is not persisted to disk and has no CloudKit synchronisation.
    /// It uses the same schema (`RippleSchemaV1`) and migration plan
    /// (`RippleMigrationPlan`) as the production container, ensuring that test
    /// fixtures accurately reflect the production model structure.
    ///
    /// Seed this container with `SeededModelContainer` fixtures (defined in the
    /// test target) for deterministic, repeatable scenarios.
    ///
    /// Usage in a SwiftUI Preview:
    /// ```swift
    /// #Preview {
    ///     let container = try! ModelContainerFactory.makeInMemoryContainer()
    ///     let board = HabitBoard(name: "Running", metricType: MetricType.binary.rawValue)
    ///     container.mainContext.insert(board)
    ///     return HabitCardView(board: board)
    ///         .modelContainer(container)
    /// }
    /// ```
    ///
    /// - Returns: An ephemeral, in-memory `ModelContainer`.
    /// - Throws: `PersistenceError.containerInitFailed` if schema construction fails.
    ///           Under normal circumstances this does not throw; the `try!` form is
    ///           acceptable in `#Preview` bodies.
    static func makeInMemoryContainer() throws -> ModelContainer {
        // ModelConfiguration specifies in-memory storage only — no schema embedded.
        // Schema is passed to ModelContainer(for:) as the authoritative argument. (H3)
        let schema = Schema(RippleSchemaV1.models)
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true
        )
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: RippleMigrationPlan.self,
                configurations: [configuration]
            )
            logger.debug("In-memory ModelContainer initialised.")
            return container
        } catch {
            logger.error(
                "In-memory ModelContainer init failed: \(error.localizedDescription, privacy: .public)"
            )
            throw PersistenceError.containerInitFailed(underlying: error)
        }
    }
}
