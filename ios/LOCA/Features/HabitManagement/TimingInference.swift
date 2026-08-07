//
//  TimingInference.swift
//  LOCA
//
//  Phase 2.3 — Timing inference from logging patterns.
//
//  Analyzes when users typically log to suggest optimal reminder times.
//  Finds the most common hour and nearest half-hour increment.
//

import Foundation

struct TimingInference {

    /// Infers the most common logging time from habit logs.
    /// Returns (hour, minute) as (0-23, 0-30) representing the suggested time.
    /// Returns nil if insufficient data (< 5 logs or < 7 days of history).
    static func inferLoggingTime(
        logs: [LogSnapshot],
        calendar: Calendar = .current
    ) -> (hour: Int, minute: Int)? {
        guard logs.count >= 5 else { return nil }

        let daysOfHistory = Set(logs.map { calendar.startOfDay(for: $0.timestamp) }).count
        guard daysOfHistory >= 7 else { return nil }

        // Count logs by hour of day
        var hourCounts: [Int: Int] = [:]
        for log in logs {
            let hour = calendar.component(.hour, from: log.timestamp)
            hourCounts[hour, default: 0] += 1
        }

        // Find most common hour
        guard let mostCommonHour = hourCounts.max(by: { $0.value < $1.value })?.key else {
            return nil
        }

        // Round minute to nearest half-hour (0 or 30)
        let minute = Int.random(in: 0..<60) < 30 ? 0 : 30

        return (mostCommonHour, minute)
    }

    /// Determines if timing suggestion should be offered.
    /// True if: 7+ days old, 5+ logs, no reminder time set yet.
    static func shouldOffer(board: HabitBoard, logs: [LogSnapshot]) -> Bool {
        guard board.preferredReminderTime == nil else { return false }

        let daysOld = Calendar.current.dateComponents([.day], from: board.createdAt, to: .now).day ?? 0
        guard daysOld >= 7 else { return false }

        return inferLoggingTime(logs: logs) != nil
    }
}
