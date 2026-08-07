//
//  GoalInference.swift
//  LOCA
//
//  Phase 2.2 — Goal inference from first week of quantitative tracking.
//
//  Calculates a sensible daily target from the first 7 days of logging,
//  rounded to user-friendly increments (e.g., 4.8 km avg → suggest 5 km).
//

import Foundation

struct GoalInference {

    /// Infers a sensible goal from the first week of logs.
    /// Returns nil if insufficient data (< 3 logs or < 2 days of history).
    static func inferFromFirstWeek(
        logs: [LogSnapshot],
        calendar: Calendar = .current
    ) -> Double? {
        guard logs.count >= 3 else { return nil }

        let sortedLogs = logs.sorted { $0.timestamp < $1.timestamp }
        let firstLog = sortedLogs.first!.timestamp
        let firstLogDay = calendar.startOfDay(for: firstLog)
        let windowEnd = calendar.date(byAdding: .day, value: 7, to: firstLogDay)!

        let logsInWindow = logs.filter { log in
            let logDay = calendar.startOfDay(for: log.timestamp)
            return logDay >= firstLogDay && logDay < windowEnd
        }

        let daysWithLogs = Set(logsInWindow.map { calendar.startOfDay(for: $0.timestamp) }).count
        guard daysWithLogs >= 2 else { return nil }

        let total = logsInWindow.reduce(0.0) { $0 + $1.value }
        let average = total / Double(daysWithLogs)

        return roundToFriendlyIncrement(average)
    }

    /// Rounds a value to a user-friendly increment.
    /// E.g., 4.8 → 5, 12.3 → 12, 0.3 → 0.5
    private static func roundToFriendlyIncrement(_ value: Double) -> Double {
        if value < 1.0 {
            // For fractional values (< 1), round to nearest 0.5
            return (value * 2).rounded() / 2
        } else if value < 10.0 {
            // For 1–10, round to nearest 1
            return value.rounded()
        } else {
            // For 10+, round to nearest 5
            return (value / 5).rounded() * 5
        }
    }

    /// Determines if goal inference should be offered.
    /// True if: habit is quantitative, has no goal, 7+ days old, 3+ logs, 2+ days with logs.
    static func shouldOffer(board: HabitBoard, logs: [LogSnapshot]) -> Bool {
        guard board.metric == .quantitative && board.targetValue == nil else { return false }

        let daysOld = Calendar.current.dateComponents([.day], from: board.createdAt, to: .now).day ?? 0
        guard daysOld >= 7 else { return false }

        return inferFromFirstWeek(logs: logs) != nil
    }
}
