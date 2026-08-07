//
//  PredictionConfidence.swift
//  LOCA
//
//  Phase 5.1 — False-positive budget.
//
//  Set the confidence threshold; a wrong insight is far costlier than silence.
//  Price the asymmetry: missed opportunity < false alarm.
//

import Foundation

/// Confidence model for intervention predictions (Phase 5.1).
///
/// Unlike reflections (Phase 4), interventions are *actionable requests*.
/// A wrong reflection is noise. A wrong intervention damages trust.
/// This asymmetry is priced into the confidence threshold.
struct PredictionConfidence {

    /// The predicted probability (0.0–1.0) that a relapse is imminent.
    let probability: Double

    /// How many data points support this prediction.
    /// Higher count = more reliable. Low count = high uncertainty.
    let dataPoints: Int

    /// The cost of a false positive (user gets wrong warning).
    /// Scale: 1.0 = neutral, 2.0 = twice as bad as missed opportunity.
    /// Interventions are intrusive; false positives are expensive.
    let falsePositiveCost: Double

    /// The optimal confidence threshold for this prediction type.
    /// Accounts for false-positive cost asymmetry.
    var recommendedThreshold: Double {
        // Base threshold: 80% (vs. 60% for reflections)
        // Increase further if false-positive cost is high
        let baseLine = 0.80
        let adjustedForCost = baseLine + (falsePositiveCost * 0.05)  // +5% per cost unit
        return min(adjustedForCost, 0.95)  // Cap at 95% (never 100%)
    }

    /// Whether this prediction is confident enough to trigger an intervention.
    var isActionable: Bool {
        // Require both high probability AND sufficient data
        return probability >= recommendedThreshold && dataPoints >= 15
    }

    /// Initialize a relapse-risk prediction.
    init(probability: Double, dataPoints: Int, falsePositiveCost: Double = 2.0) {
        self.probability = min(max(probability, 0.0), 1.0)
        self.dataPoints = max(dataPoints, 0)
        self.falsePositiveCost = max(falsePositiveCost, 1.0)
    }
}

/// Utility to compute the cost/benefit of an intervention (Phase 5.1).
struct InterventionCostBenefit {

    /// Probability the intervention helps (relapse actually happens).
    let helpfulProbability: Double

    /// Probability the intervention annoys (false alarm).
    let falseProbability: Double

    /// Expected value of intervening (helpful benefit - annoying cost).
    /// Positive = intervene. Negative = stay silent.
    var expectedValue: Double {
        let benefit = helpfulProbability * 10.0      // +10 for successful intervention
        let cost = falseProbability * 5.0             // -5 for false alarm
        return benefit - cost
    }

    /// Whether the intervention is worth sending.
    var shouldIntervene: Bool {
        return expectedValue > 2.0  // Require positive EV with safety margin
    }

    init(helpfulProbability: Double, falseProbability: Double) {
        self.helpfulProbability = max(0, min(1, helpfulProbability))
        self.falseProbability = max(0, min(1, 1.0 - helpfulProbability))
    }
}
