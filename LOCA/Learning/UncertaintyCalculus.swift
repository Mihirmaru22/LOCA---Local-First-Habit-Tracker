//
//  UncertaintyCalculus.swift
//  LOCA
//
//  C5 Honest Synthesis — Single source of truth for uncertainty propagation.
//
//  Five rules govern how uncertainty flows through synthesis layers.
//  Core invariant: "A synthesized claim is never more certain than the evidence
//  beneath it." Operationally: no rule may produce an uncertainty BELOW the
//  minimum uncertainty of its inputs (equivalently, a confidence ABOVE the most
//  confident input). Every rule below is written so that
//      output.uncertainty >= min(input uncertainties)
//  which is the machine-checkable form of the certainty ceiling.
//

import Foundation

// MARK: - Rule A: Aggregate (Composite to Mean)

/// Combine measurements into a single estimate.
/// Used when: multiple states contribute to a pattern, or multiple patterns to a narrative.
///
/// Certainty ceiling: the aggregate is never more certain than its most-certain
/// input. We deliberately do NOT apply a √N standard-error reduction here —
/// synthesis must not manufacture certainty out of mere repetition. The measurement
/// component is the RMS of input uncertainties (>= min input), and dispersion of
/// the values can only ADD uncertainty, never remove it.
func aggregateUncertainty(
    values: [Double],
    uncertainties: [Double]
) -> (mean: Double, uncertainty: Double) {
    guard !values.isEmpty else {
        return (mean: 0.0, uncertainty: 1.0)
    }

    let mean = values.reduce(0, +) / Double(values.count)

    // Measurement component: RMS of input uncertainties. RMS >= min(uncertainties),
    // so this alone already satisfies the certainty ceiling.
    let measurementVariance = uncertainties.map { $0 * $0 }.reduce(0, +) / Double(uncertainties.count)
    let measurementU = sqrt(measurementVariance)

    // Dispersion component: how spread the values are around the mean. Spread can
    // only widen the aggregate's uncertainty; it is added in quadrature.
    let spreadVariance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
    let dispersionU = sqrt(spreadVariance)

    let combined = sqrt(measurementU * measurementU + dispersionU * dispersionU)
    let uncertainty = max(0.01, min(1.0, combined))

    return (mean: mean, uncertainty: uncertainty)
}

// MARK: - Rule B: Difference (Effect Size to Confidence)

/// Convert an effect magnitude and its component uncertainties into confidence.
/// Used when: comparing two groups (with/without habit, in/out chapter).
///
/// Confidence measures how far the effect stands clear of the combined noise floor.
/// If the effect does not exceed the noise floor, it is not detectable → confidence 0.
/// As signal-to-noise rises, confidence approaches (but never reaches) 1.0.
func differenceConfidence(
    delta: Double,
    uncertaintyA: Double,
    uncertaintyB: Double
) -> Double {
    let noiseFloor = sqrt(uncertaintyA * uncertaintyA + uncertaintyB * uncertaintyB)

    // Effect within the noise floor is not distinguishable from zero.
    guard abs(delta) > noiseFloor else { return 0.0 }

    let ratio = abs(delta) / max(0.01, noiseFloor)
    let confidence = min(1.0, ratio / (ratio + 1.0))
    return confidence
}

// MARK: - Rule C: Temporal Blend (Persistence with Decay)

