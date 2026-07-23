//
//  CheckInWriter.swift
//  LOCA
//
//  Centralised persistence service for all check-in mutations.
//  Every call site routes through here — one write path, one error contract,
//  one streak-routing decision, one widget reload trigger.
//

import SwiftData
import Foundation

// MARK: - Notification Names

extension Notification.Name {
    /// Posted after any non-today insert, delete, or update so the streak
    /// recalculation pipeline can repair the cached streak values (C-2).
    /// Defined here because CheckInWriter is the sole posting site and is
    /// compiled into both the main app and the widget extension.
    static let streakRecalculationRequested = Notification.Name("streakRecalculationRequested")
}

// MARK: - CheckInWriter

/// Coordinates all check-in mutations: insert, delete, update, and binary toggle.
///
/// ## Contract
/// - All methods are `@MainActor` — they operate on `ModelContext.mainContext` objects.
/// - On success the context has already been saved and a widget reload scheduled.
/// - On failure the context is rolled back and the error is re-thrown; call sites own
///   the user-facing error alert.
/// - No haptics, animations, or dismiss logic — those belong at the call site.
///
/// ## Streak Routing
/// - Insert today   → `board.updateStreak(using: .current)` (incremental fast path, C-2)
/// - Insert non-today, delete, or update → `board.needsStreakRecalculation = true` +
///   `.streakRecalculationRequested` notification posted after a successful save
@MainActor
enum CheckInWriter {

    // MARK: - Insert

    /// Inserts a new `LogEntry` for `board` and saves.
    static func insert(
        value: Double,
        timestamp: Date = .now,
        note: String? = nil,
        board: HabitBoard,
        context: ModelContext
    ) throws {
        let entry = LogEntry(
            timestamp: timestamp,
            value: value,
            note: note,
            boardID: board.id,
            board: board
        )
        context.insert(entry)
        let isToday = Calendar.current.isDateInToday(timestamp)
        if isToday {
            board.updateStreak(using: .current)
        } else {
            board.needsStreakRecalculation = true
        }
        try saveAndReload(context: context)
        if !isToday {
            NotificationCenter.default.post(name: .streakRecalculationRequested, object: nil)
        }
    }

    // MARK: - Delete

    /// Deletes `entry` and saves. Always flags for full streak recalculation.
    static func delete(
        _ entry: LogEntry,
        board: HabitBoard,
        context: ModelContext
    ) throws {
        context.delete(entry)
        board.needsStreakRecalculation = true
        try saveAndReload(context: context)
        NotificationCenter.default.post(name: .streakRecalculationRequested, object: nil)
    }

    // MARK: - Update (edit existing entry)

    /// Mutates `entry`'s fields in-place and saves. Always flags for full streak recalculation.
    ///
    /// On failure the context is rolled back (in `saveAndReload`) and the entry's
    /// in-memory state is restored defensively, then the error is re-thrown.
    static func update(
        entry: LogEntry,
        timestamp: Date,
        value: Double,
        note: String?,
        board: HabitBoard,
        context: ModelContext
    ) throws {
        let oldTS   = entry.timestamp
        let oldVal  = entry.value
        let oldNote = entry.note
        entry.timestamp = timestamp
        entry.value     = value
        entry.note      = note
        board.needsStreakRecalculation = true
        do {
            try saveAndReload(context: context)
            NotificationCenter.default.post(name: .streakRecalculationRequested, object: nil)
        } catch {
            // saveAndReload already called rollback(); restore in-memory state defensively.
            entry.timestamp = oldTS
            entry.value     = oldVal
            entry.note      = oldNote
            throw error
        }
    }

    // MARK: - Toggle Binary (idempotent)

    /// For a binary habit: inserts today's entry if none exists; deletes it otherwise.
    ///
    /// - Returns: `true` if the habit is now checked in, `false` if the entry was removed.
    @discardableResult
    static func toggleBinary(board: HabitBoard, context: ModelContext) throws -> Bool {
        let todayLogs = (board.logs ?? []).filter { Calendar.current.isDateInToday($0.timestamp) }
        if let existing = todayLogs.first {
            try delete(existing, board: board, context: context)
            return false
        } else {
            try insert(value: 1.0, board: board, context: context)
            return true
        }
    }

    // MARK: - Private

    private static func saveAndReload(context: ModelContext) throws {
        do {
            try context.save()
            WidgetRefreshCoordinator.shared.scheduleReload()
        } catch {
            context.rollback()
            throw error
        }
    }
}
