import SwiftData
import SwiftUI
import os.log

// MARK: - AppCoordinator

/// Centralizes app-level coordinator lifecycle management.
///
/// On launch, `LOCAApp` constructs all coordinators and passes them to `AppCoordinator`,
/// which manages their startup sequence via a single `.task` modifier on the root view.
/// This replaces 7 separate `.task` modifiers with one unified initialization pipeline.
///
/// ## Coordinators Managed
/// - `CloudKitSyncCoordinator`: Observes CloudKit sync events and flags boards for recalculation.
/// - `StreakMaintenanceCoordinator`: Performs full historical recalculation on flagged boards.
/// - `SyncStatusCoordinator`: Displays CloudKit sync state to the user.
/// - `SignalCollectionCoordinator`: Ingests passive signals (HealthKit, Calendar, Location).
/// - `ReminderScheduler`: Requests notification permission and reschedules reminders.
/// - `ReflectionDelivery`: Generates and delivers daily reflections (Phase 4.1–4.4).
/// - `InterventionDelivery`: Detects and delivers intervention warnings (Phase 5.1–5.5).
///
/// ## Lifecycle
/// Instantiated once per app session in `LOCAApp.init()`. `start()` is called from a single
/// `.task` modifier on `TodayView`, tying the lifetime of all background tasks to the root
/// view's lifetime. Cancellation propagates to all running coordinators when the task is cancelled.
@MainActor
final class AppCoordinator {

    private let container: ModelContainer
    private let cloudKitCoordinator: CloudKitSyncCoordinator?
    private let streakMaintenanceCoordinator: StreakMaintenanceCoordinator?
    private let signalCollectionCoordinator: SignalCollectionCoordinator?
    nonisolated private let logger = Logger(subsystem: "com.loca.app", category: "coordinator")

    /// Creates a new coordinator managing all app-level background tasks.
    ///
    /// - Parameters:
    ///   - container: The shared `ModelContainer`.
    ///   - cloudKitCoordinator: Observer for CloudKit sync events. Pass `nil` in development.
    ///   - streakMaintenanceCoordinator: Full streak recalculator. Pass `nil` in development.
    ///   - signalCollectionCoordinator: Passive signal ingestion. Pass `nil` in development.
    init(
        container: ModelContainer,
        cloudKitCoordinator: CloudKitSyncCoordinator?,
        streakMaintenanceCoordinator: StreakMaintenanceCoordinator?,
        signalCollectionCoordinator: SignalCollectionCoordinator?
    ) {
        self.container = container
        self.cloudKitCoordinator = cloudKitCoordinator
        self.streakMaintenanceCoordinator = streakMaintenanceCoordinator
        self.signalCollectionCoordinator = signalCollectionCoordinator
    }

    /// Starts all coordinators and background loops (reminders, reflections, interventions).
    ///
    /// Runs until the calling `Task` is cancelled. Intended to be driven by a SwiftUI `.task`
    /// modifier on a long-lived view (`TodayView`), not called directly.
    ///
    /// Launches the following in parallel via separate child tasks to avoid serial blocking:
    /// 1. CloudKit sync observation
    /// 2. Streak recalculation consumer loop
    /// 3. Reminder permission + reschedule
    /// 4. Sync status display
    /// 5. Signal collection initialization + loop
    /// 6. Reflection generation loop (Phase 4.1–4.4)
    /// 7. Intervention detection loop (Phase 5.1–5.5)
    func start() async {
        // Tie all background tasks to this coordinator's lifetime via structured concurrency.
        // When start()'s Task is cancelled, all child tasks below stop automatically.
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.startCloudKit() }
            group.addTask { await self.startStreakMaintenance() }
            group.addTask { await self.startReminders(container: self.container) }
            group.addTask { await self.startSyncStatus() }
            group.addTask { await self.startSignalCollection() }
            group.addTask { await self.startReflections(container: self.container) }
            group.addTask { await self.startInterventions(container: self.container) }
            // Wait until any child task completes or the group is cancelled (if parent Task
            // is cancelled, the group cancels and all children stop).
            // In normal operation none of these return, so the group suspends indefinitely.
            for await _ in group { }
        }
    }

    // MARK: - Coordinator Tasks

    private func startCloudKit() async {
        await cloudKitCoordinator?.start()
    }

    private func startStreakMaintenance() async {
        await streakMaintenanceCoordinator?.start()
    }

    private func startReminders(container: ModelContainer) async {
        _ = await ReminderScheduler.shared.requestNotificationPermission()
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

    private func startSyncStatus() async {
        await SyncStatusCoordinator.shared.start()
    }

    private func startSignalCollection() async {
        await signalCollectionCoordinator?.initialize(modelContext: container.mainContext)
        await signalCollectionCoordinator?.start()
    }

    private func startReflections(container: ModelContainer) async {
        while !Task.isCancelled {
            let continueReflections = await ReflectionDelivery.shared.shouldContinueReflections()
            guard continueReflections else {
                logger.debug("Reflection feature suppressed due to low engagement")
                break
            }

            let fetchRequest = FetchDescriptor<HabitBoard>(
                predicate: #Predicate { $0.archivedAt == nil }
            )
            if let boards = try? container.mainContext.fetch(fetchRequest) {
                for board in boards {
                    let logs = (board.logs ?? []).map { LogSnapshot(from: $0) }
                    if let reflection = ReflectionGenerator.generateForHabit(board: board, logs: logs) {
                        await ReflectionDelivery.shared.deliverReflection(reflection)
                        break
                    }
                }
            }

            try? await Task.sleep(for: .seconds(24 * 60 * 60))
        }
    }

    private func startInterventions(container: ModelContainer) async {
        while !Task.isCancelled {
            let continueInterventions = await InterventionDelivery.shared.shouldContinueInterventions()
            guard continueInterventions else {
                logger.debug("Intervention feature suppressed due to low effectiveness")
                break
            }

            let fetchRequest = FetchDescriptor<HabitBoard>(
                predicate: #Predicate { $0.archivedAt == nil }
            )
            if let boards = try? container.mainContext.fetch(fetchRequest) {
                for board in boards {
                    let logs = (board.logs ?? []).map { LogSnapshot(from: $0) }
                    if let prediction = RelapseDetector.detectRelapse(board: board, logs: logs) {
                        await InterventionDelivery.shared.deliverIntervention(prediction)
                        break
                    }
                }
            }

            try? await Task.sleep(for: .seconds(24 * 60 * 60))
        }
    }
}
