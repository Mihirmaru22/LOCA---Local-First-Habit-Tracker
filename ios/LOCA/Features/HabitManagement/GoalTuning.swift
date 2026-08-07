//
//  GoalTuning.swift
//  LOCA
//
//  Phase 3.2 — Intelligent goal adjustment based on multiple signals.
//
//  Tunes habit goals based on: user difficulty feedback from reflections,
//  consistency metrics (% of target met), and logging patterns. Prevents
//  goal churn by requiring consistent feedback before adjusting.
//

import Foundation

struct GoalTuning {

    /// Analyzes signals to determine if a goal should be adjusted.
    /// Returns suggested new goal, or nil if current goal is well-calibrated.
    static func suggestAdjustment(
        board: HabitBoard,
        logs: [LogSnapshot],
        recentReflections: [String],  // Recent sentiment values: "easy", "right", "hard", "unsure"
        calendar: Calendar = .current
    ) -> Double? {
        guard board.metric == .quantitative && board.targetValue != nil else { return nil }
        let currentGoal = board.targetValue!

        // Signal 1: Consistency
        let consistency = computeConsistency(logs: logs, goal: currentGoal)

        // Signal 2: Difficulty feedback (weighted toward recent)
        let difficultySignal = computeDifficultySignal(recentReflections: recentReflections)

        // Combine signals
        let shouldIncrease = (difficultySignal > 0.2 && consistency > 0.70) || (consistency > 0.85)
        let shouldDecrease = (difficultySignal < -0.2 && consistency < 0.60) || (consistency < 0.40)

        guard shouldIncrease || shouldDecrease else { return nil }

        // Calculate adjustment (10–20% change)
        let adjustmentPercent = shouldIncrease ? 1.15 : 0.85
        let suggested = (currentGoal * adjustmentPercent).rounded(toPlaces: 1)

        // Prevent thrashing: require at least 10% change
        guard abs(suggested - currentGoal) / currentGoal > 0.10 else { return nil }

        return suggested
    }

    // MARK: - Private Helpers

    /// Consistency = (average % of goal met per day with logs) × (% of days with logs)
    /// Range: 0.0–1.0
    private static func computeConsistency(
        logs: [LogSnapshot],
        goal: Double,
        calendar: Calendar = .current
    ) -> Double {
        guard !logs.isEmpty else { return 0.0 }

        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        let recentLogs = logs.filter { $0.timestamp >= sevenDaysAgo }
        guard !recentLogs.isEmpty else { return 0.0 }

        // Days with at least one log
        let daysWithLogs = Set(recentLogs.map { calendar.startOfDay(for: $0.timestamp) }).count

        // Accuracy: how close each day gets to the goal
        let dayTotals = Dictionary(grouping: recentLogs, by: { calendar.startOfDay(for: $0.timestamp) })
            .mapValues { $0.reduce(0.0) { $0 + $1.value } }

        let accuracyPerDay = dayTotals.map { min(1.0, $0.value / goal) }
        let averageAccuracy = accuracyPerDay.isEmpty ? 0.0 : accuracyPerDay.reduce(0.0, +) / Double(accuracyPerDay.count)

        // Final consistency = (accuracy) × (coverage: days with logs / total days in window)
        let coverage = Double(daysWithLogs) / 7.0
        return averageAccuracy * coverage
    }

    /// Difficulty signal: weighted average of recent feedback.
    /// "easy" = +1, "right" = 0, "hard" = -1, "unsure" = 0
    /// Weights recent feedback more heavily.
    private static func computeDifficultySignal(recentReflections: [String]) -> Double {
        guard !recentReflections.isEmpty else { return 0.0 }

        var weightedSum = 0.0
        var weightTotal = 0.0

        for (index, reflection) in recentReflections.reversed().enumerated() {
            let weight = pow(2.0, Double(index))  // Recent feedback exponentially weighted
            let value: Double
            switch reflection {
            case "easy": value = 1.0
            case "hard": value = -1.0
            default: value = 0.0
            }
            weightedSum += value * weight
            weightTotal += weight
        }

        return weightTotal > 0 ? weightedSum / weightTotal : 0.0
    }
}

// MARK: - Double Extension

extension Double {
    /// Rounds to a specific number of decimal places.
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
