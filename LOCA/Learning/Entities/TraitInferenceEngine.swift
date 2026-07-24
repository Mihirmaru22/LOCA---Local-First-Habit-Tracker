//
//  TraitInferenceEngine.swift
//  LOCA
//
//  Phase 5 — Trait inference from long-horizon state patterns
//  Traits are inferred from rolling 30-day windows, updated weekly
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
            logger.debug("Insufficient data for trait inference (\(states.count) samples)")
            return
        }

        for traitType in TraitType.allCases {
            let inferred = inferTrait(traitType: traitType, states: states)
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

    // MARK: - Per-Trait Inference

    private func inferTrait(
        traitType: TraitType,
        states: [InferredState]
    ) -> (value: Double, uncertainty: Double) {
        switch traitType {
        case .resilience:      return inferResilience(states: states)
        case .consistency:     return inferConsistency(states: states)
        case .socialDrive:     return inferSocialDrive(states: states)
        case .activityDrive:   return inferActivityDrive(states: states)
        case .focusDepth:      return inferFocusDepth(states: states)
        case .moodStability:   return inferMoodStability(states: states)
        }
    }

    // Resilience: speed of stress recovery after spikes
    // High resilience = stress spikes drop quickly back to baseline
    private func inferResilience(states: [InferredState]) -> (Double, Double) {
        var recoveryRates: [Double] = []

        for i in 1..<states.count {
            let prev = states[i - 1]
            let curr = states[i]

            // Detect a stress spike followed by recovery
            if prev.stress > 0.65 && curr.stress < prev.stress {
                let recovery = prev.stress - curr.stress
                recoveryRates.append(recovery)
            }
        }

        guard !recoveryRates.isEmpty else {
            return (0.5, 0.6)  // No spikes observed; uncertain
        }

        let meanRecovery = recoveryRates.reduce(0, +) / Double(recoveryRates.count)
        let normalised = min(1.0, meanRecovery / 0.3)  // 0.3 drop per hour = high resilience
        let uncertainty = max(0.15, 0.5 - Double(recoveryRates.count) * 0.03)

        return (normalised, uncertainty)
    }

    // Consistency: how regular daily patterns are across weeks
    // High consistency = same activities at same times day after day
    private func inferConsistency(states: [InferredState]) -> (Double, Double) {
        let calendar = Calendar.current

        // Group states by hour of day; measure variance within each hour bucket
        var hourGroups: [Int: [Double]] = [:]
        for state in states {
            let hour = calendar.component(.hour, from: state.timestamp)
            hourGroups[hour, default: []].append(state.energy)
        }

        var hourVariances: [Double] = []
        for (_, values) in hourGroups where values.count >= 3 {
            let mean = values.reduce(0, +) / Double(values.count)
            let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
            hourVariances.append(variance)
        }

        guard !hourVariances.isEmpty else { return (0.5, 0.5) }

        let meanVariance = hourVariances.reduce(0, +) / Double(hourVariances.count)
        let consistency = 1.0 - min(1.0, meanVariance / 0.1)  // Low variance = high consistency
        let uncertainty = max(0.1, 0.4 - Double(hourVariances.count) * 0.01)

        return (consistency, uncertainty)
    }

    // Social drive: tendency toward calendar / social engagement signals
    private func inferSocialDrive(states: [InferredState]) -> (Double, Double) {
        // Proxy: mood lifts correlating with social signals
        // Here we use mood variance — high mood variation often tracks social exposure
        let moodValues = states.map { $0.mood }
        let moodMean = moodValues.reduce(0, +) / Double(moodValues.count)

        // Count high-mood periods (proxy for social lift)
        let highMoodCount = moodValues.filter { $0 > moodMean + 0.1 }.count
        let socialDrive = Double(highMoodCount) / Double(moodValues.count)

        let uncertainty = max(0.2, 0.5 - Double(states.count) * 0.005)
        return (min(1.0, socialDrive * 2.0), uncertainty)
    }

    // Activity drive: tendency toward physical activity
    private func inferActivityDrive(states: [InferredState]) -> (Double, Double) {
        // Energy pattern: consistently high morning energy = active tendency
        let calendar = Calendar.current

        var morningEnergies: [Double] = []
        for state in states {
            let hour = calendar.component(.hour, from: state.timestamp)
            if (7...10).contains(hour) {
                morningEnergies.append(state.energy)
            }
        }

        guard !morningEnergies.isEmpty else { return (0.5, 0.6) }

        let meanMorningEnergy = morningEnergies.reduce(0, +) / Double(morningEnergies.count)
        let uncertainty = max(0.15, 0.5 - Double(morningEnergies.count) * 0.01)

        return (meanMorningEnergy, uncertainty)
    }

    // Focus depth: sustained concentration in long uninterrupted sessions
    private func inferFocusDepth(states: [InferredState]) -> (Double, Double) {
        let focusValues = states.map { $0.focus }

        // Measure sustained runs of high focus (≥3 consecutive hours above 0.6)
        var sustainedRunLengths: [Int] = []
        var currentRun = 0

        for focus in focusValues {
            if focus >= 0.6 {
                currentRun += 1
            } else {
                if currentRun >= 3 {
                    sustainedRunLengths.append(currentRun)
                }
                currentRun = 0
            }
        }
        if currentRun >= 3 { sustainedRunLengths.append(currentRun) }

        guard !sustainedRunLengths.isEmpty else {
            return (0.3, 0.5)  // Rarely sustains focus
        }

        let meanRunLength = Double(sustainedRunLengths.reduce(0, +)) / Double(sustainedRunLengths.count)
        let normalised = min(1.0, meanRunLength / 6.0)  // 6-hour run = high focus depth
        let uncertainty = max(0.1, 0.4 - Double(sustainedRunLengths.count) * 0.05)

        return (normalised, uncertainty)
    }

    // Mood stability: low variance in mood across the window
    private func inferMoodStability(states: [InferredState]) -> (Double, Double) {
        let moods = states.map { $0.mood }
        let mean = moods.reduce(0, +) / Double(moods.count)
        let variance = moods.map { pow($0 - mean, 2) }.reduce(0, +) / Double(moods.count)
        let stddev = sqrt(variance)

        let stability = 1.0 - min(1.0, stddev / 0.25)  // stddev > 0.25 = unstable
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
            // Bayesian-style update: blend old estimate with new
            let blendWeight = 0.3  // Weight of new observation
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
