//
//  SyncStatusCoordinator.swift
//  LOCA
//
//  Phase 3.5 — Sync status tracking and error reporting.
//
//  Monitors CloudKit sync state and surfaces issues to the UI.
//  Non-blocking: sync errors don't interrupt the user.
//

import SwiftData
import Foundation
import os.log

actor SyncStatusCoordinator {

    enum SyncStatus {
        case idle
        case syncing
        case error(String)
    }

    nonisolated private let logger = Logger(subsystem: "com.loca.app", category: "sync")

    private var syncStatus: SyncStatus = .idle
    private var statusCallbacks: [(SyncStatus) -> Void] = []

    /// Starts monitoring sync status.
    /// Called once from LOCAApp on launch.
    func start() async {
        await observeSyncEvents()
    }

    /// Register a callback to receive sync status updates.
    func onStatusChanged(_ callback: @escaping (SyncStatus) -> Void) {
        statusCallbacks.append(callback)
    }

    /// Get current sync status.
    func status() -> SyncStatus {
        return syncStatus
    }

    // MARK: - Private

    private func observeSyncEvents() async {
        // Monitor for sync events from the model container
        // This is called whenever CloudKit completes an operation

        // For now, we track basic state changes
        // In production, this would hook into NSPersistentCloudKitContainerEvent notifications
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

        // Notify all callbacks
        for callback in statusCallbacks {
            callback(newStatus)
        }
    }

    /// Records a sync error without interrupting the user.
    func recordError(_ error: Error) {
        let message = error.localizedDescription
        updateStatus(.error(message))

        // Auto-clear error after a delay
        Task {
            try? await Task.sleep(for: .seconds(5))
            await updateStatus(.idle)
        }
    }
}

// MARK: - Shared Instance

let syncStatusCoordinator = SyncStatusCoordinator()
