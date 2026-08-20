//
//  RelapsePrediction.swift
//  LOCA
//
//  Phase 5.2 — Relapse risk detection.
//
//  Detects subtle shifts before a streak breaks or consistency collapses.
//  Grounds predictions in hard data (frequency, timing, gaps).
//

import Foundation

/// Type of trigger indicating potential relapse risk (Phase 5.2).
enum RelapseTrigger: String, Codable, CaseIterable, Sendable {
    case streakAboutToBreak = "streak_about_to_break"
    case consistencyCollapse = "consistency_collapse"
    case timeGapIncreasing = "time_gap_increasing"
    case patternShift = "pattern_shift"
}

/// A structured prediction of relapse risk for a specific habit (Phase 5.2).
struct RelapsePrediction: Identifiable, Sendable {
    let id: UUID
    let habitID: UUID
    let habitName: String
    let trigger: RelapseTrigger
    let confidence: PredictionConfidence
    let reasoning: String
    let detectedAt: Date

    init(
        id: UUID = UUID(),
        habitID: UUID,
        habitName: String,
        trigger: RelapseTrigger,
        confidence: PredictionConfidence,
        reasoning: String,
        detectedAt: Date = .now
    ) {
        self.id = id
        self.habitID = habitID
        self.habitName = habitName
        self.trigger = trigger
        self.confidence = confidence
        self.reasoning = reasoning
        self.detectedAt = detectedAt
    }
}

/// Detects relapse risk from historical logging behavior (Phase 5.2).
struct RelapseDetector {

    /// Analyze a habit's log history to detect whether a relapse is imminent.
    /// Returns `nil` if there is insufficient data or no risk detected.
    static func detectRelapse(
        board: HabitBoard,
        logs: [LogSnapshot],
        calendar: Calendar = .current
    ) -> RelapsePrediction? {
        let boardLogs = logs.filter { $0.boardID == board.id }
        guard boardLogs.count >= 5 else { return nil }

        let now = Date.now
        let today = calendar.startOfDay(for: now)

        // Filter logs by unique days
        let loggedDays = Set(boardLogs.map { calendar.startOfDay(for: $0.timestamp) })
        let loggedToday = loggedDays.contains(today)

        // 1. Check if an established streak is about to break
        if !loggedToday && board.currentStreak >= 2 {
            let daysSinceLast = boardLogs.compactMap {
                calendar.dateComponents([.day], from: calendar.startOfDay(for: $0.timestamp), to: today).day
            }.min() ?? 0

            // If last log was yesterday, user needs to log today to keep streak
            if daysSinceLast == 1 {
                let probability = board.currentStreak >= 5 ? 0.92 : 0.88
                let confidence = PredictionConfidence(probability: probability, dataPoints: boardLogs.count)
                return RelapsePrediction(
                    habitID: board.id,
                    habitName: board.name,
                    trigger: .streakAboutToBreak,
                    confidence: confidence,
                    reasoning: "\(board.name) streak ends tomorrow without a log"
                )
            }
        }

        // 2. Check for consistency collapse over the past 7 days vs previous baseline
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let pastWeekLogs = boardLogs.filter { $0.timestamp >= sevenDaysAgo }
        let pastWeekDays = Set(pastWeekLogs.map { calendar.startOfDay(for: $0.timestamp) }).count

        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        let pastMonthLogs = boardLogs.filter { $0.timestamp >= thirtyDaysAgo }
        let pastMonthDays = Set(pastMonthLogs.map { calendar.startOfDay(for: $0.timestamp) }).count

        // If historically frequent (e.g. 4+ days/week in monthly view) but past week dropped to 1-3 days
        let expectedWeeklyDays = Double(pastMonthDays) / 4.0
        if expectedWeeklyDays >= 3.5 && pastWeekDays <= 3 && boardLogs.count >= 10 {
            let probability = 0.90
            let confidence = PredictionConfidence(probability: probability, dataPoints: boardLogs.count)
            return RelapsePrediction(
                habitID: board.id,
                habitName: board.name,
                trigger: .consistencyCollapse,
                confidence: confidence,
                reasoning: "Logged only \(pastWeekDays) days this week compared to baseline \(Int(expectedWeeklyDays)) days"
            )
        }

        // 3. Check for widening time gaps between logs
        let sortedLogs = boardLogs.sorted(by: { $0.timestamp < $1.timestamp })
        if sortedLogs.count >= 5 {
            let mostRecentLog = sortedLogs.last!
            let daysSinceLastLog = calendar.dateComponents([.day], from: calendar.startOfDay(for: mostRecentLog.timestamp), to: today).day ?? 0

            // Compute average gap between consecutive days logged
            let sortedDays = Array(loggedDays).sorted()
            if sortedDays.count >= 3 {
                var totalGap = 0
                for i in 1..<sortedDays.count {
                    let gap = calendar.dateComponents([.day], from: sortedDays[i-1], to: sortedDays[i]).day ?? 1
                    totalGap += gap
                }
                let avgGap = Double(totalGap) / Double(sortedDays.count - 1)

                if Double(daysSinceLastLog) > avgGap * 2.0 && daysSinceLastLog >= 2 {
                    let probability = 0.89
                    let confidence = PredictionConfidence(probability: probability, dataPoints: boardLogs.count)
                    return RelapsePrediction(
                        habitID: board.id,
                        habitName: board.name,
                        trigger: .timeGapIncreasing,
                        confidence: confidence,
                        reasoning: "Gap between logs widening—last logged \(daysSinceLastLog) days ago"
                    )
                }
            }
        }

        // 4. Check for pattern shift (e.g. usual logging window missed)
        if !loggedToday, let preferredTime = board.preferredReminderTime {
            let currentHour = calendar.component(.hour, from: now)
            let parts = preferredTime.split(separator: ":")
            let preferredHour = Int(parts.first ?? "9") ?? 9

            // If current time is significantly past preferred reminder time (e.g. 4+ hours later)
            if currentHour >= preferredHour + 4 && boardLogs.count >= 10 {
                let probability = 0.85
                let confidence = PredictionConfidence(probability: probability, dataPoints: boardLogs.count)
                return RelapsePrediction(
                    habitID: board.id,
                    habitName: board.name,
                    trigger: .patternShift,
                    confidence: confidence,
                    reasoning: "Logging time shifted past usual time \(preferredTime)"
                )
            }
        }

        return nil
    }
}
