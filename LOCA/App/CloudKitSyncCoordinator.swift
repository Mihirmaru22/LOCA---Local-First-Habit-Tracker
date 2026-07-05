import SwiftData
import CoreData
import SwiftUI
import os

// MARK: - CloudKitSyncCoordinator

/// Observes CloudKit sync activity on the shared `ModelContainer` and invalidates
/// cached streak data on active boards after a bulk import.
///
/// ## Why This Type Exists (Phase 0)
///
/// `HabitBoard.needsStreakRecalculation` (added in Phase 1's H1 fix) has no effect
/// until something actually sets it to `true`. This type is that something. Without
/// it, the flag remains permanently `false`, and the CloudKit last-write-wins risk
/// H1 was written to guard against — two devices with divergent offline log
/// histories syncing and one device's cached streak silently overwriting the
/// other's — is not actually mitigated at runtime, only documented as a known risk.
///
/// ## Why Not `ModelContainerFactory`
///
/// Engineering Principles §3.4 describes the event observer as living inside
/// `ModelContainerFactory`. `ModelContainerFactory`'s own doc comment describes
/// itself as "a pure namespace of static factory methods... never instantiated" —
/// adding stateful `NotificationCenter` observation and `ModelContext` mutation to
/// that type would contradict its own stated single-responsibility contract. This
/// type exists instead, owned and started once by `LOCAApp`, matching the framing
/// already established in `HabitBoard.swift`'s H1 documentation ("observer in
/// `RippleCloneApp`"). `ModelContainerFactory` itself is unmodified except for
/// identifier constants.
///
/// ## Lifecycle
///
/// Instantiated once in `LOCAApp.init()` alongside the shared `ModelContainer`.
/// Started via `.task { await coordinator.start() }` attached to the root view —
/// this ties the observation loop's lifetime to the view hierarchy's lifetime
/// using SwiftUI's own cancellation mechanism, with no manual thread or queue
/// management (Engineering Principles §3.1: structured concurrency only).
///
/// ## What It Does Not Do
///
/// Does not perform the actual streak recalculation — that is `StreakCalculator`'s
/// job (Phase 2), triggered separately wherever a board with
/// `needsStreakRecalculation == true` is next displayed or explicitly recalculated.
/// This type's only responsibility is flagging which boards need it, in response to
/// evidence that new data may have arrived from another device.
@MainActor
final class CloudKitSyncCoordinator {

    private let container: ModelContainer
    private let logger = Logger(subsystem: "com.mihirmaru.loca", category: "CloudKitSync")

    // MARK: Idempotency Guard (Phase 0 review finding H1)
    //
    // `start()` is invoked from a `.task` attached to `RootNavigationView` — a
    // per-window view, not a per-app one. `WindowGroup` provides a "New Window"
    // command on macOS by default, with zero opt-in required. Opening a second
    // window creates a second `RootNavigationView`, firing a second `.task`, which
    // calls `start()` again on this same shared coordinator instance (`LOCAApp`
    // holds exactly one `CloudKitSyncCoordinator`, not one per window). Without
    // this guard, each call independently subscribes to the same notification
    // stream — every CloudKit import would be fetched, mutated, and saved once
    // per open window instead of once per app.
    //
    // The guard makes `start()` idempotent regardless of call count, which is the
    // correct fix: it protects the actual multi-window case and any other future
    // duplicate-invocation path, without requiring every call site to separately
    // reason about how many windows might be open.
    private var isObserving = false

    /// - Parameter container: The shared `ModelContainer` constructed by
    ///   `ModelContainerFactory.makeSharedContainer()` in `LOCAApp.init()`.
    ///   This type never constructs its own container.
    init(container: ModelContainer) {
        self.container = container
    }

    // MARK: - Observation Loop

    // MARK: NSPersistentCloudKitContainer.Event Bridging
    //
    // NotificationCenter.default.notifications(named:) returns an AsyncSequence —
    // the Foundation-provided bridge from the legacy notification-callback API to
    // structured concurrency, satisfying Engineering Principles §3.1's requirement
    // that system callbacks be "bridged via withCheckedContinuation or AsyncStream,
    // not wrapped in DispatchQueue.main.async." No DispatchQueue appears anywhere
    // in this type.
    //
    // The explicit `Task.isCancelled` check inside the loop satisfies Engineering
    // Principles §3.3 ("Task.isCancelled is checked at the top of every loop body
    // in long-running tasks") even though `for await` over a system AsyncSequence
    // already cooperatively stops yielding once the consuming Task is cancelled —
    // the check costs nothing and removes any ambiguity about compliance.

