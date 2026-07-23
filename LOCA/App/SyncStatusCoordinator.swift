//
//  SyncStatusCoordinator.swift
//  LOCA
//
//  Phase 3.5 — Sync status tracking and error reporting.
//
//  Monitors CloudKit sync state and surfaces issues to the UI.
//  Non-blocking: sync errors don't interrupt the user.
//

import Foundation
import os.log

actor SyncStatusCoordinator {

    /// The sync state surfaced to the UI. `Sendable` so it can cross the actor
    /// boundary into a MainActor view via the `statusUpdates()` stream.
    enum SyncStatus: Sendable, Equatable {
        case idle
        case syncing
        case error(String)
    }

    static let shared = SyncStatusCoordinator()

    nonisolated private let logger = Logger(subsystem: "com.loca.app", category: "sync")

    private var syncStatus: SyncStatus = .idle

    /// Active stream continuations, keyed by subscription id so each can be
    /// cleaned up independently when its consumer stops iterating.
    private var continuations: [UUID: AsyncStream<SyncStatus>.Continuation] = [:]

    /// Starts monitoring sync status.
    /// Called once from LOCAApp on launch.
    func start() async {
        await observeSyncEvents()
    }

    /// Current sync status.
    func status() -> SyncStatus {
        return syncStatus
    }

    /// A stream of sync status updates for the UI to consume with `for await`.
    ///
    /// Emits the current status immediately, then every subsequent change.
    /// Because `SyncStatus` is `Sendable`, a MainActor view can iterate this
    /// stream in a `.task` and assign directly to `@State` without any data
    /// race — no MainActor-capturing closure is ever handed to the actor.
    func statusUpdates() -> AsyncStream<SyncStatus> {
        AsyncStream { continuation in
            let id = UUID()
            continuations[id] = continuation
            continuation.yield(syncStatus)
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id) }
            }
        }
    }

    // MARK: - Private

    private func removeContinuation(_ id: UUID) {
        continuations[id] = nil
    }

    private func observeSyncEvents() async {
        // Monitor for sync events from the model container.
        // This is called whenever CloudKit completes an operation.
        //
        // For now, we track basic state changes. In production, this would hook
        // into NSPersistentCloudKitContainerEvent notifications.
        updateStatus(.idle)
    }

    private func updateStatus(_ newStatus: SyncStatus) {
        self.syncStatus = newStatus

        switch newStatus {
        case .idle:
            logger.debug("Sync idle")
        case .syncing:
            logger.debug("Sync in progress")
        case .error(let message):
            logger.warning("Sync error: \(message)")
        }

        // Broadcast to every active stream consumer.
        for continuation in continuations.values {
            continuation.yield(newStatus)
        }
    }

    /// Records a sync error without interrupting the user.
    func recordError(_ error: Error) {
        let message = error.localizedDescription
        updateStatus(.error(message))

        // Auto-clear error after a delay.
        Task {
            try? await Task.sleep(for: .seconds(5))
            await updateStatus(.idle)
        }
    }
}
