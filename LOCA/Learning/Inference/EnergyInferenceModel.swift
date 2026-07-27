//
//  EnergyInferenceModel.swift
//  LOCA
//
//  Energy inference model
//  Infers physical/mental vigor from sleep, HRV, steps, time-of-day
//

import Foundation

class EnergyInferenceModel {
    private var sleepWeight: Double = 0.4
    private var timeOfDayWeight: Double = 0.2
    private var stepsWeight: Double = 0.15
    private var hrvWeight: Double = 0.15
    private var loggedEnergyWeight: Double = 0.1

    private var circadianBaseline: [Int: Double] = [:]
    private var sleepTargetHours: Double = 8.0

    init() {
        initializeCircadianBaseline()
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
        var energyComponents: [Double] = []
        var hasRealEvidence = false

        // Component 1: Sleep quality (previous night)
        if let sleepAggregate = aggregates[.sleep] {
            energyComponents.append(sleepAggregate.mean * sleepWeight)
            uncertaintyTerms.append(sleepAggregate.uncertainty * sleepWeight)
            hasRealEvidence = true
        } else {
            uncertaintyTerms.append(0.2)
        }

        // Component 2: Step count (activity in this hour)
        if let stepsAggregate = aggregates[.motionActivity] {
            energyComponents.append(stepsAggregate.mean * stepsWeight)
            uncertaintyTerms.append(stepsAggregate.uncertainty * stepsWeight)
            hasRealEvidence = true
        } else {
            uncertaintyTerms.append(0.1 * stepsWeight)
        }

        // Component 3: Heart rate variability (arousal level)
        if let hrvAggregate = aggregates[.heartRateVariability] {
            energyComponents.append(hrvAggregate.mean * hrvWeight)
            uncertaintyTerms.append(hrvAggregate.uncertainty * hrvWeight)
            hasRealEvidence = true
        } else {
            uncertaintyTerms.append(0.15 * hrvWeight)
        }

        // Component 4: Explicit logged energy (ground truth)
        if let loggedSignal = signals.first(where: { $0.source == .explicitLog }) {
            energyComponents.append(loggedSignal.value * loggedEnergyWeight)
            uncertaintyTerms.append(loggedSignal.uncertainty * loggedEnergyWeight)
            hasRealEvidence = true
        } else {
            uncertaintyTerms.append(0.3 * loggedEnergyWeight)
        }

        // C1.1: Without real evidence, circadian alone is a prior — not a measurement.
        guard hasRealEvidence else {
            return .absent(uncertainty: 1.0)
        }

        // Circadian rhythm is valid context when real evidence exists.
        let circadianScore = circadianRhythm(hour: hour)
        energyComponents.append(circadianScore * timeOfDayWeight)
        uncertaintyTerms.append(0.08 * timeOfDayWeight)

        let energy = energyComponents.reduce(0, +)
        let baseUncertainty = sqrt(
            uncertaintyTerms.map { pow($0, 2) }.reduce(0, +)
        )

        return .measured(
            value: min(1.0, max(0, energy)),
            uncertainty: min(1.0, baseUncertainty)
        )
    }

    // MARK: - Circadian Rhythm

    private func circadianRhythm(hour: Int) -> Double {
        guard let baseline = circadianBaseline[hour] else {
            return defaultCircadianRhythm(hour: hour)
        }
        return baseline
    }

    private func defaultCircadianRhythm(hour: Int) -> Double {
        switch hour {
        case 0...3: return 0.2     // 12 AM - 3 AM: very low
        case 4...6: return 0.25    // 4 AM - 6 AM: recovering
        case 7...8: return 0.4     // 7 AM - 8 AM: wake effect, still low
        case 9...11: return 0.75   // 9 AM - 11 AM: morning peak
        case 12: return 0.65       // 12 PM: lunch dip begins
        case 13...14: return 0.6   // 1 PM - 2 PM: post-lunch low
        case 15...16: return 0.75  // 3 PM - 4 PM: afternoon peak
        case 17...18: return 0.7   // 5 PM - 6 PM: holding
        case 19...21: return 0.5   // 7 PM - 9 PM: evening decline
        case 22...23: return 0.35  // 10 PM - 11 PM: sleep prep
        default: return 0.5
        }
    }

    private func initializeCircadianBaseline() {
        for hour in 0..<24 {
            circadianBaseline[hour] = nil  // Will learn from user data
        }
    }

    // MARK: - Personalization

    func updateCircadianRhythm(hour: Int, observedEnergy: Double) {
        circadianBaseline[hour] = observedEnergy
    }

    func updateWeights(
        sleepWeight: Double,
        timeOfDayWeight: Double,
        stepsWeight: Double,
        hrvWeight: Double,
        loggedWeight: Double
    ) {
        let total = sleepWeight + timeOfDayWeight + stepsWeight + hrvWeight + loggedWeight
        self.sleepWeight = sleepWeight / total
        self.timeOfDayWeight = timeOfDayWeight / total
        self.stepsWeight = stepsWeight / total
        self.hrvWeight = hrvWeight / total
        self.loggedEnergyWeight = loggedWeight / total
    }
}
