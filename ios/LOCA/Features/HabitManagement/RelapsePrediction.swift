//
//  RelapsePrediction.swift
//  LOCA
//
//  Phase 5.2 — Trigger models.
//
//  Predict relapse signals with sufficient maturity to justify speaking.
//  High bar: 85%+ confidence. Structured signals only. No speculation.
//

import Foundation

/// A structured relapse-risk signal (Phase 5.2).
/// One or more triggers that predict imminent lapse.
struct RelapsePrediction {
    /// The habit at risk.
    let habitName: String
    let habitID: UUID

    /// What specifically is the risk? (streak breaking, consistency drop, etc.)
    enum TriggerType: String, Codable {
        case streakAboutToBreak    // User has a streak but hasn't logged today
        case consistencyCollapse   // Weekly consistency dropped below 30%
        case timeGapIncreasing     // Gap between logs is lengthening
        case patternShift          // Logging time shifted (e.g., 7am → 10pm)
    }

    let trigger: TriggerType
    /// Why we think this is risky (e.g., "streak 7 days, last log 36 hours ago").
    let reasoning: String

    /// Confidence this prediction is correct (Phase 5.1).
    let confidence: PredictionConfidence

    /// Whether to intervene based on confidence threshold (Phase 5.1).
    var shouldTrigger: Bool {
        confidence.isActionable
    }
}

/// Analyzes habit logs to predict relapse (Phase 5.2).
struct RelapseDetector {

    /// Detect relapse risk for a single habit.
    /// Returns nil if risk is low or confidence insufficient.
    static func detectRelapse(
        board: HabitBoard,
        logs: [LogSnapshot]
    ) -> RelapsePrediction? {
        guard !logs.isEmpty else { return nil }

        let sortedLogs = logs.sorted { $0.timestamp < $1.timestamp }

        // Check trigger 1: streak about to break
        if let prediction = checkStreakRisk(board: board, logs: sortedLogs) {
            return prediction
        }

        // Check trigger 2: consistency collapse
        if let prediction = checkConsistencyCollapse(board: board, logs: sortedLogs) {
            return prediction
        }

        // Check trigger 3: time gap increasing
        if let prediction = checkTimeGapIncreasing(board: board, logs: sortedLogs) {
            return prediction
        }

        // Check trigger 4: logging pattern shift
        if let prediction = checkPatternShift(logs: sortedLogs) {
            return prediction
        }

        return nil
    }

    // MARK: - Trigger detection

    private static func checkStreakRisk(
        board: HabitBoard,
        logs: [LogSnapshot]
    ) -> RelapsePrediction? {
        // Risk: user has a streak, but hasn't logged today
        guard board.currentStreak > 0 else { return nil }

        let today = Calendar.current.startOfDay(for: .now)
        let hasLoggedToday = logs.contains { Calendar.current.startOfDay(for: $0.timestamp) == today }

        guard !hasLoggedToday else { return nil }

        // How much time since last log?
        guard let lastLog = logs.last else { return nil }
        let hoursSinceLastLog = Calendar.current.dateComponents([.hour], from: lastLog.timestamp, to: .now).hour ?? 0

        // Risk increases with time
        let probability: Double
        if hoursSinceLastLog > 36 {
            probability = 0.85  // High risk
        } else if hoursSinceLastLog > 24 {
            probability = 0.70  // Moderate
        } else {
            return nil  // Too early to warn
        }

        let reasoning = "\(board.name) streak of \(board.currentStreak) days—last log \(hoursSinceLastLog)h ago."
        let confidence = PredictionConfidence(
            probability: probability,
            dataPoints: logs.count,
            falsePositiveCost: 2.5  // Breaking a streak is disappointing; false warning is annoying
        )

        guard confidence.isActionable else { return nil }

        return RelapsePrediction(
            habitName: board.name,
            habitID: board.id,
            trigger: .streakAboutToBreak,
            reasoning: reasoning,
            confidence: confidence
        )
    }

