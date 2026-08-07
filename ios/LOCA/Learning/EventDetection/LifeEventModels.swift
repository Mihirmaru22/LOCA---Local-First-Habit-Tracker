//
//  LifeEventModels.swift
//  LOCA
//
//  Phase 3 — Life Event data models
//

import Foundation
import SwiftData

// MARK: - Event Type Taxonomy

enum LifeEventType: String, Codable {
    case scheduleChange      // Major change in daily structure
    case locationChange      // Move, new commute
    case socialChange        // Relationship, social circle shift
    case healthChange        // Injury, illness, fitness shift
    case workChange          // Job, role, career shift
    case habitChange         // New regular habit, old habit dropped
    case unknown             // Unclassified

    var displayName: String {
        switch self {
        case .scheduleChange: return "Schedule shift"
        case .locationChange: return "Location change"
        case .socialChange:   return "Social change"
        case .healthChange:   return "Health change"
        case .workChange:     return "Work change"
        case .habitChange:    return "Habit change"
        case .unknown:        return "Unclear shift"
        }
    }

    var iconName: String {
        switch self {
        case .scheduleChange: return "clock.arrow.circlepath"
        case .locationChange: return "mappin.and.ellipse"
        case .socialChange:   return "person.2"
        case .healthChange:   return "heart"
        case .workChange:     return "briefcase"
        case .habitChange:    return "repeat"
        case .unknown:        return "questionmark.circle"
        }
    }
}

// MARK: - Life Event (First-Class Entity)

@Model
final class LifeEvent {
    var id: UUID = UUID()
    var timestamp: Date           // Atomic point in time
    var detectedDate: Date        // When we detected it
    var eventType: LifeEventType
    var confidence: Double        // 0–1 (only surface ≥0.7)
    var userConfirmed: Bool = false
    var userNotes: String?

    // Raw detection signals
    var anomalyScore: Double
    var persistenceScore: Double
    var classificationScore: Double

    // Metadata for understanding the shift
    var metadata: [String: String] = [:]

    init(
        timestamp: Date,
        eventType: LifeEventType,
        confidence: Double,
        anomalyScore: Double,
        persistenceScore: Double,
        classificationScore: Double,
        metadata: [String: String] = [:]
    ) {
        self.timestamp = timestamp
        self.detectedDate = Date()
        self.eventType = eventType
        self.confidence = max(0, min(1, confidence))
        self.anomalyScore = anomalyScore
        self.persistenceScore = persistenceScore
        self.classificationScore = classificationScore
        self.metadata = metadata
    }
}

// MARK: - Weekly Regime Snapshot (For Anomaly Detection)

@Model
final class WeeklyRegime {
    var id: UUID = UUID()
    var weekStart: Date
    var weekEnd: Date

    // Aggregated state values (mean, stddev)
    var energyMean: Double
    var energyStddev: Double
    var stressMean: Double
    var stressStddev: Double
    var focusMean: Double
    var focusStddev: Double
    var moodMean: Double
    var moodStddev: Double

    // C6 (Focus A): per-metric propagated uncertainty from the states this regime
    // was built from (via UncertaintyCalculus Rule A). 1.0 = no evidence.
    var energyUncertainty: Double = 1.0
    var stressUncertainty: Double = 1.0
    var focusUncertainty: Double = 1.0
    var moodUncertainty: Double = 1.0

    // C6 (Focus A): true when the week had ZERO present states for that metric.
    // An absent metric is structurally distinct from a measured 0.0 mean and must
    // contribute nothing to anomaly scoring.
    var energyAbsent: Bool = true
    var stressAbsent: Bool = true
    var focusAbsent: Bool = true
    var moodAbsent: Bool = true

    // C6 (Focus A): fraction of the week's expected state slots that were present
    // (present states / 28). Drives the absence/thinness gate — a gap-heavy week
    // cannot assert an event.
    var dataDensity: Double = 0.0

    // Pattern metrics
    var scheduleRegularity: Double         // 0–1 (how consistent daily schedule)
    var locationDiversity: Double          // 0–1 (place variety)
    var socialEngagement: Double           // 0–1 (people interaction)
    var activityLevel: Double              // 0–1 (step count average)

    // Anomaly signals
    var anomalyScore: Double = 0.0

    init(
        weekStart: Date,
        energyMean: Double, energyStddev: Double,
        stressMean: Double, stressStddev: Double,
        focusMean: Double, focusStddev: Double,
        moodMean: Double, moodStddev: Double,
        scheduleRegularity: Double,
        locationDiversity: Double,
        socialEngagement: Double,
        activityLevel: Double,
        energyUncertainty: Double = 1.0,
        stressUncertainty: Double = 1.0,
        focusUncertainty: Double = 1.0,
        moodUncertainty: Double = 1.0,
        energyAbsent: Bool = true,
        stressAbsent: Bool = true,
        focusAbsent: Bool = true,
        moodAbsent: Bool = true,
        dataDensity: Double = 0.0
    ) {
        self.weekStart = weekStart
        self.weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
        self.energyMean = energyMean
        self.energyStddev = energyStddev
        self.stressMean = stressMean
        self.stressStddev = stressStddev
        self.focusMean = focusMean
        self.focusStddev = focusStddev
        self.moodMean = moodMean
        self.moodStddev = moodStddev
        self.scheduleRegularity = scheduleRegularity
        self.locationDiversity = locationDiversity
        self.socialEngagement = socialEngagement
        self.activityLevel = activityLevel
        self.energyUncertainty = energyUncertainty
        self.stressUncertainty = stressUncertainty
        self.focusUncertainty = focusUncertainty
        self.moodUncertainty = moodUncertainty
        self.energyAbsent = energyAbsent
        self.stressAbsent = stressAbsent
        self.focusAbsent = focusAbsent
        self.moodAbsent = moodAbsent
        self.dataDensity = dataDensity
    }
}
