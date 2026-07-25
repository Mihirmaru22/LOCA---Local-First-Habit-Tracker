//
//  MotionActivityManager.swift
//  LOCA
//
//  Motion and activity tracking (steps, movement)
//

import Foundation
import CoreMotion

@MainActor
class MotionActivityManager: NSObject {
    private let pedometer = CMPedometer()

    // MARK: - Motion Collection

    func collectMotion() async throws -> [SignalEvent] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let now = Date()

        // CMPedometer delivers its handler on a private CoreMotion serial queue,
        // not the main queue. Marking the handler @Sendable keeps it off the
        // MainActor so the concurrency runtime doesn't assert (dispatch_assert_queue).
        // We extract only Sendable primitives here and build the SwiftData @Model
        // back on the MainActor after the await.
        let totalSteps: Int? = await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(
                from: thirtyDaysAgo,
                to: now
            ) { @Sendable data, error in
                if let data = data, error == nil {
                    continuation.resume(returning: data.numberOfSteps.intValue)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }

        guard let totalSteps else { return [] }

        let hours = Int(now.timeIntervalSince(thirtyDaysAgo) / 3600)
        let avgStepsPerHour = hours > 0 ? Double(totalSteps) / Double(hours) : 0
        let normalized = min(1.0, avgStepsPerHour / 500)

        let signal = SignalEvent(
            timestamp: now,
            source: .motionActivity,
            value: normalized,
            uncertainty: 0.15,
            metadata: [
                "total_steps": String(totalSteps),
                "avg_per_hour": String(format: "%.0f", avgStepsPerHour)
            ]
        )

        return [signal]
    }
}