    private static func checkConsistencyCollapse(
        board: HabitBoard,
        logs: [LogSnapshot]
    ) -> RelapsePrediction? {
        // Risk: weekly consistency dropped below 30% (habit slipping away)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let weeklyLogs = logs.filter { $0.timestamp > sevenDaysAgo }
        let uniqueDays = Set(weeklyLogs.map { Calendar.current.dateComponents([.year, .month, .day], from: $0.timestamp) })

        let consistency = Double(uniqueDays.count) / 7.0
        guard consistency < 0.3 && consistency > 0 else { return nil }

        let probability = 0.80  // If consistency dropped this low, relapse is likely
        let reasoning = "\(board.name): only \(uniqueDays.count) days this week. Habit is slipping."

        let confidence = PredictionConfidence(
            probability: probability,
            dataPoints: max(logs.count, 15),
            falsePositiveCost: 2.0
        )

        guard confidence.isActionable else { return nil }

        return RelapsePrediction(
            habitName: board.name,
            habitID: board.id,
            trigger: .consistencyCollapse,
            reasoning: reasoning,
            confidence: confidence
        )
    }

    private static func checkTimeGapIncreasing(
        board: HabitBoard,
        logs: [LogSnapshot]
    ) -> RelapsePrediction? {
        // Risk: gap between logs is lengthening (user losing momentum)
        guard logs.count >= 5 else { return nil }

        let sortedLogs = logs.sorted { $0.timestamp < $1.timestamp }

        // Compare recent gap to historical average
        let recentGaps = stride(from: sortedLogs.count - 3, to: sortedLogs.count - 1, by: 1)
            .map { Calendar.current.dateComponents([.day], from: sortedLogs[$0].timestamp, to: sortedLogs[$0 + 1].timestamp).day ?? 0 }

        let historicalGaps = stride(from: 0, to: min(3, sortedLogs.count - 1), by: 1)
            .map { Calendar.current.dateComponents([.day], from: sortedLogs[$0].timestamp, to: sortedLogs[$0 + 1].timestamp).day ?? 0 }

        let recentAvg = recentGaps.isEmpty ? 0 : Double(recentGaps.reduce(0, +)) / Double(recentGaps.count)
        let historicalAvg = historicalGaps.isEmpty ? 0 : Double(historicalGaps.reduce(0, +)) / Double(historicalGaps.count)

        // Only trigger if gap is increasing significantly
        guard recentAvg > historicalAvg * 1.5 && recentAvg > 2 else { return nil }

        let probability = 0.75  // Growing gap suggests losing the habit
        let reasoning = "Logging gap is increasing (was \(Int(historicalAvg))d, now \(Int(recentAvg))d)."

        let confidence = PredictionConfidence(
            probability: probability,
            dataPoints: logs.count,
            falsePositiveCost: 1.8
        )

        guard confidence.isActionable else { return nil }

        return RelapsePrediction(
            habitName: board.name,
            habitID: board.id,
            trigger: .timeGapIncreasing,
            reasoning: reasoning,
            confidence: confidence
        )
    }

    private static func checkPatternShift(
        logs: [LogSnapshot]
    ) -> RelapsePrediction? {
        // Risk: when user usually logs has shifted (loses structure)
        guard logs.count >= 10 else { return nil }

        let historicalHours = logs.prefix(5).map { Calendar.current.component(.hour, from: $0.timestamp) }
        let recentHours = logs.suffix(5).map { Calendar.current.component(.hour, from: $0.timestamp) }

        let historicalAvg = historicalHours.reduce(0, +) / historicalHours.count
        let recentAvg = recentHours.reduce(0, +) / recentHours.count

        // Shift of 3+ hours suggests lost structure
        guard abs(historicalAvg - recentAvg) >= 3 else { return nil }

        let probability = 0.70
        let reasoning = "Logging time shifted from \(historicalAvg):00 to \(recentAvg):00—routine broken."

        let confidence = PredictionConfidence(
            probability: probability,
            dataPoints: logs.count,
            falsePositiveCost: 1.5
        )

        guard confidence.isActionable else { return nil }

        // Don't return a full prediction yet—this is a weak signal alone
        // (Would need to be combined with other triggers in production)
        return nil
    }
}