    /// Begins observing `NSPersistentCloudKitContainer.Event` notifications.
    ///
    /// Idempotent — a second call while already observing is a no-op (Phase 0
    /// review finding H1). Runs until the calling `Task` is cancelled — intended
    /// to be driven by a SwiftUI `.task` modifier on a long-lived view, not called
    /// directly in a fire-and-forget `Task {}`.
    ///
    /// In Simulator or development environments without a signed-in iCloud account
    /// or a correctly provisioned CloudKit container entitlement, this notification
    /// stream may never fire. That is expected, not a defect — it means no CloudKit
    /// sync activity occurred, not that observation failed silently.
    func start() async {
        guard !isObserving else { return }
        isObserving = true

        let notifications = NotificationCenter.default.notifications(
            named: NSPersistentCloudKitContainer.eventChangedNotification
        )

        for await notification in notifications {
            guard !Task.isCancelled else { break }

            guard let event = notification.userInfo?[
                NSPersistentCloudKitContainer.eventNotificationUserInfoKey
            ] as? NSPersistentCloudKitContainer.Event else {
                continue
            }

            handle(event)
        }
    }

    // MARK: - Event Handling

    // MARK: Event Filtering and Failure Logging
    //
    // Three event types exist: .setup, .import, .export. Only .import represents
    // new data arriving from another device — .export means we sent data out,
    // which cannot change our own local streak correctness, and .setup is
    // infrastructure-only. Filtering to .import matches the intent already
    // documented in HabitBoard.swift's H1 comment ("whenever a bulk import event
    // may have delivered LogEntry records").
    //
    // Per Engineering Principles §4.4: "CloudKit sync errors observed from
    // NSPersistentCloudKitContainer.Event are logged at .error level and never
    // surfaced to the user as alerts. Sync is silent." No UI-facing error path
    // exists here by design.

    private func handle(_ event: NSPersistentCloudKitContainer.Event) {
        guard event.succeeded else {
            logger.error(
                "CloudKit sync event failed: \(event.error?.localizedDescription ?? "unknown error", privacy: .public)"
            )
            return
        }

        guard event.type == .import else { return }

        // Any state update triggered by an NSPersistentCloudKitContainer.Event is
        // wrapped in withAnimation(nil) — Engineering Principles §3.4. A bulk
        // remote import must not drive SwiftUI layout recalculations mid-animation.
        withAnimation(nil) {
            markActiveBoardsForRecalculation()
        }
    }

    // MARK: Flagging Active Boards
    //
    // Restricted to HabitBoard.activePredicate (archivedAt == nil) rather than all
    // boards. Archived boards are not currently displayed anywhere and have no
    // restore path yet (Phase 1 defined archive(in:) with no corresponding restore
    // method) — flagging them for a recalculation that will never be read or
    // observed would be speculative work for a feature that doesn't exist, which
    // this phase is explicitly scoped to avoid introducing.
    //
    // No rollback on save failure, unlike HabitBoard.archive(in:)'s rollback
    // pattern (Phase 1 finding C1). That asymmetry is intentional: a
    // needsStreakRecalculation flag left `true` after a failed save merely costs
    // one extra (harmless, idempotent) recalculation pass the next time this
    // board is displayed. Rolling it back risks the opposite, worse failure mode —
    // silently stale streak data with no flag left to trigger correction. Erring
    // toward "recalculate once more than necessary" is the safer asymmetry here.

    private func markActiveBoardsForRecalculation() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<HabitBoard>(predicate: HabitBoard.activePredicate)

        let boards: [HabitBoard]
        do {
            boards = try context.fetch(descriptor)
        } catch {
            logger.error(
                "Failed to fetch active boards for streak recalculation flagging: \(error.localizedDescription, privacy: .public)"
            )
            return
        }

        guard !boards.isEmpty else { return }

        for board in boards {
            board.needsStreakRecalculation = true
        }

        do {
            try context.save()
            NotificationCenter.default.post(name: .cloudKitImportDidComplete, object: nil)
        } catch {
            logger.error(
                "Failed to save needsStreakRecalculation flags after CloudKit import: \(error.localizedDescription, privacy: .public)"
            )
            // Intentionally not rolled back — see algorithm note above.
        }
    }
}

// MARK: - Notification Name

extension Notification.Name {
    /// Posted on the main actor after `CloudKitSyncCoordinator` successfully flags
    /// active boards for streak recalculation following a CloudKit import.
    ///
    /// Per Engineering Principles §3.4, views never observe
    /// `NSPersistentCloudKitContainer.Event` directly — they observe this notification
    /// instead, if they need to react to a completed import (e.g. to trigger an
    /// immediate `StreakCalculator` pass rather than waiting for next display).
    /// No current view observes this notification; it exists as the documented
    /// integration point for Phase 4 and later, per the established pattern.
    static let cloudKitImportDidComplete = Notification.Name("cloudKitImportDidComplete")
}
