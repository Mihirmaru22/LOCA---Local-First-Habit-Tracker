//
//  PlutoDataResetManager.swift
//  PLUTO
//
//  Executive Data Reset Engine for PLUTO Sovereign OS.
//  Provides granular and full factory data reset capabilities:
//  - Tasks (TodoItem)
//  - Work Strategic Goals
//  - Master Bucket List Dreams
//  - Journal Notes (JournalNote / HabitNote)
//  - Habit Logs & Check-ins (LogEntry / HabitBoard)
//  - Focus Sessions & Telemetry
//  - State & Summit expedition logs
//

import SwiftData
import Foundation
import os.log

extension Notification.Name {
    static let plutoDataDidReset = Notification.Name("plutoDataDidReset")
}

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

    /// Factory Reset: Wipes all user-generated tasks, strategic goals, journal notes,
    /// master bucket list items, habit logs, focus sessions, and expedition records to a clean slate.
    static func resetAllAppData(context: ModelContext) {
        do {
            // 1. Wipe all Tasks (TodoItem)
            let todoDescriptor = FetchDescriptor<TodoItem>()
            if let todos = try? context.fetch(todoDescriptor) {
                for todo in todos {
                    context.delete(todo)
                }
                logger.info("Deleted \(todos.count) TodoItem records.")
            }

            // 2. Wipe all Journal Notes
            let noteDescriptor = FetchDescriptor<JournalNote>()
            if let notes = try? context.fetch(noteDescriptor) {
                for note in notes {
                    context.delete(note)
                }
                logger.info("Deleted \(notes.count) JournalNote records.")
            }

            // 3. Wipe all Habit Check-in Logs
            let logDescriptor = FetchDescriptor<LogEntry>()
            if let logs = try? context.fetch(logDescriptor) {
                for log in logs {
                    context.delete(log)
                }
                logger.info("Deleted \(logs.count) LogEntry records.")
            }

            // 4. Wipe all Habit Boards
            let boardDescriptor = FetchDescriptor<HabitBoard>()
            if let boards = try? context.fetch(boardDescriptor) {
                for board in boards {
                    context.delete(board)
                }
                logger.info("Deleted \(boards.count) HabitBoard records.")
            }

            // 5. Reset Travel Records (Wishlist state, empty visited cities)
            let travelDescriptor = FetchDescriptor<TravelRecord>()
            if let travels = try? context.fetch(travelDescriptor) {
                for t in travels {
                    t.status = .wishlist
                    t.dateVisited = nil
                    t.visitedCities = []
                }
                logger.info("Reset \(travels.count) TravelRecord entries to unvisited wishlist.")
            }

            // 6. Reset Trek & Mountain Records (Wishlist state, rating 0, no conquered date)
            let trekDescriptor = FetchDescriptor<TrekRecord>()
            if let treks = try? context.fetch(trekDescriptor) {
                for t in treks {
                    t.status = .wishlist
                    t.dateConquered = nil
                    t.rating = nil
                }
                logger.info("Reset \(treks.count) TrekRecord entries to unconquered wishlist.")
            }

            // 7. Clear Work Goals & Master Bucket List in UserDefaults
            UserDefaults.standard.removeObject(forKey: "pluto_work_goals_v1")
            UserDefaults.standard.removeObject(forKey: "pluto_bucket_items_v1")
            UserDefaults.standard.removeObject(forKey: "has_reset_pluto_v35_checkins_clean_run")

            // 8. Clear Telemetry Storage
            PlutoTelemetryStorage.shared.clearAllQueuedFiles()

            // 9. Save SwiftData ModelContext
            try context.save()
            logger.info("Successfully completed full factory reset of Pluto app data.")

            // 10. Broadcast Notification to refresh all active views
            NotificationCenter.default.post(name: .plutoDataDidReset, object: nil)

        } catch {
            logger.error("Failed to reset all app data: \(error.localizedDescription)")
        }
    }
}
