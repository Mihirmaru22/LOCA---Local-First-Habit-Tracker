//
//  PlutoDataResetManager.swift
//  PLUTO
//
//  Utility to reset habit check-in logs and streaks while preserving
//  all habits, tasks, life benchmarks, and journal templates intact.
//

import SwiftData
import Foundation
import os.log

@MainActor
enum PlutoDataResetManager {

    private static let logger = Logger(subsystem: "com.mihirmaru.pluto.reset", category: "data")

    /// Resets check-in data once on launch to clean existing history while preserving habit boards
    static func resetCheckInDataIfNeeded(context: ModelContext) {
        let key = "has_reset_pluto_v35_checkins_clean_run"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        resetCheckInData(context: context)
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Resets all habit check-in records and streak counters.
    /// Preserves all HabitBoard entities, TodoItems, and life settings.
    static func resetCheckInData(context: ModelContext) {
        do {
            // 1. Delete all LogEntry (check-in) records
            let logDescriptor = FetchDescriptor<LogEntry>()
            if let logs = try? context.fetch(logDescriptor) {
                for log in logs {
                    context.delete(log)
                }
                logger.info("Deleted \(logs.count) LogEntry check-in records.")
            }

            // 2. Reset streak caches on all active HabitBoards
            let boardDescriptor = FetchDescriptor<HabitBoard>()
            if let boards = try? context.fetch(boardDescriptor) {
                for board in boards {
                    board.currentStreak = 0
                    board.longestStreak = 0
                    board.lastCheckedDate = nil
                    board.needsStreakRecalculation = false
                }
                logger.info("Reset streak counters on \(boards.count) HabitBoards.")
            }

            // 3. Save SwiftData context
            try context.save()
            logger.info("Successfully saved clean habit check-in state.")

            // 4. Clear local telemetry queue files
            PlutoTelemetryStorage.shared.clearAllQueuedFiles()

        } catch {
            logger.error("Failed to reset check-in data: \(error.localizedDescription)")
        }
    }
}
