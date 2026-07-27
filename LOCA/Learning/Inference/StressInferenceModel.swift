//
//  StressInferenceModel.swift
//  LOCA
//
//  Stress inference model
//  Infers load/arousal from HRV, event density, location changes, sentiment
//

import Foundation

class StressInferenceModel {
    private var hrvWeight: Double = 0.25
    private var eventDensityWeight: Double = 0.2
    private var locationChangeWeight: Double = 0.2
    private var sentimentWeight: Double = 0.15
    private var dayOfWeekWeight: Double = 0.1
    private var loggedStressWeight: Double = 0.1

    private var dayOfWeekBaseline: [Int: Double] = [:]

    init() {
        initializeDayOfWeekBaseline()
    }

    // MARK: - Main Inference

    func infer(
        signals: [SignalEvent],
        aggregates: [SignalSource: AggregatedValue],
        timestamp: Date
    ) -> InferenceResult {
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: timestamp)

        var uncertaintyTerms: [Double] = []
        var stressComponents: [Double] = []
        var hasRealEvidence = false

        // Component 1: HRV (inverse: low HRV = high stress)
        if let hrvAggregate = aggregates[.heartRateVariability] {
            let hrvStress = 1.0 - hrvAggregate.mean
            stressComponents.append(hrvStress * hrvWeight)
            uncertaintyTerms.append(hrvAggregate.uncertainty * hrvWeight)
            hasRealEvidence = true
        } else {
            uncertaintyTerms.append(0.25 * hrvWeight)
        }

        // Component 2: Event density (more events = more stress)
        if let calendarAggregate = aggregates[.calendar] {
            stressComponents.append(calendarAggregate.mean * eventDensityWeight)
            uncertaintyTerms.append(calendarAggregate.uncertainty * eventDensityWeight)
            hasRealEvidence = true
        } else {
            uncertaintyTerms.append(0.2 * eventDensityWeight)
        }

        // Component 3: Location changes (task-switching stress indicator)
        if let locationChangeScore = detectLocationChanges(signals: signals) {
            stressComponents.append(locationChangeScore * locationChangeWeight)
            uncertaintyTerms.append(0.15 * locationChangeWeight)
            hasRealEvidence = true
        } else {
            uncertaintyTerms.append(0.15 * locationChangeWeight)
        }

        // Component 4: Note sentiment — nil when no notes logged
        if let sentimentScore = extractNoteSentiment(signals: signals) {
            stressComponents.append((1.0 - sentimentScore) * sentimentWeight)
            uncertaintyTerms.append(0.2 * sentimentWeight)
            hasRealEvidence = true
        } else {
            uncertaintyTerms.append(0.2 * sentimentWeight)
        }

        // Component 5: Explicit logged stress
        if let loggedSignal = signals.first(where: { $0.source == .explicitLog }) {
            stressComponents.append(loggedSignal.value * loggedStressWeight)
            uncertaintyTerms.append(loggedSignal.uncertainty * loggedStressWeight)
            hasRealEvidence = true
        } else {
            uncertaintyTerms.append(0.25 * loggedStressWeight)
        }

        // C1.1: Day-of-week is a prior, not evidence. Return absent when nothing real arrived.
        guard hasRealEvidence else {
            return .absent(uncertainty: 1.0)
        }

        // Day-of-week baseline is valid context when real evidence exists.
        let dayBaseline = dayOfWeekBaseline[dayOfWeek] ?? defaultDayOfWeekBaseline(dayOfWeek: dayOfWeek)
        stressComponents.append(dayBaseline * dayOfWeekWeight)
        uncertaintyTerms.append(0.1 * dayOfWeekWeight)

        let stress = stressComponents.reduce(0, +)
        let baseUncertainty = sqrt(
            uncertaintyTerms.map { pow($0, 2) }.reduce(0, +)
        )

        return .measured(
            value: min(1.0, max(0, stress)),
            uncertainty: min(1.0, baseUncertainty)
        )
    }

    // MARK: - Location Changes

    // C1.1: Returns nil when fewer than 2 location signals — cannot infer change rate.
    private func detectLocationChanges(signals: [SignalEvent]) -> Double? {
        let locationSignals = signals.filter { $0.source == .location }
        guard locationSignals.count > 1 else { return nil }

        var changeCount = 0
        var lastPlace: String?

        for signal in locationSignals.sorted(by: { $0.timestamp < $1.timestamp }) {
            if let place = signal.metadata["place"], place != lastPlace {
                changeCount += 1
                lastPlace = place
            }
        }

        let changeScore = Double(changeCount) / Double(locationSignals.count)
        return min(1.0, changeScore)
    }

    // MARK: - Sentiment Analysis (Simple)

    // C1.1: Returns nil when no notes logged — absence of notes is not neutral sentiment.
    private func extractNoteSentiment(signals: [SignalEvent]) -> Double? {
        let notedSignals = signals.filter { $0.source == .explicitLog }
        var sentimentSum = 0.0
        var count = 0

        for signal in notedSignals {
            if let note = signal.metadata["note"] {
                sentimentSum += simpleSentimentScore(note)
                count += 1
            }
        }

        guard count > 0 else { return nil }
        return sentimentSum / Double(count)
    }

    private func simpleSentimentScore(_ text: String) -> Double {
        let lowerText = text.lowercased()

        let positiveWords = ["great", "amazing", "excellent", "good", "happy", "energized", "focused"]
        let negativeWords = ["bad", "terrible", "awful", "stressed", "anxious", "tired", "overwhelmed"]

        var score = 0.5

        for word in positiveWords {
            if lowerText.contains(word) {
                score += 0.1
            }
        }

        for word in negativeWords {
            if lowerText.contains(word) {
                score -= 0.1
            }
        }

        return max(0, min(1, score))
    }

    // MARK: - Day-of-Week Baseline

    private func initializeDayOfWeekBaseline() {
        for day in 1...7 {
            dayOfWeekBaseline[day] = nil
        }
    }

    private func defaultDayOfWeekBaseline(dayOfWeek: Int) -> Double {
        switch dayOfWeek {
        case 1: return 0.35  // Sunday: lowest stress (recovery)
        case 2: return 0.5   // Monday: stress ramps
        case 3: return 0.5   // Tuesday: sustained
        case 4: return 0.5   // Wednesday: mid-week stress
        case 5: return 0.55  // Thursday: building fatigue
        case 6: return 0.45  // Friday: relief in sight
        case 7: return 0.3   // Saturday: low stress (weekend)
        default: return 0.5
        }
    }

    // MARK: - Personalization

    func updateDayOfWeekBaseline(dayOfWeek: Int, observedStress: Double) {
        dayOfWeekBaseline[dayOfWeek] = observedStress
    }

    func updateWeights(
        hrvWeight: Double,
        eventDensityWeight: Double,
        locationChangeWeight: Double,
        sentimentWeight: Double,
        dayOfWeekWeight: Double,
        loggedWeight: Double
    ) {
        let total = hrvWeight + eventDensityWeight + locationChangeWeight + sentimentWeight + dayOfWeekWeight + loggedWeight
        self.hrvWeight = hrvWeight / total
        self.eventDensityWeight = eventDensityWeight / total
        self.locationChangeWeight = locationChangeWeight / total
        self.sentimentWeight = sentimentWeight / total
        self.dayOfWeekWeight = dayOfWeekWeight / total
        self.loggedStressWeight = loggedWeight / total
    }
}
