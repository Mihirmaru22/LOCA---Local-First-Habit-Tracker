//
//  InterventionGenerator.swift
//  LOCA
//
//  Phase 5.3 — Delivery.
//
//  Generate one dismissible sentence. Right moment. Never during vulnerability.
//

import Foundation

/// Generates an intervention message from a relapse prediction.
/// One sentence. Actionable. Dismissible. Not preachy.
struct InterventionGenerator {

    /// Generate a one-sentence intervention from a relapse prediction.
    static func generateIntervention(from prediction: RelapsePrediction) -> String {
        switch prediction.trigger {
        case .streakAboutToBreak:
            return "\(prediction.habitName) streak ends tomorrow without a log—now's the time."

        case .consistencyCollapse:
            return "\(prediction.habitName) is slipping (only \(extractWeekDays(from: prediction.reasoning)) days this week)—get back on track?"

        case .timeGapIncreasing:
            return "Gap between logs widening—\(prediction.habitName) needs you today."

        case .patternShift:
            return "\(prediction.habitName): logging time shifted. Routine helps—log at your usual time."
        }
    }

    private static func extractWeekDays(from reasoning: String) -> String {
        // Extract "only X days" from reasoning
        if reasoning.contains("only 1 days") { return "1" }
        if reasoning.contains("only 2 days") { return "2" }
        if reasoning.contains("only 3 days") { return "3" }
        return "few"
    }
}

/// Determines when to deliver an intervention (Phase 5.3).
/// Not during grief/lapse. Right before critical moment.
struct InterventionScheduler {

    /// Compute optimal delivery time for this intervention.
    /// Returns a DateComponents for scheduling, or nil if timing is inappropriate.
    static func scheduleTime(for prediction: RelapsePrediction, board: HabitBoard) -> DateComponents? {
        // Never during vulnerability (grief/lapse > 3 days)
        let daysSinceLastLog = Calendar.current.dateComponents([.day], from: board.lastReflectionPromptTime ?? .now, to: .now).day ?? 0
        if daysSinceLastLog > 3 {
            return nil  // User is vulnerable; don't intervene
        }

        // Determine best time based on habit's usual logging time
        if let preferredTime = board.preferredReminderTime {
            // Deliver 30 minutes before their usual time
            let (hour, minute) = parseTime(preferredTime)
            let deliveryMinute = max(0, minute - 30)
            let deliveryHour = minute >= 30 ? hour : (hour - 1 + 24) % 24

            var components = DateComponents()
            components.hour = deliveryHour
            components.minute = deliveryMinute
            return components
        }

        // Default: morning (8 AM) — gives user whole day to act
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return components
    }

    private static func parseTime(_ timeString: String) -> (hour: Int, minute: Int) {
        let parts = timeString.split(separator: ":")
        let hour = Int(parts[0]) ?? 9
        let minute = Int(parts[1]) ?? 0
        return (hour, minute)
    }
}
