//
//  InterventionDelivery.swift
//  LOCA
//
//  Phase 5.3 & 5.5 — Intervention delivery and tracking.
//
//  Delivers high-confidence relapse warnings as push.
//  Tracks whether user acted on it (logged) or dismissed.
//

import UserNotifications
import Foundation
import os.log

actor InterventionDelivery {

    static let shared = InterventionDelivery()

    nonisolated private let logger = Logger(subsystem: "com.loca.app", category: "intervention")

    /// Recent interventions sent (for tracking effectiveness).
    private var recentInterventions: [SentIntervention] = []

    struct SentIntervention: Identifiable {
        let id: UUID = UUID()
        let habitID: UUID
        let text: String
        let sentAt: Date
        var userActed: Bool = false  // Did user log after intervention?
        var wasDismissed: Bool = false
    }

    /// Deliver an intervention as a push notification.
    /// High bar: only sends if prediction confidence is actionable.
    func deliverIntervention(_ prediction: RelapsePrediction) async {
        // Double-check confidence threshold
        guard prediction.confidence.isActionable else {
            logger.debug("Intervention suppressed: confidence below threshold")
            return
        }

        let center = UNUserNotificationCenter.current()
        let text = InterventionGenerator.generateIntervention(from: prediction)

        // Remove any existing intervention (only one active at a time)
        center.removePendingNotificationRequests(withIdentifiers: ["intervention"])

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Quick check-in"  // Non-alarming title
        content.body = text
        content.sound = .default
        content.categoryIdentifier = "intervention"  // For custom actions (dismiss, etc.)

        // Attach ID for tracking
        content.userInfo = ["interventionID": prediction.habitID.uuidString]

        // Schedule for optimal time
        guard let timeComponents = InterventionScheduler.scheduleTime(for: prediction, board: HabitBoard(name: prediction.habitName, metricType: 0, colorIndex: 0)) else {
            logger.debug("Intervention suppressed: inappropriate timing (vulnerability period)")
            return
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: timeComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "intervention",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            let intervention = SentIntervention(habitID: prediction.habitID, text: text, sentAt: .now)
            recentInterventions.append(intervention)
            if recentInterventions.count > 50 {
                recentInterventions.removeFirst()
            }
            logger.info("Intervention delivered: \(prediction.trigger.rawValue)")
        } catch {
            logger.warning("Failed to deliver intervention: \(error.localizedDescription)")
        }
    }

    /// Record that user acted on the intervention (logged the habit).
    func markActedUpon(habitID: UUID) async {
        if let index = recentInterventions.firstIndex(where: { $0.habitID == habitID }) {
            recentInterventions[index].userActed = true
            logger.debug("User acted on intervention")
        }
    }

    /// Record that user dismissed the intervention.
    func markDismissed(habitID: UUID) async {
        if let index = recentInterventions.firstIndex(where: { $0.habitID == habitID }) {
            recentInterventions[index].wasDismissed = true
        }
    }

    /// Get effectiveness metrics (Phase 5.5: exit gate).
    /// Returns (sent, acted, dismissed, effectiveness rate).
    func getEffectiveness(lastN: Int = 20) -> (sent: Int, acted: Int, dismissed: Int, effectiveRate: Double) {
        let recent = Array(recentInterventions.suffix(lastN))
        let acted = recent.filter { $0.userActed }.count
        let dismissed = recent.filter { $0.wasDismissed }.count
        let rate = recent.isEmpty ? 0 : Double(acted) / Double(recent.count)
        return (recent.count, acted, dismissed, rate)
    }

    /// Check if interventions are effective enough to continue.
    /// Exit gate: if trusted less than 50% of the time, suppress.
    func shouldContinueInterventions() -> Bool {
        let (sent, _, _, rate) = getEffectiveness(lastN: 20)

        // Need sample size
        guard sent >= 10 else { return true }

        // If only 50%+ of interventions are acted on (not dismissed),
        // continue; else suppress
        return rate >= 0.5
    }
}
