//
//  MotionActivityManager.swift
//  LOCA
//
//  C3.2 — Motion activity type ingestion
//  Replaces the 30-day CMPedometer aggregate with hourly CMMotionActivity
//  classification (walking / running / cycling / automotive / stationary).
//  Returns one SignalEvent per hour, using the dominant activity type for
//  that hour weighted by confidence.
//

import Foundation
import CoreMotion

@MainActor
class MotionActivityManager: NSObject {
    private let activityManager = CMMotionActivityManager()

    // MARK: - Motion Activity Collection

    func collectMotion() async -> [SignalEvent] {
        guard CMMotionActivityManager.isActivityAvailable() else { return [] }

        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let now = Date()

        // CMMotionActivityManager callback runs on a OperationQueue, not MainActor.
        // Extract only Sendable primitives; build SignalEvents on MainActor after await.
        let rawActivities: [(date: Date, value: Double, label: String)] =
            await withCheckedContinuation { continuation in
                activityManager.queryActivityStarting(
                    from: sevenDaysAgo,
                    to: now,
                    to: OperationQueue()
                ) { @Sendable activities, error in
                    guard let activities, error == nil else {
                        continuation.resume(returning: [])
                        return
                    }
                    let extracted = activities.compactMap { activity -> (Date, Double, String)? in
                        guard activity.confidence != .low else { return nil }
                        let (value, label) = Self.activitySignal(activity)
                        return (activity.startDate, value, label)
                    }
                    continuation.resume(returning: extracted)
                }
            }

        return hourlyDominant(rawActivities)
    }

    // MARK: - Activity → Signal Mapping

    private static func activitySignal(_ activity: CMMotionActivity) -> (Double, String) {
        if activity.running     { return (0.9, "running") }
        if activity.cycling     { return (0.7, "cycling") }
        if activity.walking     { return (0.5, "walking") }
        if activity.automotive  { return (0.3, "automotive") }
        if activity.stationary  { return (0.0, "stationary") }
        return (0.1, "unknown")
    }

    // MARK: - Hourly Aggregation

    private func hourlyDominant(
        _ activities: [(date: Date, value: Double, label: String)]
    ) -> [SignalEvent] {
        let calendar = Calendar.current
        var byHour: [Date: [(Double, String)]] = [:]

        for activity in activities {
            let components = calendar.dateComponents([.year, .month, .day, .hour], from: activity.date)
            guard let hourStart = calendar.date(from: components) else { continue }
            byHour[hourStart, default: []].append((activity.value, activity.label))
        }

        return byHour.map { (hourStart, entries) in
            let mean = entries.map { $0.0 }.reduce(0, +) / Double(entries.count)
            let dominant = entries.max(by: { $0.0 < $1.0 })?.1 ?? "unknown"
            return SignalEvent(
                timestamp: hourStart,
                source: .motionActivity,
                value: min(1.0, mean),
                uncertainty: 0.15,
                metadata: ["activity": dominant, "sample_count": String(entries.count)]
            )
        }
    }
}
