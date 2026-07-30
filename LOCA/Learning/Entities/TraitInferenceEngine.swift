//
//  TraitInferenceEngine.swift
//  LOCA
//
//  Phase 5 — Trait inference from long-horizon state patterns
//  Traits are inferred from rolling 30-day windows, updated weekly
//
//  C1 (composition layer): absent InferredState values are filtered before all
//  trait computations. A trait method returns nil when the evidence window
//  contains no present measurements — nil means "no record written," not "0.5."
//

import Foundation
import SwiftData
import os.log

@MainActor
class TraitInferenceEngine {
    static let shared = TraitInferenceEngine()

    private let logger = Logger(subsystem: "com.loca.entities", category: "traits")
    private let windowDays = 30
    private let minimumSamples = 14  // At least 2 weeks of data

    // MARK: - Update All Traits

    func updateTraits(modelContext: ModelContext) throws {
        let windowStart = Calendar.current.date(
            byAdding: .day, value: -windowDays, to: Date()
        )!

        let descriptor = FetchDescriptor<InferredState>(
            predicate: #Predicate { state in
                state.timestamp >= windowStart
            },
            sortBy: [SortDescriptor(\.timestamp)]
        )

        let states = try modelContext.fetch(descriptor)
        guard states.count >= minimumSamples else {
            logger.debug("Insufficient data for trait inference (\(states.count) samples, need \(self.minimumSamples))")
            return
        }

        // Load pattern feedback for trait confidence adjustment
        let processor = FeedbackProcessor.shared
        let patternFeedback = try processor.loadPatternFeedback(modelContext: modelContext)

        for traitType in TraitType.allCases {
            guard let inferred = inferTrait(traitType: traitType, states: states) else {
                // No present measurements for this dimension — leave any existing record unchanged
                logger.debug("No evidence for \(traitType.rawValue) — skipping upsert")
                continue
            }
            upsertTrait(
                type: traitType,
                value: inferred.value,
                uncertainty: inferred.uncertainty,
                sampleCount: states.count,
                modelContext: modelContext
            )
        }

