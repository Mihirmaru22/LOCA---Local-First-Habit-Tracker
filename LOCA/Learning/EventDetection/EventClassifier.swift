//
//  EventClassifier.swift
//  LOCA
//
//  Stage 3 of event detection: Event type classification
//  Classifies detected regime shift into event type
//

import Foundation

struct EventClassificationResult {
    let eventType: LifeEventType
    let confidence: Double
    let metadata: [String: String]
}

class EventClassifier {

    // MARK: - Classification

    func classify(
        eventTime: Date,
        beforeWeek: WeeklyRegime,
        afterStates: [InferredState],
        regimes: [WeeklyRegime]
    ) -> EventClassificationResult {
        let calendar = Calendar.current

        let beforeRegime = beforeWeek
        let afterWeek = regimes.first { regime in
            calendar.isDate(regime.weekStart, inSameDayAs: calendar.date(byAdding: .day, value: 7, to: eventTime)!)
        }

        guard let afterRegime = afterWeek else {
            return EventClassificationResult(
                eventType: .unknown,
                confidence: 0.3,
                metadata: [:]
            )
        }

        var scores: [LifeEventType: Double] = [:]

        // Score each event type
        scores[.scheduleChange] = scoreScheduleChange(before: beforeRegime, after: afterRegime)
        scores[.locationChange] = scoreLocationChange(before: beforeRegime, after: afterRegime)
        scores[.socialChange] = scoreSocialChange(before: beforeRegime, after: afterRegime)
        scores[.healthChange] = scoreHealthChange(before: beforeRegime, after: afterRegime)
        scores[.workChange] = scoreWorkChange(before: beforeRegime, after: afterRegime)
        scores[.habitChange] = scoreHabitChange(before: beforeRegime, after: afterRegime)

        // Find highest scoring type
        guard let (eventType, confidence) = scores.max(by: { $0.value < $1.value }) else {
            return EventClassificationResult(
                eventType: .unknown,
                confidence: 0.3,
                metadata: [:]
            )
        }

        let metadata = buildMetadata(
            eventType: eventType,
            before: beforeRegime,
            after: afterRegime
        )

        return EventClassificationResult(
            eventType: eventType,
            confidence: min(1.0, confidence),
            metadata: metadata
        )
    }

    // MARK: - Scoring Functions

    private func scoreScheduleChange(before: WeeklyRegime, after: WeeklyRegime) -> Double {
        let regularityChange = abs(after.scheduleRegularity - before.scheduleRegularity)
        let energyChange = abs(after.energyMean - before.energyMean)

        return regularityChange * 0.7 + energyChange * 0.3
    }

    private func scoreLocationChange(before: WeeklyRegime, after: WeeklyRegime) -> Double {
        let locationChange = abs(after.locationDiversity - before.locationDiversity)
        let scheduleChange = abs(after.scheduleRegularity - before.scheduleRegularity)
        let activityChange = abs(after.activityLevel - before.activityLevel)

        return locationChange * 0.6 + scheduleChange * 0.2 + activityChange * 0.2
    }

    private func scoreSocialChange(before: WeeklyRegime, after: WeeklyRegime) -> Double {
        let socialChange = abs(after.socialEngagement - before.socialEngagement)
        let moodChange = abs(after.moodMean - before.moodMean)

        return socialChange * 0.7 + moodChange * 0.3
    }

    private func scoreHealthChange(before: WeeklyRegime, after: WeeklyRegime) -> Double {
        let energyChange = abs(after.energyMean - before.energyMean)
        let activityChange = abs(after.activityLevel - before.activityLevel)
        let stressChange = abs(after.stressMean - before.stressMean)

        return energyChange * 0.5 + activityChange * 0.3 + stressChange * 0.2
    }

    private func scoreWorkChange(before: WeeklyRegime, after: WeeklyRegime) -> Double {
        let scheduleChange = abs(after.scheduleRegularity - before.scheduleRegularity)
        let focusChange = abs(after.focusMean - before.focusMean)
        let stressChange = abs(after.stressMean - before.stressMean)

        return scheduleChange * 0.5 + focusChange * 0.3 + stressChange * 0.2
    }

    private func scoreHabitChange(before: WeeklyRegime, after: WeeklyRegime) -> Double {
        let activityChange = abs(after.activityLevel - before.activityLevel)
        let energyChange = abs(after.energyMean - before.energyMean)
        let focusChange = abs(after.focusMean - before.focusMean)

        return activityChange * 0.5 + energyChange * 0.3 + focusChange * 0.2
    }

    // MARK: - Metadata Building

    private func buildMetadata(
        eventType: LifeEventType,
        before: WeeklyRegime,
        after: WeeklyRegime
    ) -> [String: String] {
        var metadata: [String: String] = [:]

        metadata["event_type"] = eventType.rawValue
        metadata["energy_before"] = String(format: "%.2f", before.energyMean)
        metadata["energy_after"] = String(format: "%.2f", after.energyMean)
        metadata["stress_before"] = String(format: "%.2f", before.stressMean)
        metadata["stress_after"] = String(format: "%.2f", after.stressMean)
        metadata["schedule_regularity_before"] = String(format: "%.2f", before.scheduleRegularity)
        metadata["schedule_regularity_after"] = String(format: "%.2f", after.scheduleRegularity)
        metadata["location_diversity_before"] = String(format: "%.2f", before.locationDiversity)
        metadata["location_diversity_after"] = String(format: "%.2f", after.locationDiversity)

        return metadata
    }
}
