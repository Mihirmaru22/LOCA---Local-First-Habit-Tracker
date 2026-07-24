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
        activityLevel: Double
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
    }
}
