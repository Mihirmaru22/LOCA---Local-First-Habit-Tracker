//
//  ReflectionGenerator.swift
//  LOCA
//
//  Phase 4.1 — Reflection generation.
//
//  Analyzes habit progress and generates one honest sentence.
//  Grounded in data, never speculation. Seasonal and context-aware.
//  Returns nil if nothing's worth saying.
//

import Foundation

struct ReflectionGenerator {

    /// Generate a reflection for a habit based on its current state and history.
    ///
    /// Returns `nil` if there's nothing honest to say (Phase 4.3: guardrails).
    /// One sentence only. Seasonal. Tied to real progress metrics.
    static func generateForHabit(
        board: HabitBoard,
        logs: [LogSnapshot]
    ) -> ReflectionUnit? {
        // Filter recent logs (last 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        let recentLogs = logs.filter { $0.timestamp > thirtyDaysAgo }

        // Compute consistency metrics
        let weeklyStats = computeWeeklyStats(logs: recentLogs)
        let streakStatus = computeStreakStatus(board: board)
        let recoveryStatus = computeRecoveryStatus(logs: recentLogs)

        // Generate the one sentence, or return nil if nothing's worth saying
        if let sentence = generateSentence(
            habitName: board.name,
            streak: board.currentStreak,
            weeklyConsistency: weeklyStats.consistency,
            recentLogsCount: recentLogs.count,
            isRecovering: recoveryStatus.isRecovering,
            daysSinceLapse: recoveryStatus.daysSinceLapse
        ) {
            let contextType = determineContextType(
                streak: board.currentStreak,
                isRecovering: recoveryStatus.isRecovering,
                weeklyConsistency: weeklyStats.consistency
            )
            return ReflectionUnit(text: sentence, contextType: contextType)
        }

        return nil
    }

    // MARK: - Helpers

    private static func computeWeeklyStats(logs: [LogSnapshot]) -> (days: Int, consistency: Double) {
        guard !logs.isEmpty else { return (0, 0) }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let weeklyLogs = logs.filter { $0.timestamp > sevenDaysAgo }
        let uniqueDays = Set(weeklyLogs.map { Calendar.current.dateComponents([.year, .month, .day], from: $0.timestamp) })
        let consistency = Double(uniqueDays.count) / 7.0
        return (uniqueDays.count, consistency)
    }

    private static func computeStreakStatus(board: HabitBoard) -> (current: Int, longest: Int) {
        return (board.currentStreak, board.longestStreak)
    }

    private static func computeRecoveryStatus(logs: [LogSnapshot]) -> (isRecovering: Bool, daysSinceLapse: Int) {
        // A "lapse" is >2 days without logging
        guard !logs.isEmpty else { return (false, 0) }
        let sortedLogs = logs.sorted { $0.timestamp < $1.timestamp }
        guard let lastLog = sortedLogs.last else { return (false, 0) }

        let daysSinceLastLog = Calendar.current.dateComponents([.day], from: lastLog.timestamp, to: .now).day ?? 0
        // If last log was 2+ days ago, consider it a lapse, but check if we've logged recently
        if daysSinceLastLog > 2 {
            // Check if there's a log in the last day (recovery in progress)
            let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
            let recentLog = logs.first { $0.timestamp > oneDayAgo }
            if recentLog != nil {
                return (true, daysSinceLastLog)
            }
        }
        return (false, 0)
    }

    private static func generateSentence(
        habitName: String,
        streak: Int,
        weeklyConsistency: Double,
        recentLogsCount: Int,
        isRecovering: Bool,
        daysSinceLapse: Int
    ) -> String? {
        // Generate one honest sentence tied to real metrics
        // Return nil if nothing's worth saying

        // Recovery: "You logged again after 5 days—that's what matters."
        if isRecovering && daysSinceLapse > 2 {
            return "You logged \(habitName) again after \(daysSinceLapse) days—that's what matters."
        }

        // Strong streak: "7-day streak on \(habitName). Showing up matters."
        if streak >= 7 {
            return "\(streak)-day streak on \(habitName). Showing up matters."
        }

        // Consistency: "4 days this week—building the habit, not perfection."
        let weeklyDays = Int(weeklyConsistency * 7)
        if weeklyDays >= 4 && weeklyDays < 7 {
            return "\(weeklyDays) days this week on \(habitName)—building the habit, not perfection."
        }

        // Just starting: "You logged \(habitName) 3 times. The beginning matters."
        if recentLogsCount >= 3 && streak < 7 {
            return "You logged \(habitName) \(recentLogsCount) times. The beginning matters."
        }

        // Single log: Don't say anything yet (wait for a pattern)
        if recentLogsCount == 1 {
            return nil
        }

        // Default: nothing worth saying
        return nil
    }

    private static func determineContextType(
        streak: Int,
        isRecovering: Bool,
        weeklyConsistency: Double
    ) -> ReflectionUnit.ContextType {
        if isRecovering {
            return .recovery
        }
        if streak >= 7 {
            return .streak
        }
        if weeklyConsistency >= 0.5 {
            return .consistency
        }
        return .evening
    }
}
