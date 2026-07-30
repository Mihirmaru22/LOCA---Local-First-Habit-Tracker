//
//  RegimePersistenceChecker.swift
//  LOCA
//
//  Stage 2 of event detection: Regime persistence confirmation
//  Checks: does the anomaly persist for ≥2 weeks afterward?
//  A one-off spike isn't an event; sustained divergence is.
//

import Foundation

class RegimePersistenceChecker {
    private let persistenceWindowWeeks = 4
    // C6B fix: the threshold is compared against computeRegimeDistance, which since
    // C6A returns an uncertainty-discounted MEAN distance in [0,1] (small for real
    // shifts) — NOT a z-score. The previous value 1.5 was unsatisfiable (mean ≤ 1.0),
    // so persistence never confirmed and the whole pipeline emitted no events. 0.08
    // sits in the discounted-distance range: a sustained shift clears it, noise does not.
    private let persistenceThreshold = 0.08
    private let correlationThreshold = 0.5  // max correlation before-to-after

    /// Raw discounted persistence distance from the last confirmed check (evidence).
    /// The engine converts this to a confidence via persistenceConfidence (C6B).
    var lastPersistenceScore = 0.0

    // MARK: - Main Check

    func checkPersistence(
        anomalousWeek: WeeklyRegime,
        subsequentWeeks: [WeeklyRegime],
        states: [InferredState]
    ) -> Date? {
        guard subsequentWeeks.count >= persistenceWindowWeeks else { return nil }

        // Check 1: Do subsequent weeks remain anomalous?
        let subsequentScores = subsequentWeeks.prefix(persistenceWindowWeeks).map { week in
            computeRegimeDistance(from: anomalousWeek, to: week)
        }

        let meanSubsequentScore = subsequentScores.reduce(0, +) / Double(subsequentScores.count)

        guard meanSubsequentScore > persistenceThreshold else { return nil }

        // Check 2: Is the post-shift pattern different from pre-shift?
        let correlation = computeCorrelation(
            beforeWeek: anomalousWeek,
            afterWeeks: Array(subsequentWeeks.prefix(persistenceWindowWeeks))
        )

        guard correlation < correlationThreshold else { return nil }

        // Passed both checks: regime shift is real. Store the raw discounted distance
        // as evidence; the engine derives a [0,1] confidence from it (C6B).
        lastPersistenceScore = meanSubsequentScore

        // Estimate event timestamp: Sunday of anomalous week
        let calendar = Calendar.current
        let eventDate = calendar.date(from: calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear],
            from: anomalousWeek.weekStart
        )) ?? anomalousWeek.weekStart

        return eventDate
    }

    // MARK: - Regime Distance (uncertainty-discounted)

    /// C6A: distance between two regimes, counting only the portion of each metric's
    /// difference that exceeds the two regimes' COMBINED measurement uncertainty. A
    /// difference within the combined noise contributes 0, so a "persistent" shift
    /// built on sparse/uncertain weeks does not accumulate distance and cannot
    /// confirm. Metrics absent in either regime are skipped (their fabricated 0.0
    /// mean must not register as distance); the result averages over the metrics
    /// that were present in both.
    // internal (not private) so C6A property tests can exercise the discounted
    // distance directly via @testable import.
    func computeRegimeDistance(
        from baselineWeek: WeeklyRegime,
        to comparisonWeek: WeeklyRegime
    ) -> Double {
        var sum = 0.0
        var contributing = 0

        func accumulate(
            _ a: Double, _ b: Double,
            _ uA: Double, _ uB: Double,
            _ aAbsent: Bool, _ bAbsent: Bool
        ) {
            guard !aAbsent, !bAbsent else { return }
            let noiseFloor = sqrt(uA * uA + uB * uB)
            sum += max(0.0, abs(a - b) - noiseFloor)
            contributing += 1
        }

        accumulate(baselineWeek.energyMean, comparisonWeek.energyMean,
                   baselineWeek.energyUncertainty, comparisonWeek.energyUncertainty,
                   baselineWeek.energyAbsent, comparisonWeek.energyAbsent)
        accumulate(baselineWeek.stressMean, comparisonWeek.stressMean,
                   baselineWeek.stressUncertainty, comparisonWeek.stressUncertainty,
                   baselineWeek.stressAbsent, comparisonWeek.stressAbsent)
        accumulate(baselineWeek.focusMean, comparisonWeek.focusMean,
                   baselineWeek.focusUncertainty, comparisonWeek.focusUncertainty,
                   baselineWeek.focusAbsent, comparisonWeek.focusAbsent)
        // scheduleRegularity has no uncertainty model in C6A; treat as certain.
        accumulate(baselineWeek.scheduleRegularity, comparisonWeek.scheduleRegularity,
                   0.0, 0.0, false, false)

        guard contributing > 0 else { return 0.0 }
        return sum / Double(contributing)
    }

    // MARK: - Correlation (Before vs. After)

    private func computeCorrelation(
        beforeWeek: WeeklyRegime,
        afterWeeks: [WeeklyRegime]
    ) -> Double {
        guard !afterWeeks.isEmpty else { return 0 }

        let beforeVector = regimeVector(beforeWeek)
        var afterVectors: [[Double]] = []

        for week in afterWeeks {
            afterVectors.append(regimeVector(week))
        }

        var correlations: [Double] = []
        for afterVector in afterVectors {
            let corr = pearsonCorrelation(beforeVector, afterVector)
            correlations.append(corr)
        }

        return correlations.reduce(0, +) / Double(correlations.count)
    }

    private func regimeVector(_ regime: WeeklyRegime) -> [Double] {
        return [
            regime.energyMean,
            regime.stressMean,
            regime.focusMean,
            regime.moodMean,
            regime.scheduleRegularity,
            regime.locationDiversity,
            regime.socialEngagement,
            regime.activityLevel
        ]
    }

    private func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count, x.count > 0 else { return 0 }

        let meanX = x.reduce(0, +) / Double(x.count)
        let meanY = y.reduce(0, +) / Double(y.count)

        let numerator = zip(x, y).map { ($0 - meanX) * ($1 - meanY) }.reduce(0, +)
        let denominator = sqrt(
            x.map { pow($0 - meanX, 2) }.reduce(0, +) *
            y.map { pow($0 - meanY, 2) }.reduce(0, +)
        )

        guard denominator > 0 else { return 0 }
        return numerator / denominator
    }
}
