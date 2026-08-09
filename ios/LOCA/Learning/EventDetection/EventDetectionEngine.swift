//
//  EventDetectionEngine.swift
//  LOCA
//
//  Life Event detection engine
//  Three-stage pipeline: anomaly detection → regime persistence → classification
//

import Foundation
import SwiftData
import Combine

@MainActor
class EventDetectionEngine: NSObject, ObservableObject {
    static let shared = EventDetectionEngine()

    @Published var lastDetectionTime: Date?
    @Published var detectionError: String?

    private let anomalyDetector = AnomalyDetector()
    private let regimePersistenceChecker = RegimePersistenceChecker()
    private let eventClassifier = EventClassifier()

    // C6B: an event is surfaced only when its combined (weakest-link) confidence
    // clears this bar. Downstream consumers (Chapters, timeline) then reflect an
    // honest confidence rather than a raw classification magnitude.
    private let eventConfidenceBar = 0.5

    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Main Detection Loop

    func detectEventsForPastMonth(modelContext: ModelContext) async {
        let ctx = self.modelContext ?? modelContext

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

                    // C6B: the event's confidence is the weakest-link conjunction of
                    // the evidence that it happened (anomaly × persistence) and the
                    // evidence for what it was (classification margin) — not the raw
                    // classification magnitude.
                    let eventConfidence = combinedEventConfidence(
                        anomaly: anomalyConfidence(anomalyScore: anomalousWeek.anomalyScore),
                        persistence: persistenceConfidence(distance: regimePersistenceChecker.lastPersistenceScore),
                        classification: classification.confidence
                    )

                    // Only insert events that clear the confidence bar, and only if we
                    // haven't already recorded one near this time. This detector
                    // re-scans the whole past month every run; the proximity guard
                    // keeps it idempotent and preserves each event's stable identity
                    // across runs, so Chapters (which link events by id) don't duplicate.
                    guard eventConfidence >= eventConfidenceBar else { continue }

                    let windowStart = eventTimestamp.addingTimeInterval(-3 * 86400)
                    let windowEnd = eventTimestamp.addingTimeInterval(3 * 86400)
                    let nearbyDescriptor = FetchDescriptor<LifeEvent>(
                        predicate: #Predicate { existing in
                            existing.timestamp >= windowStart && existing.timestamp <= windowEnd
                        }
                    )
                    let alreadyRecorded = !((try? ctx.fetch(nearbyDescriptor)) ?? []).isEmpty
                    guard !alreadyRecorded else { continue }

                    let event = LifeEvent(
                        timestamp: eventTimestamp,
                        eventType: classification.eventType,
                        confidence: eventConfidence,
                        anomalyScore: anomalousWeek.anomalyScore,
                        persistenceScore: regimePersistenceChecker.lastPersistenceScore,
                        classificationScore: classification.confidence,
                        metadata: classification.metadata
                    )
                    ctx.insert(event)
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

    /// Expected inferred-state slots per week (~4 readings/day × 7 days). Drives
    /// dataDensity — the fraction of the week actually covered by present states.
    private let expectedWeeklySlots = 28.0

