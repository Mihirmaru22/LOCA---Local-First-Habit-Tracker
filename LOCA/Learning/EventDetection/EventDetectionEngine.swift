//
//  EventDetectionEngine.swift
//  LOCA
//
//  Life Event detection engine
//  Three-stage pipeline: anomaly detection → regime persistence → classification
//

import Foundation
import SwiftData

@MainActor
class EventDetectionEngine: NSObject, ObservableObject {
    static let shared = EventDetectionEngine()

    @Published var lastDetectionTime: Date?
    @Published var detectionError: String?

    private let anomalyDetector = AnomalyDetector()
    private let regimePersistenceChecker = RegimePersistenceChecker()
    private let eventClassifier = EventClassifier()

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Main Detection Loop

    func detectEventsForPastMonth(modelContext: ModelContext) async {
        guard let ctx = self.modelContext ?? modelContext else { return }

        do {
            let calendar = Calendar.current
            let now = Date()
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now)!

            // Fetch inferred states for past month
            let descriptor = FetchDescriptor<InferredState>(
                predicate: #Predicate { state in
                    state.timestamp >= oneMonthAgo && state.timestamp <= now
                }
            )

            guard let states = try? ctx.fetch(descriptor), !states.isEmpty else { return }

            // Build weekly regime snapshots
            let weeklyRegimes = buildWeeklyRegimes(states: states, modelContext: ctx)

            // Stage 1: Anomaly detection (weekly level)
            let anomalousWeeks = anomalyDetector.detectAnomalies(
                regimes: weeklyRegimes
            )

            // Stage 2: Regime persistence (4-week forward check)
            for anomalousWeek in anomalousWeeks {
                if let eventTimestamp = regimePersistenceChecker.checkPersistence(
                    anomalousWeek: anomalousWeek,
                    subsequentWeeks: Array(weeklyRegimes.dropFirst()),
                    states: states
                ) {
                    // Stage 3: Classify event type
                    let classification = eventClassifier.classify(
                        eventTime: eventTimestamp,
                        beforeWeek: anomalousWeek,
                        afterStates: states,
                        regimes: weeklyRegimes
                    )

                    let event = LifeEvent(
                        timestamp: eventTimestamp,
                        eventType: classification.eventType,
                        confidence: classification.confidence,
                        anomalyScore: anomalousWeek.anomalyScore,
                        persistenceScore: regimePersistenceChecker.lastPersistenceScore,
                        classificationScore: classification.confidence,
                        metadata: classification.metadata
                    )

                    // Only insert if confidence ≥ 0.7
                    if event.confidence >= 0.7 {
                        ctx.insert(event)
                    }
                }
            }

            try ctx.save()

