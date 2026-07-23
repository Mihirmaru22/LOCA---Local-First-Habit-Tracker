//
//  ReflectionPrompt.swift
//  LOCA
//
//  Phase 2.4 — Weekly reflection prompts.
//
//  Captures user sentiment about habit difficulty to inform future
//  adjustments. Throttled to once per week per habit.
//

import Foundation

struct ReflectionPrompt {

    enum Sentiment: String, Codable {
        case tooEasy = "easy"
        case aboutRight = "right"
        case tooHard = "hard"
        case unsure = "unsure"
    }

    /// Determines if reflection prompt should be shown.
    /// True if: 7+ days old, 3+ logs in past 7 days, never asked or 7+ days since last ask.
    static func shouldOffer(
        board: HabitBoard,
        logs: [LogSnapshot],
        calendar: Calendar = .current
    ) -> Bool {
        let daysOld = calendar.dateComponents([.day], from: board.createdAt, to: .now).day ?? 0
        guard daysOld >= 7 else { return false }

        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        let recentLogs = logs.filter { $0.timestamp >= sevenDaysAgo }
        guard recentLogs.count >= 3 else { return false }

        guard let lastReflectionTime = board.lastReflectionPromptTime else {
            // Never asked before
            return true
        }

        let daysSinceLastReflection = calendar.dateComponents([.day], from: lastReflectionTime, to: .now).day ?? 0
        return daysSinceLastReflection >= 7
    }
}
