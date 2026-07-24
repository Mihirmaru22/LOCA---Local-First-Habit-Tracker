//
//  MoodInferenceModel.swift
//  LOCA
//
//  Mood inference model
//  Infers valence (good/bad feeling) from check-ins, sentiment, social engagement, sleep
//  Mood is the slowest state to change (day-to-day baseline with hourly perturbations)
//

import Foundation

class MoodInferenceModel {
    private var moodCheckinWeight: Double = 0.25
    private var sentimentWeight: Double = 0.2
    private var socialEngagementWeight: Double = 0.15
    private var varietyWeight: Double = 0.15
    private var sleepQualityWeight: Double = 0.15
    private var loggedMoodWeight: Double = 0.1

    private var baselineHourMood: [Int: Double] = [:]

    init() {
        initializeBaseline()
    }

    // MARK: - Main Inference

    func infer(
        signals: [SignalEvent],
        aggregates: [SignalSource: AggregatedValue],
        timestamp: Date
    ) -> InferenceResult {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: timestamp)

        var uncertaintyTerms: [Double] = []
        var moodComponents: [Double] = []

        // Component 1: Explicit mood check-ins (recent 7 days, aggregate)
        // Note: In real implementation, fetch from InferredState history
        let recentMoodScore = extractRecentMoodCheck(signals: signals)
        moodComponents.append(recentMoodScore * moodCheckinWeight)
        uncertaintyTerms.append(0.4 * moodCheckinWeight)  // High uncertainty if sparse

        // Component 2: Note sentiment (last 6 hours)
        let sentimentScore = extractNoteSentiment(signals: signals)
        moodComponents.append(sentimentScore * sentimentWeight)
        uncertaintyTerms.append(0.25 * sentimentWeight)

        // Component 3: Social engagement (presence of people, social events)
        let socialScore = calculateSocialEngagement(signals: signals)
        moodComponents.append(socialScore * socialEngagementWeight)
        uncertaintyTerms.append(0.2 * socialEngagementWeight)

        // Component 4: Variety score (entropy of places, activities)
        let varietyScore = calculateVariety(signals: signals)
        moodComponents.append(varietyScore * varietyWeight)
        uncertaintyTerms.append(0.2 * varietyWeight)

        // Component 5: Sleep quality (chronic sleep debt affects mood)
        if let sleepAggregate = aggregates[.sleep] {
            moodComponents.append(sleepAggregate.mean * sleepQualityWeight)
            uncertaintyTerms.append(sleepAggregate.uncertainty * sleepQualityWeight)
        } else {
            uncertaintyTerms.append(0.15 * sleepQualityWeight)
        }

        // Component 6: Explicit logged mood
        if let loggedSignal = signals.first(where: { $0.source == .explicitLog }) {
            moodComponents.append(loggedSignal.value * loggedMoodWeight)
            uncertaintyTerms.append(loggedSignal.uncertainty * loggedMoodWeight)
        } else {
            uncertaintyTerms.append(0.3 * loggedMoodWeight)
        }

        let mood = moodComponents.reduce(0, +)
        let baseUncertainty = sqrt(
            uncertaintyTerms.map { pow($0, 2) }.reduce(0, +)
        )

        return InferenceResult(
            value: min(1.0, max(0, mood)),
            uncertainty: min(1.0, baseUncertainty)
        )
    }

    // MARK: - Recent Mood Check-Ins

    private func extractRecentMoodCheck(signals: [SignalEvent]) -> Double {
        let moodSignals = signals.filter { $0.source == .explicitLog }
            .filter { $0.metadata["mood"] != nil }

        guard !moodSignals.isEmpty else { return 0.5 }

        let moodValues = moodSignals.compactMap { signal -> Double? in
            guard let moodStr = signal.metadata["mood"],
                  let mood = Double(moodStr) else { return nil }
            return mood
        }

        guard !moodValues.isEmpty else { return 0.5 }

        return moodValues.reduce(0, +) / Double(moodValues.count)
    }

    // MARK: - Sentiment Analysis

    private func extractNoteSentiment(signals: [SignalEvent]) -> Double {
        let notedSignals = signals.filter { $0.source == .explicitLog }

        var sentimentSum = 0.5
        var count = 0

        for signal in notedSignals {
            if let note = signal.metadata["note"] {
                let sentiment = simpleSentimentScore(note)
                sentimentSum += sentiment
                count += 1
            }
        }

        guard count > 0 else { return 0.5 }
        return sentimentSum / Double(count + 1)
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

    private func calculateSocialEngagement(signals: [SignalEvent]) -> Double {
        let calendarSignals = signals.filter { $0.source == .calendar }
        let notes = signals.filter { $0.source == .explicitLog }
            .compactMap { $0.metadata["note"] }

        var socialScore = 0.0

        // Calendar-based: events with attendees
        for signal in calendarSignals {
            if let attendeeCount = Int(signal.metadata["attendee_count"] ?? "0"), attendeeCount > 0 {
                socialScore += 0.3
            }
        }

        // Note-based: mentions of people or social activities
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

    private func calculateVariety(signals: [SignalEvent]) -> Double {
        let locationSignals = signals.filter { $0.source == .location }

        guard !locationSignals.isEmpty else { return 0.5 }

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
    }
}
