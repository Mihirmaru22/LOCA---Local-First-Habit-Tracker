import SwiftUI
import SwiftData
import os.log

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
@MainActor
struct LOCAApp: App {

    private let container: ModelContainer?
    private let cloudKitCoordinator: CloudKitSyncCoordinator?
    private let streakMaintenanceCoordinator: StreakMaintenanceCoordinator?
    nonisolated private let logger = Logger(subsystem: "com.loca.app", category: "app")

    init() {
        do {
            // makeConfiguredContainer() is the single centralized switch point
            // between production (App Group + CloudKit) and local development
            // (neither) — see ADR-009 and ModelContainerFactory's own doc
            // comment. LOCAApp does not know or care which one it gets.
            let container = try ModelContainerFactory.makeConfiguredContainer()
            self.container = container
            self.cloudKitCoordinator = CloudKitSyncCoordinator(container: container)
            // Consumer half of the needsStreakRecalculation pipeline (C-1):
            // CloudKitSyncCoordinator flags boards after an import; this repairs
            // their cached streaks from the full log history and clears the flag.
            self.streakMaintenanceCoordinator = StreakMaintenanceCoordinator(container: container)

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
            self.streakMaintenanceCoordinator = nil
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
                    .task {
                        // Consumer half of the streak-recalculation pipeline (C-1):
                        // runs a launch repair pass for boards flagged in a prior
                        // session, then recalculates on each completed CloudKit import.
                        // Separate .task so it observes concurrently with the coordinator
                        // above rather than serially behind its never-returning loop.
                        await streakMaintenanceCoordinator?.start()
                    }
                    .task {
                        // Request notification permission for reminders (Phase 3.1).
                        // Non-critical; silent fail if permission denied.
                        _ = await ReminderScheduler.shared.requestNotificationPermission()
                    }
                    .task {
                        // Reschedule all reminders on launch (Phase 3.1).
                        // Handles reminders that may have been cleared on system restart
                        // or prior app updates.
                        //
                        // HabitBoard is a non-Sendable SwiftData @Model, so we extract
                        // Sendable ReminderRequest snapshots here on the MainActor before
                        // handing them across the ReminderScheduler actor boundary.
                        let fetchRequest = FetchDescriptor<HabitBoard>(
                            predicate: #Predicate { $0.archivedAt == nil }
                        )
                        if let boards = try? container.mainContext.fetch(fetchRequest) {
                            let requests: [ReminderRequest] = boards.compactMap { board in
                                guard let time = board.preferredReminderTime else { return nil }
                                return ReminderRequest(id: board.id, name: board.name, time: time)
                            }
                            await ReminderScheduler.shared.rescheduleAllReminders(requests)
                        }
                    }
                    .task {
                        // Monitor CloudKit sync status (Phase 3.5).
                        // Non-blocking: displays sync state to user without interruption.
                        await SyncStatusCoordinator.shared.start()
                    }
                    .task {
                        // Generate and deliver reflections (Phase 4.1–4.4).
                        // One honest sentence tied to progress, delivered as push.
                        // Phase 4.4: Exit gate — if engagement < 30% over 20 reflections, suppress.
                        while true {
                            // Check if feature is still earning attention (Phase 4.4)
                            if !ReflectionDelivery.shared.shouldContinueReflections() {
                                logger.debug("Reflection feature suppressed due to low engagement")
                                break
                            }

                            let fetchRequest = FetchDescriptor<HabitBoard>(
                                predicate: #Predicate { $0.archivedAt == nil }
                            )
                            if let boards = try? container.mainContext.fetch(fetchRequest) {
                                // Generate one reflection per active habit
                                for board in boards {
                                    let logs = (board.logs ?? []).map { LogSnapshot(from: $0) }
                                    if let reflection = ReflectionGenerator.generateForHabit(board: board, logs: logs) {
                                        await ReflectionDelivery.shared.deliverReflection(reflection)
                                        // Limit to one reflection per app session to avoid noise
                                        break
                                    }
                                }
                            }

                            // Wait ~24 hours before regenerating (Phase 4.1: rare).
                            try? await Task.sleep(for: .seconds(24 * 60 * 60))
                        }
                    }
                    .task {
                        // Detect and deliver interventions (Phase 5.1–5.4).
                        // High-confidence relapse warnings, delivered as push.
                        // Phase 5.5: Exit gate — if effectiveness < 50% over 10 interventions, suppress.
                        while true {
                            // Check if feature is still effective (Phase 5.5)
                            if !InterventionDelivery.shared.shouldContinueInterventions() {
                                logger.debug("Intervention feature suppressed due to low effectiveness")
                                break
                            }

                            let fetchRequest = FetchDescriptor<HabitBoard>(
                                predicate: #Predicate { $0.archivedAt == nil }
                            )
                            if let boards = try? container.mainContext.fetch(fetchRequest) {
                                // Detect relapse risk for each active habit
                                for board in boards {
                                    let logs = (board.logs ?? []).map { LogSnapshot(from: $0) }
                                    if let prediction = RelapseDetector.detectRelapse(board: board, logs: logs) {
                                        await InterventionDelivery.shared.deliverIntervention(prediction)
                                        // Limit to one intervention per app session to avoid noise
                                        break
                                    }
                                }
                            }

                            // Wait ~24 hours before re-checking (Phase 5: infrequent).
                            try? await Task.sleep(for: .seconds(24 * 60 * 60))
                        }
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
