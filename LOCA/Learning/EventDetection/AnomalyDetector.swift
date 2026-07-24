//
//  AnomalyDetector.swift
//  LOCA
//
//  Stage 1 of event detection: Weekly anomaly detection
//  Compares each week to rolling 8-week baseline
//

import Foundation

class AnomalyDetector {
    private let baselineWindowWeeks = 8
    private let anomalyThreshold = 2.0  // 2 standard deviations

    // MARK: - Main Detection

    func detectAnomalies(regimes: [WeeklyRegime]) -> [WeeklyRegime] {
        guard regimes.count > baselineWindowWeeks else { return [] }

        var anomalousWeeks: [WeeklyRegime] = []

        for i in baselineWindowWeeks..<regimes.count {
            let currentWeek = regimes[i]
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

    private func computeAnomalyScore(
        week: WeeklyRegime,
        baseline: [WeeklyRegime]
    ) -> Double {
        let energyDev = zScoreDev(value: week.energyMean, baseline: baseline.map { $0.energyMean })
        let stressDev = zScoreDev(value: week.stressMean, baseline: baseline.map { $0.stressMean })
        let focusDev = zScoreDev(value: week.focusMean, baseline: baseline.map { $0.focusMean })
        let scheduleDev = zScoreDev(value: week.scheduleRegularity, baseline: baseline.map { $0.scheduleRegularity })
        let locationDev = zScoreDev(value: week.locationDiversity, baseline: baseline.map { $0.locationDiversity })

        let score = (
            0.3 * energyDev +
            0.2 * stressDev +
            0.15 * focusDev +
            0.15 * scheduleDev +
            0.2 * locationDev
        )

        return score
    }

    private func zScoreDev(value: Double, baseline: [Double]) -> Double {
        guard baseline.count > 0 else { return 0 }

        let mean = baseline.reduce(0, +) / Double(baseline.count)
        let variance = baseline.map { pow($0 - mean, 2) }.reduce(0, +) / Double(baseline.count)
        let stddev = sqrt(max(0.01, variance))

        return abs(value - mean) / stddev
    }
}
