import SwiftUI
import SwiftData

// MARK: - LOCAApp

/// The application's entry point.
///
/// ## Single Call Site Rule
///
/// This is the **only** call site for `ModelContainerFactory.makeConfiguredContainer()`
/// in the Main App target (`ModelContainerFactory`'s own documented contract). No
/// other file constructs or holds a production `ModelContainer`. Views access data
/// exclusively via `@Environment(\.modelContext)` and `@Query`, injected here via
/// `.modelContainer(container)`.
///
/// `makeConfiguredContainer()` resolves to either production (App Group + CloudKit)
/// or local development (neither) storage depending on the `LOCAL_DEVELOPMENT`
/// compilation condition — see ADR-009. This file is deliberately unaware of which
/// one it received; its own logic is identical either way.
///
/// ## Failure Handling
///
/// `makeConfiguredContainer()` throws. Container construction happens once, eagerly, in
/// `init()`. On failure, `container` is `nil` and the app shows `ContainerUnavailableView`
/// instead of crashing — consistent with this project's established "never `try!`"
/// discipline (Phase 1 finding M4, first applied at Phase 3's Preview call sites,
/// now applied here at the one call site that matters most: real app launch).
///
/// A production container failure here means something structural is wrong — a
/// missing or mismatched App Group entitlement, an unresolvable schema migration,
/// or a CloudKit container misconfiguration. `ModelContainerFactory` already logs
/// the underlying error via `os.Logger` before this type ever sees it; there is
/// nothing further to diagnose at this layer, only to fail visibly rather than
/// silently.
///
/// ## Scene Configuration
///
/// A single `WindowGroup` hosting `TodayView` (Phase 11.1) directly as its root
/// content. `TodayView` is a NavigationStack wrapping the ModuleDescriptor-driven
/// "Today" surface. When modules >= 3 arrive, the root upgrades to a TabView or
/// Browse grid, but the screens beneath don't change — only this container swaps.
@main
struct LOCAApp: App {

    private let container: ModelContainer?
    private let cloudKitCoordinator: CloudKitSyncCoordinator?

    init() {
        do {
            // makeConfiguredContainer() is the single centralized switch point
            // between production (App Group + CloudKit) and local development
            // (neither) — see ADR-009 and ModelContainerFactory's own doc
            // comment. LOCAApp does not know or care which one it gets.
            let container = try ModelContainerFactory.makeConfiguredContainer()
            self.container = container
            self.cloudKitCoordinator = CloudKitSyncCoordinator(container: container)

            // DEBUG-only: seeds minimal sample data so HabitDetailView,
            // HeatmapView, and AnalyticsCardsView can be exercised before
            // Phase 7's New Habit form exists. No-op if real data already
            // exists. Entirely absent from Release — DebugSeeder itself is
            // #if DEBUG-gated, so this call site must be too, or Release
            // would fail to compile against a symbol that doesn't exist there.
            #if DEBUG
            DebugSeeder.seedIfNeeded(context: container.mainContext)
            #endif
        } catch {
            // ModelContainerFactory has already logged the underlying error.
            // Nothing further to do here except fail visibly via ContainerUnavailableView
            // rather than force-unwrapping into a crash.
            self.container = nil
            self.cloudKitCoordinator = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                TodayView()
                    .modelContainer(container)
                    .task {
                        // .task ties CloudKitSyncCoordinator's observation loop
                        // lifetime to this view's lifetime — cancelled automatically
                        // on disappear, with no manual Task/queue lifecycle management
                        // (Engineering Principles §3.1: structured concurrency only).
                        await cloudKitCoordinator?.start()
                    }
            } else {
                ContainerUnavailableView()
            }
        }
    }
}

// MARK: - ContainerUnavailableView

/// Shown in place of the app's content when `ModelContainerFactory.makeConfiguredContainer()`
/// fails during launch.
///
/// Private to this file: exactly one call site, no reuse, no platform-conditional
/// logic — the same file-count discipline established in Phase 3
/// (`EmptyDetailPlaceholderView`, `EmptySidebarPlaceholderView`).
///
/// This state is not user-recoverable from within the app — a failed container
/// construction means the on-disk store, entitlements, or schema migration path
/// is broken at a level no in-app action can fix. The view exists so a real
/// structural failure produces a legible screen instead of a crash, not to offer
/// a retry affordance that would just fail identically.
private struct ContainerUnavailableView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Unable to Load", systemImage: "exclamationmark.triangle")
        } description: {
            Text("LOCA couldn't set up its data store. Please reinstall the app.")
        }
    }
}