    private func computeWeeklyRegime(
        weekStart: Date,
        states: [InferredState],
        modelContext: ModelContext
    ) -> WeeklyRegime {
        // C6/C1: build each metric from PRESENT states only. Absent states (value
        // 0.0) are no-data, not measured zeros, and must not pollute the mean.
        // C6/C5: aggregate present values through Rule A so the regime inherits the
        // propagated measurement uncertainty of the states beneath it.
        let energyStates = states.filter { !$0.energyAbsent }
        let stressStates = states.filter { !$0.stressAbsent }
        let focusStates  = states.filter { !$0.focusAbsent }
        let moodStates   = states.filter { !$0.moodAbsent }
        let energy = metricSummary(values: energyStates.map { $0.energy }, uncertainties: energyStates.map { $0.energyUncertainty })
        let stress = metricSummary(values: stressStates.map { $0.stress }, uncertainties: stressStates.map { $0.stressUncertainty })
        let focus  = metricSummary(values: focusStates.map { $0.focus },   uncertainties: focusStates.map { $0.focusUncertainty })
        let mood   = metricSummary(values: moodStates.map { $0.mood },     uncertainties: moodStates.map { $0.moodUncertainty })

        // Data density: how much of the week is actually covered by present states.
        // A metric with no present readings does not count toward coverage.
        let presentCount = states.filter {
            !($0.energyAbsent && $0.stressAbsent && $0.focusAbsent && $0.moodAbsent)
        }.count
        let dataDensity = min(1.0, Double(presentCount) / expectedWeeklySlots)

        let scheduleRegularity = computeScheduleRegularity(states: states)
        let locationDiversity = computeLocationDiversity(weekStart: weekStart, modelContext: modelContext)
        let socialEngagement = computeSocialEngagement(weekStart: weekStart, modelContext: modelContext)
        let activityLevel = computeActivityLevel(weekStart: weekStart, modelContext: modelContext)

        return WeeklyRegime(
            weekStart: weekStart,
            energyMean: energy.mean, energyStddev: energy.stddev,
            stressMean: stress.mean, stressStddev: stress.stddev,
            focusMean: focus.mean, focusStddev: focus.stddev,
            moodMean: mood.mean, moodStddev: mood.stddev,
            scheduleRegularity: scheduleRegularity,
            locationDiversity: locationDiversity,
            socialEngagement: socialEngagement,
            activityLevel: activityLevel,
            energyUncertainty: energy.uncertainty,
            stressUncertainty: stress.uncertainty,
            focusUncertainty: focus.uncertainty,
            moodUncertainty: mood.uncertainty,
            energyAbsent: energy.absent,
            stressAbsent: stress.absent,
            focusAbsent: focus.absent,
            moodAbsent: mood.absent,
            dataDensity: dataDensity
        )
    }

    /// Summarize one metric's present readings: sample mean/stddev plus the Rule A
    /// propagated uncertainty. When no present readings exist, the metric is absent
    /// (mean 0, uncertainty 1) — never a fabricated 0.0 mean.
    private func metricSummary(
        values: [Double],
        uncertainties: [Double]
    ) -> (mean: Double, stddev: Double, uncertainty: Double, absent: Bool) {
        guard !values.isEmpty else {
            return (mean: 0.0, stddev: 0.0, uncertainty: 1.0, absent: true)
        }
        let agg = aggregateUncertainty(values: values, uncertainties: uncertainties)  // C5 Rule A
        let stddev = sqrt(values.map { pow($0 - agg.mean, 2) }.reduce(0, +) / Double(values.count))
        return (mean: agg.mean, stddev: stddev, uncertainty: agg.uncertainty, absent: false)
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
                event.timestamp >= weekStart && event.timestamp <= weekEnd
            }
        )

        let allLocationEvents = (try? modelContext.fetch(descriptor)) ?? []
        let events = allLocationEvents.filter { $0.source == .location }
        guard !events.isEmpty else { return 0.5 }

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
                event.timestamp >= weekStart && event.timestamp <= weekEnd
            }
        )

        let allCalendarEvents = (try? modelContext.fetch(descriptor)) ?? []
        let events = allCalendarEvents.filter { $0.source == .calendar }
        guard !events.isEmpty else { return 0.5 }

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
                event.timestamp >= weekStart && event.timestamp <= weekEnd
            }
        )

        let allActivityEvents = (try? modelContext.fetch(descriptor)) ?? []
        let events = allActivityEvents.filter { $0.source == .motionActivity || $0.source == .steps }
        guard !events.isEmpty else { return 0.5 }

        let avgActivity = events.map { $0.value }.reduce(0, +) / Double(events.count)
        return avgActivity
    }
}