        try modelContext.save()
        logger.info("Traits updated from \(states.count) state samples")
    }

    // MARK: - Per-Trait Dispatch

    // C1: Returns nil when the present-measurement window is empty.
    // Callers must not upsert a nil result — absence must not become 0.5.
    private func inferTrait(
        traitType: TraitType,
        states: [InferredState]
    ) -> (value: Double, uncertainty: Double)? {
        switch traitType {
        case .resilience:      return inferResilience(states: states)
        case .consistency:     return inferConsistency(states: states)
        case .socialDrive:     return inferSocialDrive(states: states)
        case .activityDrive:   return inferActivityDrive(states: states)
        case .focusDepth:      return inferFocusDepth(states: states)
        case .moodStability:   return inferMoodStability(states: states)
        }
    }

    // MARK: - Trait Methods

    // Resilience: speed of stress recovery after spikes.
    // C1: filters stressAbsent states; returns nil when no recovery events observed.
    private func inferResilience(states: [InferredState]) -> (Double, Double)? {
        let present = states.filter { !$0.stressAbsent }
        var recoveryRates: [Double] = []

        for i in 1..<present.count {
            let prev = present[i - 1]
            let curr = present[i]

            if prev.stress > 0.65 && curr.stress < prev.stress {
                let recovery = prev.stress - curr.stress
                recoveryRates.append(recovery)
            }
        }

        guard !recoveryRates.isEmpty else { return nil }

        let meanRecovery = recoveryRates.reduce(0, +) / Double(recoveryRates.count)
        let normalised = min(1.0, meanRecovery / 0.3)
        let uncertainty = max(0.15, 0.5 - Double(recoveryRates.count) * 0.03)

        return (normalised, uncertainty)
    }

    // Consistency: how regular daily energy patterns are across weeks.
    // C1: filters energyAbsent states; returns nil when no hour has ≥3 present samples.
    private func inferConsistency(states: [InferredState]) -> (Double, Double)? {
        let calendar = Calendar.current
        let present = states.filter { !$0.energyAbsent }

        var hourGroups: [Int: [Double]] = [:]
        for state in present {
            let hour = calendar.component(.hour, from: state.timestamp)
            hourGroups[hour, default: []].append(state.energy)
        }

        var hourVariances: [Double] = []
        for (_, values) in hourGroups where values.count >= 3 {
            let mean = values.reduce(0, +) / Double(values.count)
            let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
            hourVariances.append(variance)
        }

        guard !hourVariances.isEmpty else { return nil }

        let meanVariance = hourVariances.reduce(0, +) / Double(hourVariances.count)
        let consistency = 1.0 - min(1.0, meanVariance / 0.1)
        let uncertainty = max(0.1, 0.4 - Double(hourVariances.count) * 0.01)

        return (consistency, uncertainty)
    }

    // Social drive: tendency toward social engagement, proxied through mood lift.
    // C1: filters moodAbsent states; returns nil when no present mood measurements exist.
    private func inferSocialDrive(states: [InferredState]) -> (Double, Double)? {
        let moodValues = states.filter { !$0.moodAbsent }.map { $0.mood }
        guard !moodValues.isEmpty else { return nil }

        let moodMean = moodValues.reduce(0, +) / Double(moodValues.count)
        let highMoodCount = moodValues.filter { $0 > moodMean + 0.1 }.count
        let socialDrive = Double(highMoodCount) / Double(moodValues.count)

        let uncertainty = max(0.2, 0.5 - Double(states.count) * 0.005)
        return (min(1.0, socialDrive * 2.0), uncertainty)
    }

    // Activity drive: tendency toward physical activity, proxied by morning energy.
    // C1: filters energyAbsent states; returns nil when no morning energy samples exist.
    private func inferActivityDrive(states: [InferredState]) -> (Double, Double)? {
        let calendar = Calendar.current
        let presentEnergy = states.filter { !$0.energyAbsent }

        var morningEnergies: [Double] = []
        for state in presentEnergy {
            let hour = calendar.component(.hour, from: state.timestamp)
            if (7...10).contains(hour) {
                morningEnergies.append(state.energy)
            }
        }

        guard !morningEnergies.isEmpty else { return nil }

        let meanMorningEnergy = morningEnergies.reduce(0, +) / Double(morningEnergies.count)
        let uncertainty = max(0.15, 0.5 - Double(morningEnergies.count) * 0.01)

        return (meanMorningEnergy, uncertainty)
    }

    // Focus depth: sustained concentration in long uninterrupted sessions.
    // C1: filters focusAbsent states; returns nil when no sustained focus runs exist.
    private func inferFocusDepth(states: [InferredState]) -> (Double, Double)? {
        let presentFocus = states.filter { !$0.focusAbsent }
        let focusValues = presentFocus.map { $0.focus }

        var sustainedRunLengths: [Int] = []
        var currentRun = 0

        for focus in focusValues {
            if focus >= 0.6 {
                currentRun += 1
            } else {
                if currentRun >= 3 { sustainedRunLengths.append(currentRun) }
                currentRun = 0
            }
        }
        if currentRun >= 3 { sustainedRunLengths.append(currentRun) }

        guard !sustainedRunLengths.isEmpty else { return nil }

        let meanRunLength = Double(sustainedRunLengths.reduce(0, +)) / Double(sustainedRunLengths.count)
        let normalised = min(1.0, meanRunLength / 6.0)
        let uncertainty = max(0.1, 0.4 - Double(sustainedRunLengths.count) * 0.05)

        return (normalised, uncertainty)
    }

    // Mood stability: low variance in present-measured mood across the window.
    // C1: filters moodAbsent states; returns nil when fewer than 3 present mood samples exist.
    private func inferMoodStability(states: [InferredState]) -> (Double, Double)? {
        let moods = states.filter { !$0.moodAbsent }.map { $0.mood }
        guard moods.count >= 3 else { return nil }

        let mean = moods.reduce(0, +) / Double(moods.count)
        let variance = moods.map { pow($0 - mean, 2) }.reduce(0, +) / Double(moods.count)
        let stddev = sqrt(variance)

        let stability = 1.0 - min(1.0, stddev / 0.25)
        let uncertainty = max(0.1, 0.35 - Double(states.count) * 0.003)

        return (stability, uncertainty)
    }

    // MARK: - Upsert

    private func upsertTrait(
        type: TraitType,
        value: Double,
        uncertainty: Double,
        sampleCount: Int,
        modelContext: ModelContext
    ) {
        let descriptor = FetchDescriptor<Trait>(
            predicate: #Predicate { trait in
                trait.traitType == type && trait.chapterId == nil
            }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            let blendWeight = 0.3
            existing.value = existing.value * (1 - blendWeight) + value * blendWeight
            existing.uncertainty = min(existing.uncertainty, uncertainty)
            existing.updatedAt = Date()
            existing.sampleCount = sampleCount
            existing.windowDays = windowDays
        } else {
            let trait = Trait(
                traitType: type,
                value: value,
                uncertainty: uncertainty,
                windowDays: windowDays,
                sampleCount: sampleCount
            )
            modelContext.insert(trait)
        }
    }
}
