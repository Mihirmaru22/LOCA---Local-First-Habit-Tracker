import SwiftData
import Foundation
import os

// MARK: - ModelContainerFactory

/// Constructs and configures the application's `ModelContainer`.
///
/// This type is a pure namespace of static factory methods — it is never instantiated.
///
/// ## Single Call Site Rule
/// `makeSharedContainer()` is called **exactly once**, in `RippleCloneApp.swift`.
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
    /// Replace `yourdomain` with the project's actual reverse-DNS team identifier
    /// before the first CloudKit sync in any environment.
    static let appGroupIdentifier = "group.com.yourdomain.ripples"

    private static let logger = Logger(
        subsystem: "com.yourdomain.rippleclone",
        category: "Persistence"
    )

    // MARK: - Production Container

    /// Creates a `ModelContainer` backed by the shared App Group SQLite store
    /// with CloudKit synchronisation enabled.
    ///
    /// Uses `ModelConfiguration.groupContainer` to specify the shared App Group,
    /// letting SwiftData manage the SQLite file location within the container.
    /// Both the Main App and Widget Extension pass the same `appGroupIdentifier`
    /// to ensure they address the same physical file.
    ///
    /// `cloudKitDatabase: .automatic` binds to the first iCloud container declared
    /// in the target's entitlements. Before production release, confirm this resolves
    /// to the intended CloudKit container identifier. If explicit binding is required,
    /// replace `.automatic` with `.private("iCloud.com.yourdomain.rippleclone")`.
    ///
    /// This method is the single call site for production container construction.
    /// It must only be called from `RippleCloneApp.swift` in the Main App and from
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
            cloudKitDatabase: .automatic
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