            lastDetectionTime = now
            detectionError = nil

        } catch {
            detectionError = error.localizedDescription
        }
    }

    // MARK: - Weekly Regime Building

    private func buildWeeklyRegimes(
        states: [InferredState],
        modelContext: ModelContext
    ) -> [WeeklyRegime] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: states) { state -> Date in
            let weekStart = calendar.date(from: calendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear],
                from: state.timestamp
            )) ?? state.timestamp
            return weekStart
        }

        var regimes: [WeeklyRegime] = []

        for (weekStart, weekStates) in grouped.sorted(by: { $0.key < $1.key }) {
            let regime = computeWeeklyRegime(
                weekStart: weekStart,
                states: weekStates,
                modelContext: modelContext
            )
            regimes.append(regime)
        }

        return regimes
    }

    private func computeWeeklyRegime(
        weekStart: Date,
        states: [InferredState],
        modelContext: ModelContext
    ) -> WeeklyRegime {
        let energyValues = states.map { $0.energy }
        let stressValues = states.map { $0.stress }
        let focusValues = states.map { $0.focus }
        let moodValues = states.map { $0.mood }

        let energyMean = energyValues.reduce(0, +) / Double(energyValues.count)
        let stressMean = stressValues.reduce(0, +) / Double(stressValues.count)
        let focusMean = focusValues.reduce(0, +) / Double(focusValues.count)
        let moodMean = moodValues.reduce(0, +) / Double(moodValues.count)

        let energyStddev = sqrt(energyValues.map { pow($0 - energyMean, 2) }.reduce(0, +) / Double(energyValues.count))
        let stressStddev = sqrt(stressValues.map { pow($0 - stressMean, 2) }.reduce(0, +) / Double(stressValues.count))
        let focusStddev = sqrt(focusValues.map { pow($0 - focusMean, 2) }.reduce(0, +) / Double(focusValues.count))
        let moodStddev = sqrt(moodValues.map { pow($0 - moodMean, 2) }.reduce(0, +) / Double(moodValues.count))

        let scheduleRegularity = computeScheduleRegularity(states: states)
        let locationDiversity = computeLocationDiversity(weekStart: weekStart, modelContext: modelContext)
        let socialEngagement = computeSocialEngagement(weekStart: weekStart, modelContext: modelContext)
        let activityLevel = computeActivityLevel(weekStart: weekStart, modelContext: modelContext)

        return WeeklyRegime(
            weekStart: weekStart,
            energyMean: energyMean, energyStddev: energyStddev,
            stressMean: stressMean, stressStddev: stressStddev,
            focusMean: focusMean, focusStddev: focusStddev,
            moodMean: moodMean, moodStddev: moodStddev,
            scheduleRegularity: scheduleRegularity,
            locationDiversity: locationDiversity,
            socialEngagement: socialEngagement,
            activityLevel: activityLevel
        )
    }

    private func computeScheduleRegularity(states: [InferredState]) -> Double {
        guard states.count > 1 else { return 0.5 }

        let calendar = Calendar.current
        var hourBuckets: [Int: Int] = [:]

        for state in states {
            let hour = calendar.component(.hour, from: state.timestamp)
            hourBuckets[hour, default: 0] += 1
        }

        let avgHourCount = Double(states.count) / 24.0
        let variance = hourBuckets.values.map { pow(Double($0) - avgHourCount, 2) }.reduce(0, +)
        let stddev = sqrt(variance / 24.0)

        return 1.0 - min(1.0, stddev / 10.0)
    }

    private func computeLocationDiversity(weekStart: Date, modelContext: ModelContext) -> Double {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!

        let descriptor = FetchDescriptor<SignalEvent>(
            predicate: #Predicate { event in
                event.source == .location &&
                event.timestamp >= weekStart && event.timestamp <= weekEnd
            }
        )

        guard let events = try? modelContext.fetch(descriptor), !events.isEmpty else { return 0.5 }

        var uniquePlaces = Set<String>()
        for event in events {
            if let place = event.metadata["place"] {
                uniquePlaces.insert(place)
            }
        }

        let diversity = Double(uniquePlaces.count) / Double(events.count)
        return min(1.0, diversity)
    }

    private func computeSocialEngagement(weekStart: Date, modelContext: ModelContext) -> Double {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!

        let descriptor = FetchDescriptor<SignalEvent>(
            predicate: #Predicate { event in
                event.source == .calendar &&
                event.timestamp >= weekStart && event.timestamp <= weekEnd
            }
        )

        guard let events = try? modelContext.fetch(descriptor), !events.isEmpty else { return 0.5 }

        var socialEventCount = 0
        for event in events {
            if let attendeeCount = Int(event.metadata["attendee_count"] ?? "0"), attendeeCount > 0 {
                socialEventCount += 1
            }
        }

        return Double(socialEventCount) / Double(events.count)
    }

    private func computeActivityLevel(weekStart: Date, modelContext: ModelContext) -> Double {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!

        let descriptor = FetchDescriptor<SignalEvent>(
            predicate: #Predicate { event in
                event.source == .motionActivity &&
                event.timestamp >= weekStart && event.timestamp <= weekEnd
            }
        )

        guard let events = try? modelContext.fetch(descriptor), !events.isEmpty else { return 0.5 }

        let avgActivity = events.map { $0.value }.reduce(0, +) / Double(events.count)
        return avgActivity
    }
}
