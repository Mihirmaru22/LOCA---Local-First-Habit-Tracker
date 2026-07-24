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
    private let motionManager = CMMotionManager()
    private let pedometer = CMPedometer()

    override init() {
        super.init()
        setupMotionDetection()
    }

    private func setupMotionDetection() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 60
        }
    }

    // MARK: - Motion Collection

    func collectMotion() async throws -> [SignalEvent] {
        var signals: [SignalEvent] = []

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let now = Date()

        return await withCheckedContinuation { continuation in
            pedometer.queryPedometerData(
                from: thirtyDaysAgo,
                to: now
            ) { data, error in
                guard let data = data, error == nil else {
                    continuation.resume(returning: [])
                    return
                }

                let totalSteps = data.numberOfSteps.intValue
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
                signals.append(signal)

                continuation.resume(returning: signals)
            }
        }
    }
}
