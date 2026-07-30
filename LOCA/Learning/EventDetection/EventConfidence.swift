//
//  EventConfidence.swift
//  LOCA
//
//  C6B (honest event confidence) — combine the three detection signals into one
//  calibrated confidence, via UncertaintyCalculus. An event's confidence is the
//  conjunction (weakest-link) of the evidence that it HAPPENED (anomaly strength ×
//  persistence) and the evidence for WHAT IT WAS (classification margin). No raw
//  magnitude is ever passed off as a probability.
//

import Foundation

/// Map an anomaly z-score (combined-noise units; flagged above ~2) to a [0,1]
/// confidence with a saturating curve. score=2 → 0.5, score=6 → 0.75; never reaches 1.
func anomalyConfidence(anomalyScore: Double) -> Double {
    let s = max(0.0, anomalyScore)
    return s / (s + 2.0)
}

/// Map an uncertainty-discounted persistence distance (C6A, in [0,1], small for real
/// shifts) to a [0,1] confidence with the same saturating shape. distance=0.1 → 0.5.
func persistenceConfidence(distance: Double) -> Double {
    let d = max(0.0, distance)
    return d / (d + 0.1)
}

/// Classification confidence from the RELATIVE margin between the best and
/// second-best event-type scores. A tie → ~0; a runaway winner → ~1. This replaces
/// using the winner's raw magnitude, and needs no hardcoded floor. When there is no
/// positive top score (no signal), confidence is 0.
func classificationConfidence(topScore: Double, secondScore: Double) -> Double {
    guard topScore > 0 else { return 0.0 }
    let margin = (topScore - max(0.0, secondScore)) / topScore
    return max(0.0, min(1.0, margin))
}

/// The event's overall confidence: weakest-link (Rule D) over the three signals.
/// A shift that is anomalous and persistent but ambiguously classified is only as
/// confident as its weakest leg — honest by construction.
func combinedEventConfidence(
    anomaly: Double,
    persistence: Double,
    classification: Double
) -> Double {
    conjunctionConfidence(componentConfidences: [anomaly, persistence, classification])
}
