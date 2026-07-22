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

    // MARK: Debounce State (T13)
    //
    // `NSPersistentCloudKitContainer.Event` does not expose which entity types or
    // object IDs were imported — only that an import occurred for a given store.
    // "Scoping" to implicated boards is therefore not possible from the event itself;
    // the optimisation available here is coalescing bursts of events into one pass.
    //
    // During first-install bulk sync, CloudKit fires many import events in rapid
    // succession. Without coalescing, each event independently fetches all boards,
    // marks them dirty, saves, and triggers StreakMaintenanceCoordinator — O(N×M)
    // work for N events and M boards. The debounce collapses any burst into a single
    // flagging pass that runs once the import stream quiets for `flagDebounceInterval`.
    //
    // The task is stored on `self` (main actor) and cancelled/replaced on each
    // incoming event — only the last one survives the idle window.
    private var pendingFlagTask: Task<Void, Never>? = nil
    private static let flagDebounceInterval: Duration = .seconds(1.5)

    private func handle(_ event: NSPersistentCloudKitContainer.Event) {
        guard event.succeeded else {
            logger.error(
                "CloudKit sync event failed: \(event.error?.localizedDescription ?? "unknown error", privacy: .public)"
            )
            return
        }

        guard event.type == .import else { return }

        // Cancel any pending pass from a previous event in this burst and start
        // a fresh one. The pass runs only after flagDebounceInterval of quiet.
        pendingFlagTask?.cancel()
        pendingFlagTask = Task { [weak self] in
            do {
                try await Task.sleep(for: Self.flagDebounceInterval)
            } catch {
                return  // Cancelled by a later event in the same burst.
            }
            // Any state update triggered by a CloudKit import is wrapped in
            // withAnimation(nil) — Engineering Principles §3.4.
            withAnimation(nil) {
                self?.markActiveBoardsForRecalculation()
            }
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
    // Further scoped to boards where needsStreakRecalculation == false (T13): if a
    // prior call in the same session already flagged all boards and StreakMaintenance-
    // Coordinator has not yet cleared them, there is nothing to write. Skipping the
    // save in that case avoids a redundant round-trip to the SQLite store.
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

        let activeBoards: [HabitBoard]
        do {
            activeBoards = try context.fetch(descriptor)
        } catch {
            logger.error(
                "Failed to fetch active boards for streak recalculation flagging: \(error.localizedDescription, privacy: .public)"
            )
            return
        }

        guard !activeBoards.isEmpty else { return }

        // Only write to boards not already carrying the flag. A board already marked
        // dirty from a prior import event in this session needs no second write.
        let unflagged = activeBoards.filter { !$0.needsStreakRecalculation }
        if !unflagged.isEmpty {
            for board in unflagged {
                board.needsStreakRecalculation = true
            }
            do {
                try context.save()
            } catch {
                logger.error(
                    "Failed to save needsStreakRecalculation flags after CloudKit import: \(error.localizedDescription, privacy: .public)"
                )
                // Intentionally not rolled back — see algorithm note above.
            }
        }

        // Notify regardless of whether any new flags were written: some boards may
        // already be dirty (flagged by a prior event but not yet recalculated), and
        // StreakMaintenanceCoordinator uses the flag set as its own work list.
        NotificationCenter.default.post(name: .cloudKitImportDidComplete, object: nil)
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
    ///
    /// `StreakMaintenanceCoordinator` (below) is the first consumer: it runs a full
    /// `StreakCalculator` pass over flagged boards whenever this fires.
    static let cloudKitImportDidComplete = Notification.Name("cloudKitImportDidComplete")

    /// Posted on the main actor by a mutation site (an edit, a delete, or a backdated/
    /// future insert) after it sets `needsStreakRecalculation = true` and saves. Requests
    /// the same full `StreakCalculator` pass the CloudKit path uses, so a local mutation
    /// the increment-only `HabitBoard.updateStreak(using:)` fast path cannot service is
    /// reflected immediately rather than only after the next import (C-2).
    ///
    /// Observed by `StreakMaintenanceCoordinator` alongside `cloudKitImportDidComplete`;
    /// both triggers simply re-run the recalculation pass, whose work list is the set of
    /// flagged boards.
    static let streakRecalculationRequested = Notification.Name("streakRecalculationRequested")
}

// MARK: - StreakMaintenanceCoordinator

/// Consumes `HabitBoard.needsStreakRecalculation` and repairs the cached streak
/// properties from the full log history via `StreakCalculator`.
///
/// ## Why This Type Exists (closes review finding C-1)
///
/// `CloudKitSyncCoordinator` *sets* `needsStreakRecalculation = true` after an import,
/// but nothing ever *acted* on that flag — `StreakCalculator.calculate(…)` had no call
/// site, `resetStreakCache()` was never invoked, and the flag was never cleared. The
/// entire last-write-wins streak-repair safety net (design risk "H1") was therefore
/// inert at runtime: after the first import a board's flag stayed `true` forever and its
/// merged history was never reflected in the scalar streak cache.
///
/// This type is the missing consumer. It closes the loop:
///
/// ```
/// CloudKitSyncCoordinator: import → flag boards → post cloudKitImportDidComplete
/// StreakMaintenanceCoordinator: (launch | notification) → recalc flagged boards → clear flag
/// ```
///
/// ## Separation of Concerns
///
/// Kept distinct from `CloudKitSyncCoordinator`, whose documented contract is to *flag*
/// boards and explicitly *not* perform recalculation. That responsibility lives here.
/// The two are siblings in this file because they are the two halves of one pipeline —
/// the producer and the consumer of `needsStreakRecalculation`.
///
/// ## Lifecycle
///
/// Instantiated once in `LOCAApp.init()` alongside the shared `ModelContainer` and started
/// via a `.task` on the root view, mirroring `CloudKitSyncCoordinator`. Structured
/// concurrency only — no manual thread or queue management (Engineering Principles §3.1).
///
/// ## Crash Safety
///
/// The flag is cleared to `false` only in the same `context.save()` that persists the
/// recalculated values. A crash before that save leaves the flag `true` in the store, so
/// the launch pass retries the recalculation on next launch rather than displaying stale
/// or zeroed streaks — exactly the guarantee documented on `HabitBoard.needsStreakRecalculation`.
@MainActor
final class StreakMaintenanceCoordinator {

    private let container: ModelContainer
    private let logger = Logger(subsystem: "com.mihirmaru.loca", category: "StreakMaintenance")

    // Same idempotency rationale as CloudKitSyncCoordinator: `start()` is driven from a
    // per-window `.task`, and macOS "New Window" can fire it more than once against this
    // single shared instance. The guard makes a second call a no-op.
    private var isObserving = false

    /// - Parameter container: The shared `ModelContainer` from `LOCAApp.init()`. This type
    ///   never constructs its own container; it reads and writes the same `mainContext`
    ///   that the views and `CloudKitSyncCoordinator` use, so flags set there are visible here.
    init(container: ModelContainer) {
        self.container = container
    }

    // MARK: - Observation Loop

    /// Runs an initial recalculation pass for any boards flagged in a prior session, then
    /// observes `cloudKitImportDidComplete` and re-runs a pass on each notification.
    ///
    /// Idempotent — a second concurrent call while already observing is a no-op. Runs until
    /// the calling `Task` is cancelled (driven by a SwiftUI `.task` on a long-lived view).
    func start() async {
        guard !isObserving else { return }
        isObserving = true

        // Launch pass: repair boards flagged in a prior session — including one where a
        // previous recalculation was interrupted before its save (flag still `true`).
        await recalculateFlaggedBoards()

        // Subsequent passes are driven by two triggers, observed concurrently:
        //   • cloudKitImportDidComplete   — a remote import may have merged new logs (C-1)
        //   • streakRecalculationRequested — a local edit / delete / backdated insert
        //     flagged a board and needs the same full recalculation (C-2)
        // Both simply re-run recalculateFlaggedBoards(); the flag set is the work list.
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in await self?.observe(.cloudKitImportDidComplete) }
            group.addTask { [weak self] in await self?.observe(.streakRecalculationRequested) }
        }
    }

    /// Observes one notification stream, running a recalculation pass on each post, until
    /// the surrounding task is cancelled. Two instances run concurrently (one per trigger).
    private func observe(_ name: Notification.Name) async {
        let notifications = NotificationCenter.default.notifications(named: name)
        for await _ in notifications {
            guard !Task.isCancelled else { break }
            await recalculateFlaggedBoards()
        }
    }

    // MARK: - Recalculation Pass

    /// Fetches every board with `needsStreakRecalculation == true`, recomputes its streak
    /// metrics from the full log history off the main actor, writes the results back, and
    /// clears the flag — all in a single save.
    ///
    /// Snapshots are taken on the main actor (`LogSnapshot.init(from:)` is `@MainActor`);
    /// only the `Sendable` snapshots cross into `StreakCalculator.calculate`, which runs on
    /// the cooperative thread pool. The write-back and save occur back on the main actor.
    func recalculateFlaggedBoards() async {
        let context = container.mainContext

        let boards: [HabitBoard]
        do {
            boards = try context.fetch(
                FetchDescriptor<HabitBoard>(
                    predicate: #Predicate { $0.needsStreakRecalculation }
                )
            )
        } catch {
            logger.error(
                "Failed to fetch boards needing streak recalculation: \(error.localizedDescription, privacy: .public)"
            )
            return
        }

        guard !boards.isEmpty else { return }

        for board in boards {
            // Snapshot on the main actor before suspending; the Sendable snapshots are
            // then safe to hand to the off-actor calculator.
            let snapshots = (board.logs ?? []).map(LogSnapshot.init(from:))
            let target    = board.effectiveTarget

            let result = await StreakCalculator.calculate(snapshots: snapshots, target: target)

            // Back on the main actor: apply the authoritative values and clear the flag.
            board.currentStreak       = result.currentStreak
            board.longestStreak       = result.longestStreak
            board.lastCheckedDate     = result.lastCompletedDate
            board.needsStreakRecalculation = false
        }

        do {
            try context.save()
            logger.debug("Recalculated streaks for \(boards.count, privacy: .public) flagged board(s).")
        } catch {
            logger.error(
                "Failed to save recalculated streaks: \(error.localizedDescription, privacy: .public)"
            )
            // Not rolled back: the flags remain `true` in the persistent store, so the
            // launch pass retries on next launch rather than leaving streaks silently
            // stale. This mirrors CloudKitSyncCoordinator's "recalculate once more than
            // necessary" asymmetry.
        }
    }
}
