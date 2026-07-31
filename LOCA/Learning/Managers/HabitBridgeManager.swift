//
//  HabitBridgeManager.swift
//  LOCA
//
//  C3.3 — Read-only bridge from the habit engine to life Moments.
//  Converts LogEntry records into high-confidence SignalEvents tagged
//  source: .explicitLog. Habit logs are authoritative user facts;
//  uncertainty is near-zero (0.02) so the life model never re-asks
//  about something the user explicitly logged.
//

import Foundation
import SwiftData

@MainActor
final class HabitBridgeManager {

    private static let bridgeWindowDays = 90

    // MARK: - Public API

    /// Reads non-archived LogEntry records from the past 90 days and converts
    /// them to high-confidence SignalEvents. Already-bridged entries (matched
    /// by log_entry_id in metadata) are skipped to prevent duplication.
    func collectHabitLogs(modelContext: ModelContext) -> [SignalEvent] {
        let calendar = Calendar.current
        let now = Date()
        guard let windowStart = calendar.date(byAdding: .day, value: -Self.bridgeWindowDays, to: now) else {
            return []
        }

        let logDescriptor = FetchDescriptor<LogEntry>(
            predicate: #Predicate { entry in
                entry.timestamp >= windowStart && entry.archivedAt == nil
            }
        )
        guard let entries = try? modelContext.fetch(logDescriptor), !entries.isEmpty else {
            return []
        }

        // Collect IDs already present in the signal store to avoid re-insertion.
        let eventDescriptor = FetchDescriptor<SignalEvent>(
            predicate: #Predicate { event in
                event.timestamp >= windowStart
            }
        )
        let existingEvents = (try? modelContext.fetch(eventDescriptor)) ?? []
        let bridgedIDs = Set(existingEvents.compactMap { $0.metadata["log_entry_id"] })

        var signals: [SignalEvent] = []
        for entry in entries {
            let entryIDString = entry.id.uuidString
            guard !bridgedIDs.contains(entryIDString) else { continue }

            let board = entry.board
            let habitName = board?.name ?? "Unknown Habit"
            let effectiveTarget = board?.effectiveTarget ?? 1.0
            let completionRatio = min(entry.value / effectiveTarget, 1.0)
            let streak = board?.currentStreak ?? 0

            var metadata: [String: String] = [
                "log_entry_id": entryIDString,
                "habit_name": habitName,
                "log_value": String(format: "%.2f", entry.value),
                "streak": "\(streak)",
            ]
            if let boardID = board?.id {
                metadata["board_id"] = boardID.uuidString
            }
            if let note = entry.note, !note.isEmpty {
                metadata["note"] = note
            }
            if let dimension = board?.dimension, !dimension.isEmpty {
                metadata[dimension] = String(format: "%.2f", completionRatio)
            }

            signals.append(SignalEvent(
                timestamp: entry.timestamp,
                source: .explicitLog,
                value: completionRatio,
                uncertainty: 0.02,
                metadata: metadata
            ))
        }

        return signals
    }
}