/// Blend a running estimate with new evidence over time.
/// Used when: a trait's or a person's estimate is updated incrementally.
///
/// Certainty ceiling: a blend of two estimates must NEVER be more certain than its
/// most-certain input. The uncertainty blend is therefore a CONVEX combination
/// (a weighted average), which always lands in [min(u), max(u)] — never below the
/// floor. This is the fix for the previous quadrature form
///     sqrt((1-α)²·u_old² + α²·u_new²)
/// which drove the blended uncertainty BELOW both inputs (manufacturing certainty)
/// and, iterated weekly, collapsed uncertainty toward zero regardless of evidence.
func temporalBlend(
    existing: (value: Double, uncertainty: Double),
    new: (value: Double, uncertainty: Double),
    decayFactor alpha: Double  // 0.0 = keep existing, 1.0 = adopt new
) -> (value: Double, uncertainty: Double) {
    guard alpha >= 0.0 && alpha <= 1.0 else {
        return existing
    }

    let blendedValue = (1.0 - alpha) * existing.value + alpha * new.value

    // Convex (weighted-average) blend of uncertainty: always in [min, max] of inputs.
    let convexUncertainty = (1.0 - alpha) * existing.uncertainty + alpha * new.uncertainty

    // Certainty-ceiling floor: never more certain than the most-certain input.
    // (Convex blend already satisfies this; the floor is a defensive guarantee that
    // survives any future change to the blend weighting.)
    let floor = min(existing.uncertainty, new.uncertainty)
    let ceiledUncertainty = max(floor, convexUncertainty)

    return (
        value: max(0.0, min(1.0, blendedValue)),
        uncertainty: max(0.01, min(1.0, ceiledUncertainty))
    )
}

// MARK: - Rule D: Conjunction (Weakest-Link Confidence)

/// Combine the confidence of multiple contributing components (patterns, traits).
/// Used when: a narrative arc/thread depends on several patterns.
///
/// Confidence of a conjunction is the minimum (weakest-link): an arc is only as
/// strong as its weakest contributor. This can never exceed any single input.
func conjunctionConfidence(componentConfidences: [Double]) -> Double {
    guard !componentConfidences.isEmpty else { return 0.0 }
    return componentConfidences.min() ?? 0.0
}

// MARK: - Rule E: Feedback Clamp (Resonance Bounded by Evidence)

/// Fold user resonance into a confidence, under the strict certainty ceiling.
/// Used when: the user affirms or dismisses a pattern/arc.
///
/// Under the invariant "never more certain than the evidence beneath it," user
/// affirmation is NOT permitted to lift a claim above what its underlying evidence
/// supports — corroboration cannot manufacture statistical certainty. So positive
/// resonance is clamped at the evidence ceiling (it can raise confidence toward,
/// but not beyond, the evidence value), while negative resonance (dismissal) lowers
/// confidence freely. This is intentional: the positive branch is bounded by design,
/// not by accident.
func feedbackClamp(
    evidenceConfidence: Double,
    resonanceAdjustment: Double
) -> Double {
    if resonanceAdjustment > 0 {
        // Bounded by the evidence ceiling: affirmation cannot exceed the evidence.
        return min(evidenceConfidence, evidenceConfidence + resonanceAdjustment)
    } else {
        // Dismissal lowers freely, floored at zero.
        return max(0.0, evidenceConfidence + resonanceAdjustment)
    }
}

// MARK: - Certainty Ceiling Tests (Property-Based Verification)

/// P1: Monotonicity — lower input uncertainty yields lower (or equal) output uncertainty.
func test_P1_Monotonicity() -> Bool {
    let values = [0.5, 0.6, 0.5]
    let tight = aggregateUncertainty(values: values, uncertainties: [0.1, 0.1, 0.1])
    let loose = aggregateUncertainty(values: values, uncertainties: [0.2, 0.2, 0.2])
    return tight.uncertainty < loose.uncertainty
}

/// P2 (Aggregate): output uncertainty is never below the most-certain input
/// (the machine-checkable certainty ceiling).
func test_P2_CeilingPerRule_Aggregate() -> Bool {
    let uncertainties = [0.05, 0.15]
    let result = aggregateUncertainty(values: [0.5, 0.7], uncertainties: uncertainties)
    let floor = uncertainties.min() ?? 0.0
    return result.uncertainty >= floor - 1e-9 && result.uncertainty <= 1.0
}

/// P2 (Difference): confidence stays within [0, 1].
func test_P2_CeilingPerRule_Difference() -> Bool {
    let confidence = differenceConfidence(delta: 0.2, uncertaintyA: 0.15, uncertaintyB: 0.15)
    return confidence >= 0.0 && confidence <= 1.0
}

