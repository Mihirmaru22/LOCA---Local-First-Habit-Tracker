//
//  MoodInferenceModel.swift
//  LOCA
//
//  Mood inference model
//  Infers valence (good/bad feeling) from check-ins, sentiment, social engagement, sleep
//  Mood is the slowest state to change (day-to-day baseline with hourly perturbations)
//

import Foundation

@MainActor
class MoodInferenceModel {
    static let shared = MoodInferenceModel()

    private var moodCheckinWeight: Double = 0.25
    private var sentimentWeight: Double = 0.2
    private var socialEngagementWeight: Double = 0.15
    private var varietyWeight: Double = 0.15
    private var sleepQualityWeight: Double = 0.15
    private var loggedMoodWeight: Double = 0.1

    private var baselineHourMood: [Int: Double] = [:]

    private let defaults = UserDefaults.standard
    private let keyMoodCheckinWeight = "mood_moodCheckinWeight"
    private let keySentimentWeight = "mood_sentimentWeight"
    private let keySocialEngagementWeight = "mood_socialEngagementWeight"
    private let keyVarietyWeight = "mood_varietyWeight"
    private let keySleepQualityWeight = "mood_sleepQualityWeight"
    private let keyLoggedWeight = "mood_loggedWeight"

    init() {
        loadWeights()
        initializeBaseline()
    }

    private func loadWeights() {
        if defaults.object(forKey: keyMoodCheckinWeight) != nil {
            moodCheckinWeight = defaults.double(forKey: keyMoodCheckinWeight)
            sentimentWeight = defaults.double(forKey: keySentimentWeight)
            socialEngagementWeight = defaults.double(forKey: keySocialEngagementWeight)
            varietyWeight = defaults.double(forKey: keyVarietyWeight)
            sleepQualityWeight = defaults.double(forKey: keySleepQualityWeight)
            loggedMoodWeight = defaults.double(forKey: keyLoggedWeight)
        }
    }

    private func saveWeights() {
        defaults.set(moodCheckinWeight, forKey: keyMoodCheckinWeight)
        defaults.set(sentimentWeight, forKey: keySentimentWeight)
        defaults.set(socialEngagementWeight, forKey: keySocialEngagementWeight)
        defaults.set(varietyWeight, forKey: keyVarietyWeight)
        defaults.set(sleepQualityWeight, forKey: keySleepQualityWeight)
        defaults.set(loggedMoodWeight, forKey: keyLoggedWeight)
    }

    // MARK: - Main Inference

    func infer(
        signals: [SignalEvent],
        aggregates: [SignalSource: AggregatedValue],
        timestamp: Date
    ) -> InferenceResult {
        var uncertaintyTerms: [Double] = []
        var moodComponents: [Double] = []
        var contributingSources: [String] = []
        var totalSampleCount = 0

        // Component 1: Explicit mood check-ins — nil when none logged
        let moodLogSignals = signals.filter { $0.source == .explicitLog && $0.metadata["mood"] != nil }
        if let recentMoodScore = extractRecentMoodCheck(signals: signals) {
            moodComponents.append(recentMoodScore * moodCheckinWeight)
            uncertaintyTerms.append(0.4 * moodCheckinWeight)
            contributingSources.append(SignalSource.explicitLog.rawValue)
            totalSampleCount += moodLogSignals.count
        } else {
            uncertaintyTerms.append(0.4 * moodCheckinWeight)
        }

        // Component 2: Note sentiment — nil when no notes present
        let noteSignals = signals.filter { $0.source == .explicitLog && $0.metadata["note"] != nil }
        if let sentimentScore = extractNoteSentiment(signals: signals) {
            moodComponents.append(sentimentScore * sentimentWeight)
            uncertaintyTerms.append(0.25 * sentimentWeight)
            if !contributingSources.contains(SignalSource.explicitLog.rawValue) {
                contributingSources.append(SignalSource.explicitLog.rawValue)
            }
            totalSampleCount += noteSignals.count
        } else {
            uncertaintyTerms.append(0.25 * sentimentWeight)
        }

        // Component 3: Social engagement — nil when no calendar or social signals
        let calendarSignals = signals.filter { $0.source == .calendar }
        if let socialScore = calculateSocialEngagement(signals: signals) {
            moodComponents.append(socialScore * socialEngagementWeight)
            uncertaintyTerms.append(0.2 * socialEngagementWeight)
            if !calendarSignals.isEmpty {
                if !contributingSources.contains(SignalSource.calendar.rawValue) {
                    contributingSources.append(SignalSource.calendar.rawValue)
                    totalSampleCount += calendarSignals.count
                }
            }
        } else {
            uncertaintyTerms.append(0.2 * socialEngagementWeight)
        }

        // Component 4: Variety score — nil when no location signals
        let locationSignals = signals.filter { $0.source == .location }
        if let varietyScore = calculateVariety(signals: signals) {
            moodComponents.append(varietyScore * varietyWeight)
            uncertaintyTerms.append(0.2 * varietyWeight)
            contributingSources.append(SignalSource.location.rawValue)
            totalSampleCount += locationSignals.count
        } else {
            uncertaintyTerms.append(0.2 * varietyWeight)
        }

        // Component 5: Sleep quality
        if let sleepAggregate = aggregates[.sleep] {
            moodComponents.append(sleepAggregate.mean * sleepQualityWeight)
            uncertaintyTerms.append(sleepAggregate.uncertainty * sleepQualityWeight)
            contributingSources.append(SignalSource.sleep.rawValue)
            totalSampleCount += sleepAggregate.sampleCount
        } else {
            uncertaintyTerms.append(0.15 * sleepQualityWeight)
        }

        // Component 6: Explicit logged mood (distinct from mood check-in metadata)
        let explicitLogs = signals.filter { $0.source == .explicitLog }
        if let loggedSignal = explicitLogs.first {
            moodComponents.append(loggedSignal.value * loggedMoodWeight)
            uncertaintyTerms.append(loggedSignal.uncertainty * loggedMoodWeight)
            if !contributingSources.contains(SignalSource.explicitLog.rawValue) {
                contributingSources.append(SignalSource.explicitLog.rawValue)
                totalSampleCount += explicitLogs.count
            }
        } else {
            uncertaintyTerms.append(0.3 * loggedMoodWeight)
        }

        // C1.1: Mood has no model priors (no circadian equivalent). Zero components = absent.
        guard !moodComponents.isEmpty else {
            return .absent(uncertainty: 1.0)
        }

        let mood = moodComponents.reduce(0, +)
        let baseUncertainty = sqrt(
            uncertaintyTerms.map { pow($0, 2) }.reduce(0, +)
        )

        let windowStart = signals.map(\.timestamp).min() ?? timestamp
        let windowEnd   = signals.map(\.timestamp).max() ?? timestamp
        let provenance  = InferenceProvenance.create(
            sources: contributingSources,
            sampleCount: totalSampleCount,
            windowStart: windowStart,
            windowEnd: windowEnd
        )

        return .measured(
            value: min(1.0, max(0, mood)),
            uncertainty: min(1.0, baseUncertainty),
            provenance: provenance
        )
    }

