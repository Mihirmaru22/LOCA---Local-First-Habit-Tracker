//
//  AnomalyDetector.swift
//  LOCA
//
//  Stage 1 of event detection: Weekly anomaly detection
//  Compares each week to rolling 8-week baseline.
//
//  C6A (honest regimes): the deviation test is uncertainty-aware — a shift is only
//  anomalous when it exceeds the COMBINED noise floor (baseline spread + the week's
//  own measurement uncertainty). Absent metrics contribute nothing (their weight is
//  redistributed), and a week whose data coverage is below the density floor can
//  never be flagged anomalous. No event may be asserted from absent or thin data.
//

import Foundation

class AnomalyDetector {
    private let baselineWindowWeeks = 8
    private let anomalyThreshold = 2.0     // combined-noise z-score
    // C6A: a week covering less than half its expected state slots is too thin to
    // assert an event from — it is suppressed regardless of apparent deviation.
    private let densityFloor = 0.5

    // MARK: - Main Detection

    func detectAnomalies(regimes: [WeeklyRegime]) -> [WeeklyRegime] {
        guard regimes.count > baselineWindowWeeks else { return [] }

        var anomalousWeeks: [WeeklyRegime] = []

        for i in baselineWindowWeeks..<regimes.count {
            let currentWeek = regimes[i]

            // C6A absence/thinness gate: a gap-heavy week cannot assert an event.
            guard currentWeek.dataDensity >= densityFloor else { continue }

            let baselineWeeks = Array(regimes[max(0, i - baselineWindowWeeks)..<i])

            let anomalyScore = computeAnomalyScore(
                week: currentWeek,
                baseline: baselineWeeks
            )

            if anomalyScore > anomalyThreshold {
                let anomalousWeek = currentWeek
                anomalousWeek.anomalyScore = anomalyScore
                anomalousWeeks.append(anomalousWeek)
            }
        }

        return anomalousWeeks
    }

    // MARK: - Anomaly Scoring

    /// One metric's contribution to the anomaly score.
    private struct MetricContribution {
        let weight: Double
        let value: Double
        let weekUncertainty: Double    // this week's measurement uncertainty for the metric
        let absent: Bool               // true when the week has no present data for it
        let baseline: [Double]         // baseline means from weeks where the metric was present
    }

    private func computeAnomalyScore(
        week: WeeklyRegime,
        baseline: [WeeklyRegime]
    ) -> Double {
        // Core dimensions carry per-metric uncertainty + absence (C5/C6). The two
        // pattern metrics (schedule, location) have no uncertainty model in C6A, so
        // they use a zero week-uncertainty and are never absent.
        let contributions: [MetricContribution] = [
            MetricContribution(
                weight: 0.30, value: week.energyMean, weekUncertainty: week.energyUncertainty,
                absent: week.energyAbsent,
                baseline: baseline.filter { !$0.energyAbsent }.map { $0.energyMean }
            ),
            MetricContribution(
                weight: 0.20, value: week.stressMean, weekUncertainty: week.stressUncertainty,
                absent: week.stressAbsent,
                baseline: baseline.filter { !$0.stressAbsent }.map { $0.stressMean }
            ),
            MetricContribution(
                weight: 0.15, value: week.focusMean, weekUncertainty: week.focusUncertainty,
                absent: week.focusAbsent,
                baseline: baseline.filter { !$0.focusAbsent }.map { $0.focusMean }
            ),
            MetricContribution(
                weight: 0.15, value: week.scheduleRegularity, weekUncertainty: 0.0,
                absent: false,
                baseline: baseline.map { $0.scheduleRegularity }
            ),
            MetricContribution(
                weight: 0.20, value: week.locationDiversity, weekUncertainty: 0.0,
                absent: false,
                baseline: baseline.map { $0.locationDiversity }
            ),
        ]

        var weightedSum = 0.0
        var contributingWeight = 0.0

        for c in contributions {
            // Skip metrics with no present data this week or an empty baseline — their
            // weight is redistributed across the metrics that actually contributed.
            guard !c.absent, !c.baseline.isEmpty else { continue }
            let dev = combinedNoiseZScore(value: c.value, baseline: c.baseline, weekUncertainty: c.weekUncertainty)
            weightedSum += c.weight * dev
            contributingWeight += c.weight
        }

        // No contributing metric → no anomaly (cannot exceed threshold).
        guard contributingWeight > 0 else { return 0.0 }
        return weightedSum / contributingWeight
    }

    /// Deviation of `value` from its baseline, measured in units of the COMBINED
    /// noise floor: the baseline spread and this week's own measurement uncertainty
    /// added in quadrature. A shift smaller than that combined noise scores near 0,
    /// so a spike driven by thin/uncertain data is not mistaken for a real anomaly.
    private func combinedNoiseZScore(value: Double, baseline: [Double], weekUncertainty: Double) -> Double {
        guard !baseline.isEmpty else { return 0 }

        let mean = baseline.reduce(0, +) / Double(baseline.count)
        let variance = baseline.map { pow($0 - mean, 2) }.reduce(0, +) / Double(baseline.count)
        let baselineStddev = sqrt(variance)
        let noiseFloor = sqrt(max(0.0001, baselineStddev * baselineStddev + weekUncertainty * weekUncertainty))

        return abs(value - mean) / noiseFloor
    }
}
