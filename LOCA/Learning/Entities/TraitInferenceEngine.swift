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
        var recoveryUncertainties: [Double] = []

        for i in 1..<present.count {
            let prev = present[i - 1]
            let curr = present[i]

            if prev.stress > 0.65 && curr.stress < prev.stress {
                recoveryRates.append(prev.stress - curr.stress)
                // Uncertainty of a difference: quadrature of the two measurements.
                recoveryUncertainties.append(
                    sqrt(prev.stressUncertainty * prev.stressUncertainty +
                         curr.stressUncertainty * curr.stressUncertainty)
                )
            }
        }

        guard !recoveryRates.isEmpty else { return nil }

        // Rule A: aggregate recovery magnitudes with their propagated uncertainties.
        let agg = aggregateUncertainty(values: recoveryRates, uncertainties: recoveryUncertainties)
        let normalised = min(1.0, agg.mean / 0.3)

        return (normalised, agg.uncertainty)
    }

    // Consistency: how regular daily energy patterns are across weeks.
    // C1: filters energyAbsent states; returns nil when no hour has ≥3 present samples.
    private func inferConsistency(states: [InferredState]) -> (Double, Double)? {
        let calendar = Calendar.current
        let present = states.filter { !$0.energyAbsent }

        var hourGroups: [Int: [Double]] = [:]
        var hourUncertainties: [Int: [Double]] = [:]
        for state in present {
            let hour = calendar.component(.hour, from: state.timestamp)
            hourGroups[hour, default: []].append(state.energy)
            hourUncertainties[hour, default: []].append(state.energyUncertainty)
        }

        var hourVariances: [Double] = []
        var hourUncertaintyReps: [Double] = []
        for (hour, values) in hourGroups where values.count >= 3 {
            // Rule A: aggregate this hour's energy readings; carry its uncertainty.
            let agg = aggregateUncertainty(values: values, uncertainties: hourUncertainties[hour] ?? [])
            let variance = values.map { pow($0 - agg.mean, 2) }.reduce(0, +) / Double(values.count)
            hourVariances.append(variance)
            hourUncertaintyReps.append(agg.uncertainty)
        }

        guard !hourVariances.isEmpty else { return nil }

        let meanVariance = hourVariances.reduce(0, +) / Double(hourVariances.count)
        let consistency = 1.0 - min(1.0, meanVariance / 0.1)
        // Rule A: aggregate the per-hour uncertainties into a trait-level uncertainty.
        let uncertainty = aggregateUncertainty(values: hourVariances, uncertainties: hourUncertaintyReps).uncertainty

        return (consistency, uncertainty)
    }

    // Social drive: tendency toward social engagement, proxied through mood lift.
    // C1: filters moodAbsent states; returns nil when no present mood measurements exist.
    private func inferSocialDrive(states: [InferredState]) -> (Double, Double)? {
        let present = states.filter { !$0.moodAbsent }
        let moodValues = present.map { $0.mood }
        guard !moodValues.isEmpty else { return nil }

        // Rule A: aggregate present mood measurements with their uncertainties.
        let agg = aggregateUncertainty(values: moodValues, uncertainties: present.map { $0.moodUncertainty })
        let highMoodCount = moodValues.filter { $0 > agg.mean + 0.1 }.count
        let socialDrive = Double(highMoodCount) / Double(moodValues.count)

        return (min(1.0, socialDrive * 2.0), agg.uncertainty)
    }

    // Activity drive: tendency toward physical activity, proxied by morning energy.
    // C1: filters energyAbsent states; returns nil when no morning energy samples exist.
    private func inferActivityDrive(states: [InferredState]) -> (Double, Double)? {
        let calendar = Calendar.current
        let presentEnergy = states.filter { !$0.energyAbsent }

        var morningEnergies: [Double] = []
        var morningUncertainties: [Double] = []
        for state in presentEnergy {
            let hour = calendar.component(.hour, from: state.timestamp)
            if (7...10).contains(hour) {
                morningEnergies.append(state.energy)
                morningUncertainties.append(state.energyUncertainty)
            }
        }

        guard !morningEnergies.isEmpty else { return nil }

        // Rule A: aggregate morning energy with propagated uncertainty.
        let agg = aggregateUncertainty(values: morningEnergies, uncertainties: morningUncertainties)
        return (agg.mean, agg.uncertainty)
    }

    // Focus depth: sustained concentration in long uninterrupted sessions.
    // C1: filters focusAbsent states; returns nil when no sustained focus runs exist.
    private func inferFocusDepth(states: [InferredState]) -> (Double, Double)? {
        let presentFocus = states.filter { !$0.focusAbsent }

        var sustainedRunLengths: [Double] = []
        var sustainedRunUncertainties: [Double] = []
        var currentRun = 0
        var currentRunUncertainties: [Double] = []

        func closeRun() {
            if currentRun >= 3 {
                sustainedRunLengths.append(Double(currentRun))
                sustainedRunUncertainties.append(
                    aggregateUncertainty(values: currentRunUncertainties, uncertainties: currentRunUncertainties).uncertainty
                )
            }
            currentRun = 0
            currentRunUncertainties.removeAll()
        }

        for state in presentFocus {
            if state.focus >= 0.6 {
                currentRun += 1
                currentRunUncertainties.append(state.focusUncertainty)
            } else {
                closeRun()
            }
        }
        closeRun()

        guard !sustainedRunLengths.isEmpty else { return nil }

        // Rule A: aggregate run lengths with their propagated uncertainties.
        let agg = aggregateUncertainty(values: sustainedRunLengths, uncertainties: sustainedRunUncertainties)
        let normalised = min(1.0, agg.mean / 6.0)

        return (normalised, agg.uncertainty)
    }

    // Mood stability: low variance in present-measured mood across the window.
    // C1: filters moodAbsent states; returns nil when fewer than 3 present mood samples exist.
    private func inferMoodStability(states: [InferredState]) -> (Double, Double)? {
        let present = states.filter { !$0.moodAbsent }
        let moods = present.map { $0.mood }
        guard moods.count >= 3 else { return nil }

        // Rule A: aggregate present moods with their uncertainties.
        let agg = aggregateUncertainty(values: moods, uncertainties: present.map { $0.moodUncertainty })
        let variance = moods.map { pow($0 - agg.mean, 2) }.reduce(0, +) / Double(moods.count)
        let stddev = sqrt(variance)

        let stability = 1.0 - min(1.0, stddev / 0.25)
        return (stability, agg.uncertainty)
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
            // Rule C: temporal blend of the running estimate with the new window.
            // Replaces the forbidden `min()` ratchet on uncertainty, which could only
            // shrink and so manufactured certainty over successive updates. The convex
            // blend keeps uncertainty within [min, max] of the two inputs.
            let blended = temporalBlend(
                existing: (value: existing.value, uncertainty: existing.uncertainty),
                new: (value: value, uncertainty: uncertainty),
                decayFactor: 0.3
            )
            existing.value = blended.value
            existing.uncertainty = blended.uncertainty
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