    // MARK: - Recent Mood Check-Ins

    // C1.1: Returns nil when no mood check-ins — absence is not the same as a neutral 0.5.
    private func extractRecentMoodCheck(signals: [SignalEvent]) -> Double? {
        let moodValues = signals
            .filter { $0.source == .explicitLog && $0.metadata["mood"] != nil }
            .compactMap { signal -> Double? in
                guard let moodStr = signal.metadata["mood"],
                      let mood = Double(moodStr) else { return nil }
                return mood
            }

        guard !moodValues.isEmpty else { return nil }
        return moodValues.reduce(0, +) / Double(moodValues.count)
    }

    // MARK: - Sentiment Analysis

    // C1.1: Returns nil when no notes logged — no notes is not neutral sentiment.
    private func extractNoteSentiment(signals: [SignalEvent]) -> Double? {
        var sentimentSum = 0.0
        var count = 0

        for signal in signals where signal.source == .explicitLog {
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

        let positiveWords = ["happy", "great", "amazing", "love", "wonderful", "excited", "grateful"]
        let negativeWords = ["sad", "angry", "frustrated", "disappointed", "lonely", "depressed", "scared"]

        var score = 0.5

        for word in positiveWords {
            if lowerText.contains(word) {
                score += 0.12
            }
        }

        for word in negativeWords {
            if lowerText.contains(word) {
                score -= 0.12
            }
        }

        return max(0, min(1, score))
    }

    // MARK: - Social Engagement

    // C1.1: Returns nil when no calendar or explicit-log signals are present.
    private func calculateSocialEngagement(signals: [SignalEvent]) -> Double? {
        let calendarSignals = signals.filter { $0.source == .calendar }
        let notes = signals.filter { $0.source == .explicitLog }
            .compactMap { $0.metadata["note"] }

        guard !calendarSignals.isEmpty || !notes.isEmpty else { return nil }

        var socialScore = 0.0

        for signal in calendarSignals {
            if let attendeeCount = Int(signal.metadata["attendee_count"] ?? "0"), attendeeCount > 0 {
                socialScore += 0.3
            }
        }

        for note in notes {
            if containsSocialKeywords(note) {
                socialScore += 0.2
            }
        }

        return min(1.0, socialScore / max(1, Double(calendarSignals.count + notes.count)))
    }

    private func containsSocialKeywords(_ text: String) -> Bool {
        let keywords = ["with", "friend", "family", "call", "meeting", "lunch", "dinner", "party", "together"]
        let lowerText = text.lowercased()
        return keywords.contains { lowerText.contains($0) }
    }

    // MARK: - Variety (Monotony -> Low Mood)

    // C1.1: Returns nil when no location signals — cannot measure variety without location data.
    private func calculateVariety(signals: [SignalEvent]) -> Double? {
        let locationSignals = signals.filter { $0.source == .location }
        guard !locationSignals.isEmpty else { return nil }

        var uniquePlaces = Set<String>()
        for signal in locationSignals {
            if let place = signal.metadata["place"] {
                uniquePlaces.insert(place)
            }
        }

        let varietyRatio = Double(uniquePlaces.count) / Double(locationSignals.count)
        return min(1.0, varietyRatio)
    }

    // MARK: - Initialization

    private func initializeBaseline() {
        for hour in 0..<24 {
            baselineHourMood[hour] = nil
        }
    }

    // MARK: - Personalization

    func updateHourlyBaseline(hour: Int, observedMood: Double) {
        baselineHourMood[hour] = observedMood
    }

    func updateWeights(
        moodCheckinWeight: Double,
        sentimentWeight: Double,
        socialEngagementWeight: Double,
        varietyWeight: Double,
        sleepQualityWeight: Double,
        loggedWeight: Double
    ) {
        let total = moodCheckinWeight + sentimentWeight + socialEngagementWeight + varietyWeight + sleepQualityWeight + loggedWeight
        self.moodCheckinWeight = moodCheckinWeight / total
        self.sentimentWeight = sentimentWeight / total
        self.socialEngagementWeight = socialEngagementWeight / total
        self.varietyWeight = varietyWeight / total
        self.sleepQualityWeight = sleepQualityWeight / total
        self.loggedMoodWeight = loggedWeight / total
        saveWeights()
    }
}
