//
//  TraitModel.swift
//  LOCA
//
//  Phase 5 — Trait entity
//  Traits are slow-changing personal characteristics, inferred over weeks.
//  Distinct from States (fast, hours) though sharing signal infrastructure.
//

import Foundation
import SwiftData

// MARK: - Trait Type

enum TraitType: String, Codable, CaseIterable {
    case resilience       // How quickly stress recovers after spikes
    case consistency      // How regular daily patterns are across weeks
    case socialDrive      // Tendency to seek social engagement
    case activityDrive    // Tendency toward physical activity
    case focusDepth       // Tendency to sustain long concentration sessions
    case moodStability    // Low mood volatility across time
}

// MARK: - Trait (Persistent)

@Model
final class Trait {
    var id: UUID = UUID()
    var traitType: TraitType
    var value: Double           // 0–1 (low to high expression)
    var uncertainty: Double     // Calibrated confidence in this value
    var updatedAt: Date

    // Rolling window that produced this estimate
    var windowDays: Int         // How many days of data informed this
    var sampleCount: Int        // Number of state observations used

    // Chapter context: trait values can differ across chapters
    var chapterId: UUID?        // nil = global trait estimate

    init(
        traitType: TraitType,
        value: Double,
        uncertainty: Double,
        windowDays: Int = 30,
        sampleCount: Int = 0,
        chapterId: UUID? = nil
    ) {
        self.traitType = traitType
        self.value = max(0, min(1, value))
        self.uncertainty = max(0, min(1, uncertainty))
        self.updatedAt = Date()
        self.windowDays = windowDays
        self.sampleCount = sampleCount
        self.chapterId = chapterId
    }
}