/// P2 (Temporal Blend): the blend is never more certain than its most-certain input
/// and never more uncertain than its least-certain input. This is the regression
/// guard for the Rule C ceiling fix.
func test_P2_CeilingPerRule_TemporalBlend() -> Bool {
    let existing = (value: 0.5, uncertainty: 0.2)
    let new = (value: 0.6, uncertainty: 0.2)
    let result = temporalBlend(existing: existing, new: new, decayFactor: 0.3)
    let lo = min(existing.uncertainty, new.uncertainty)
    let hi = max(existing.uncertainty, new.uncertainty)
    // Two equally-uncertain inputs must blend to the SAME uncertainty — not below it.
    return result.uncertainty >= lo - 1e-9 && result.uncertainty <= hi + 1e-9
}

/// P2 (Conjunction): conjunction equals the minimum component.
func test_P2_CeilingPerRule_Conjunction() -> Bool {
    return abs(conjunctionConfidence(componentConfidences: [0.8, 0.6, 0.9]) - 0.6) < 1e-9
}

/// P2 (Feedback Clamp): positive resonance cannot exceed the evidence ceiling.
func test_P2_CeilingPerRule_FeedbackClamp() -> Bool {
    let clamped = feedbackClamp(evidenceConfidence: 0.5, resonanceAdjustment: 0.3)
    return clamped <= 0.5 + 1e-9
}

/// P3: Absence Handling — an absent input (uncertainty 1.0) keeps the aggregate uncertain.
func test_P3_AbsenceHandling() -> Bool {
    let result = aggregateUncertainty(values: [0.0], uncertainties: [1.0])
    return result.uncertainty > 0.8
}

/// P4: End-to-End Laundering — sparse, high-uncertainty inputs cannot yield high confidence.
func test_P4_LaunderingTest() -> Bool {
    let agg = aggregateUncertainty(values: [0.3, 0.5], uncertainties: [0.3, 0.3])
    let confidence = differenceConfidence(delta: 0.1, uncertaintyA: agg.uncertainty, uncertaintyB: agg.uncertainty)
    return confidence < 0.5
}

/// P6: Feedback Non-Inflation — feedback alone cannot raise confidence above evidence.
func test_P6_FeedbackNonInflation() -> Bool {
    return feedbackClamp(evidenceConfidence: 0.4, resonanceAdjustment: 0.5) <= 0.4 + 1e-9
}

/// P6b: Rule C Non-Inflation over iteration — repeatedly blending equally-uncertain
/// evidence must not drive uncertainty toward zero. Regression guard for the old
/// quadrature collapse.
func test_P6b_TemporalBlendDoesNotCollapse() -> Bool {
    var u = 0.3
    for _ in 0..<20 {
        u = temporalBlend(existing: (0.5, u), new: (0.5, 0.3), decayFactor: 0.3).uncertainty
    }
    // With every input at 0.3, uncertainty must stay at 0.3 — never collapse below it.
    return u >= 0.3 - 1e-9
}

/// P7: No Hardcoded Confidence — a rule's output depends on its inputs.
func test_P7_NoHardcodedConfidence() -> Bool {
    let a = differenceConfidence(delta: 0.15, uncertaintyA: 0.1, uncertaintyB: 0.1)
    let b = differenceConfidence(delta: 0.25, uncertaintyA: 0.1, uncertaintyB: 0.1)
    return a != b
}

// MARK: - Run All Property Tests

func runUncertaintyCalculusTests() -> [String: Bool] {
    return [
        "P1_Monotonicity": test_P1_Monotonicity(),
        "P2_Aggregate": test_P2_CeilingPerRule_Aggregate(),
        "P2_Difference": test_P2_CeilingPerRule_Difference(),
        "P2_TemporalBlend": test_P2_CeilingPerRule_TemporalBlend(),
        "P2_Conjunction": test_P2_CeilingPerRule_Conjunction(),
        "P2_FeedbackClamp": test_P2_CeilingPerRule_FeedbackClamp(),
        "P3_AbsenceHandling": test_P3_AbsenceHandling(),
        "P4_LaunderingTest": test_P4_LaunderingTest(),
        "P6_FeedbackNonInflation": test_P6_FeedbackNonInflation(),
        "P6b_TemporalBlendDoesNotCollapse": test_P6b_TemporalBlendDoesNotCollapse(),
        "P7_NoHardcodedConfidence": test_P7_NoHardcodedConfidence(),
    ]
}
