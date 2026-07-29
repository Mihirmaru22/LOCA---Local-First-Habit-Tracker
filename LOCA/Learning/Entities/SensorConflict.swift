//
//  SensorConflict.swift
//  LOCA
//
//  C2.2 — Sensor-authoritative claims stay sensor-settled.
//  Records disagreements between sensor-derived values and user self-reports
//  as evidence. Conflicts are never silently discarded; they are never resolved
//  by overwriting — the sensor value stands, the user value is preserved here.
//

import Foundation
import SwiftData

@Model final class SensorConflict {
    var id: UUID = UUID()
    /// Hour the conflict refers to — matches InferredState.timestamp for the same slot.
    var timestamp: Date = Date()
    /// "energy", "stress", "focus", or "mood"
    var dimension: String = ""
    /// Sensor-derived value from InferredState (authoritative; never changed by this record).
    var sensorValue: Double = 0.0
    /// What the user self-reported for this dimension.
    var userValue: Double = 0.0
    /// abs(sensorValue - userValue) — magnitude of the disagreement on a 0–1 scale.
    var magnitude: Double = 0.0
    /// When this conflict was detected.
    var recordedAt: Date = Date()

    init(timestamp: Date, dimension: String, sensorValue: Double, userValue: Double) {
        self.id = UUID()
        self.timestamp = timestamp
        self.dimension = dimension
        self.sensorValue = sensorValue
        self.userValue = userValue
        self.magnitude = abs(sensorValue - userValue)
        self.recordedAt = Date()
    }
}
