//
//  ReflectionDelivery.swift
//  LOCA
//
//  Phase 4.1 & 4.4 — Reflection delivery and measurement.
//
//  Schedules reflections as push notifications. Stores history for
//  measuring engagement (4.4). Returns nil if there's nothing worth saying.
//

import UserNotifications
import Foundation
import os.log

actor ReflectionDelivery {

    static let shared = ReflectionDelivery()

    nonisolated private let logger = Logger(subsystem: "com.loca.app", category: "reflection")

    /// Store recent reflections for engagement tracking (Phase 4.4).
    private var recentReflections: [ReflectionUnit] = []

    /// Deliver a reflection as a push notification (no UI, no modal).
    /// - Parameter reflection: The one-sentence reflection to deliver.
    func deliverReflection(_ reflection: ReflectionUnit) async {
        let center = UNUserNotificationCenter.current()

        // Remove any existing reflection notification (only one at a time)
        center.removePendingNotificationRequests(withIdentifiers: ["reflection"])

        // Create the notification content
        let content = UNMutableNotificationContent()
        content.title = "A thought"
        content.body = reflection.text
        content.sound = .default
        content.categoryIdentifier = "reflection"

        // Attach reflection id for tracking engagement (Phase 4.4)
        content.userInfo = ["reflectionID": reflection.id.uuidString]

        // Schedule for a random time in the evening (6–8 PM range)
        var dateComponents = DateComponents()
        dateComponents.hour = 6 + Int.random(in: 0..<2)
        dateComponents.minute = Int.random(in: 0..<60)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "reflection",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            recentReflections.append(reflection)
            // Keep only last 30 reflections for tracking
            if recentReflections.count > 30 {
                recentReflections.removeFirst()
            }
            logger.debug("Reflection delivered: \(reflection.contextType.rawValue)")
        } catch {
            logger.warning("Failed to deliver reflection: \(error.localizedDescription)")
        }
    }

    /// Record that a reflection was engaged with (user tapped notification).
    /// Used by Phase 4.4 to measure actual value.
    func markEngaged(reflectionID: UUID) async {
        if let index = recentReflections.firstIndex(where: { $0.id == reflectionID }) {
            recentReflections[index].wasEngaged = true
            logger.debug("Reflection marked as engaged")
        }
    }

    /// Get engagement metrics for the last N reflections (Phase 4.4).
    /// Returns (total delivered, actually engaged, engagement rate).
    func getEngagementMetrics(lastN: Int = 10) -> (delivered: Int, engaged: Int, rate: Double) {
        let recent = recentReflections.suffix(lastN)
        let engaged = recent.filter { $0.wasEngaged }.count
        let rate = recent.isEmpty ? 0 : Double(engaged) / Double(recent.count)
        return (recent.count, engaged, rate)
    }

    /// Check if reflections are earning enough attention to continue (Phase 4.4).
    /// Exit gate: if engagement rate < 30% over last 20 reflections, suppress.
    /// Honest measurement: don't defend feature if users ignore it.
    func shouldContinueReflections() -> Bool {
        let (delivered, _, rate) = getEngagementMetrics(lastN: 20)

        // Need minimum sample size
        guard delivered >= 20 else { return true }

        // If only 30%+ of reflections get engaged, continue; else suppress
        return rate >= 0.3
    }

    /// Log delivery for tracking. Call this each time a reflection is sent.
    func recordDelivery(_ reflection: ReflectionUnit) {
        recentReflections.append(reflection)
        if recentReflections.count > 50 {
            recentReflections.removeFirst()
        }
    }
}
