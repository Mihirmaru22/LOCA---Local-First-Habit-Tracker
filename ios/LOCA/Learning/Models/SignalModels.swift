//
//  SignalModels.swift
//  LOCA
//
//  Phase 3 — Signal infrastructure data models
//  Local-first, on-device learning engine foundation
//

import Foundation
import SwiftData

// MARK: - Signal Source Enumeration

enum SignalSource: String, Codable {
    case sleep
    case heartRateVariability
    case heartRate
    case location
    case calendar
    case deviceActivity
    case explicitLog
    case motionActivity
    case steps
    case workout
    case mindfulSession
    case daylight
}

// MARK: - Signal Event (Atomic Measurement)

@Model
final class SignalEvent {
    var id: UUID = UUID()
    var timestamp: Date
    var source: SignalSource
    var value: Double
    var uncertainty: Double
    var metadata: [String: String] = [:]
    var dayBucket: Date?

    init(
        timestamp: Date,
        source: SignalSource,
        value: Double,
        uncertainty: Double,
        metadata: [String: String] = [:]
    ) {
        self.timestamp = timestamp
        self.source = source
        self.value = max(0, min(1, value))
        self.uncertainty = max(0, min(1, uncertainty))
        self.metadata = metadata
        self.dayBucket = Calendar.current.startOfDay(for: timestamp)
    }
}

// MARK: - Aggregation Granularity

enum AggregationGranularity: String, Codable {
    case hourly
    case daily
    case weekly

    var duration: TimeInterval {
        switch self {
        case .hourly: return 3600
        case .daily: return 86400
        case .weekly: return 604800
        }
    }
}

// MARK: - Aggregated Signal Value

struct AggregatedValue: Codable {
    let mean: Double
    let max: Double
    let min: Double
    let stddev: Double
    let uncertainty: Double
    let sampleCount: Int

    var isSparsity: Bool {
        sampleCount < 3
    }
}

// MARK: - Signal Window

struct SignalWindow: Codable {
    let granularity: AggregationGranularity
    let startDate: Date
    let endDate: Date
    var valuesBySource: [SignalSource: AggregatedValue] = [:]

    var isComplete: Bool {
        valuesBySource.count >= 4  // At least 4 of 7 sources
    }
}

// MARK: - Date Range

struct DateRange: Codable {
    let start: Date
    let end: Date
    let reason: String?
}
