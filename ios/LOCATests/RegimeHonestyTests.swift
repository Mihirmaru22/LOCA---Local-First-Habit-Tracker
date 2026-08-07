//
//  RegimeHonestyTests.swift
//  LOCATests
//
//  C6A (honest regimes) property tests. Each test isolates one clause of the
//  invariant: "A regime carries the uncertainty of the states beneath it; an
//  anomaly is credible only when the shift exceeds that uncertainty; and no event
//  may be asserted from absent or thin data."
//
//  PA1 Monotonicity      — higher week uncertainty suppresses an otherwise-detected shift.
//  PA2 Absence floor      — an all-absent (zero-density) week produces no event.
//  PA3 Within-noise       — a shift smaller than the combined noise is not detected.
//  PA4 No-regression      — a dense, low-uncertainty, large shift still detects.
//  PA5 Persistence honesty — within-noise differences accrue zero regime distance.
//  PA6 Absent ≠ zero      — an absent metric's 0.0 mean does not manufacture an anomaly.
//

import XCTest
@testable import LOCA

final class RegimeHonestyTests: XCTestCase {

    // MARK: - Builders

    /// A present, low-uncertainty, fully-covered week; override only what a test needs.
    private func week(
        _ index: Int,
        energy: Double = 0.5, energyU: Double = 0.05, energyAbsent: Bool = false,
        stress: Double = 0.4, stressU: Double = 0.05, stressAbsent: Bool = false,
        focus: Double = 0.5, focusU: Double = 0.05, focusAbsent: Bool = false,
        mood: Double = 0.6, moodU: Double = 0.05, moodAbsent: Bool = false,
        schedule: Double = 0.7, location: Double = 0.3,
        social: Double = 0.3, activity: Double = 0.5,
        density: Double = 1.0
    ) -> WeeklyRegime {
        let start = Date(timeIntervalSince1970: 0).addingTimeInterval(Double(index) * 7 * 86400)
        return WeeklyRegime(
            weekStart: start,
            energyMean: energy, energyStddev: 0.0,
            stressMean: stress, stressStddev: 0.0,
            focusMean: focus, focusStddev: 0.0,
            moodMean: mood, moodStddev: 0.0,
            scheduleRegularity: schedule,
            locationDiversity: location,
            socialEngagement: social,
            activityLevel: activity,
            energyUncertainty: energyU, stressUncertainty: stressU,
            focusUncertainty: focusU, moodUncertainty: moodU,
            energyAbsent: energyAbsent, stressAbsent: stressAbsent,
            focusAbsent: focusAbsent, moodAbsent: moodAbsent,
            dataDensity: density
        )
    }

    /// `count` identical stable weeks — a flat baseline with zero spread.
    private func stableBaseline(count: Int) -> [WeeklyRegime] {
        (0..<count).map { week($0) }
    }

    // MARK: - PA1 Monotonicity

    func test_PA1_HigherUncertaintySuppressesAnomaly() {
        let baseline = stableBaseline(count: 9)

        let lowU = week(9, energy: 0.9, energyU: 0.05)   // +0.4 shift, tight measurement
        let detectedLow = AnomalyDetector().detectAnomalies(regimes: baseline + [lowU])
        XCTAssertTrue(detectedLow.contains { $0 === lowU },
                      "a large shift measured tightly should be detected")

        let highU = week(9, energy: 0.9, energyU: 0.5)    // same shift, but very uncertain
        let detectedHigh = AnomalyDetector().detectAnomalies(regimes: baseline + [highU])
        XCTAssertFalse(detectedHigh.contains { $0 === highU },
                       "the same shift under high uncertainty must not be detected")
    }

    // MARK: - PA2 Absence floor (hard)

    func test_PA2_AllAbsentWeekProducesNoEvent() {
        let baseline = stableBaseline(count: 9)
        let absent = week(9,
                          energyAbsent: true, stressAbsent: true,
                          focusAbsent: true, moodAbsent: true,
                          density: 0.0)
        let detected = AnomalyDetector().detectAnomalies(regimes: baseline + [absent])
        XCTAssertFalse(detected.contains { $0 === absent },
                       "a zero-density, all-absent week can never be an anomaly")
    }

    // MARK: - PA3 Within-noise

    func test_PA3_WithinNoiseShiftNotDetected() {
        let baseline = stableBaseline(count: 9)
        let small = week(9, energy: 0.55, energyU: 0.1)   // +0.05 shift, noise 0.1
        let detected = AnomalyDetector().detectAnomalies(regimes: baseline + [small])
        XCTAssertFalse(detected.contains { $0 === small },
                       "a shift smaller than the combined noise is not an anomaly")
    }

    // MARK: - PA4 No-regression on solid data

    func test_PA4_DenseLargeShiftStillDetected() {
        let baseline = stableBaseline(count: 9)
        let big = week(9, energy: 0.9, energyU: 0.05, stress: 0.8, stressU: 0.05)
        let detected = AnomalyDetector().detectAnomalies(regimes: baseline + [big])
        XCTAssertTrue(detected.contains { $0 === big },
                      "a dense, tightly-measured, large multi-metric shift must still detect")
    }

    // MARK: - PA5 Persistence honesty (uncertainty-discounted distance)

    func test_PA5_PersistenceDistanceDiscountsWithinNoise() {
        let checker = RegimePersistenceChecker()

        let a = week(0, energy: 0.5, energyU: 0.1)
        let within = week(1, energy: 0.6, energyU: 0.1)   // Δ0.1 < sqrt(0.02) ≈ 0.141
        XCTAssertEqual(checker.computeRegimeDistance(from: a, to: within), 0.0, accuracy: 1e-9,
                       "a difference within the combined noise contributes zero distance")

        let beyond = week(1, energy: 1.0, energyU: 0.05)  // Δ0.5 ≫ noise
        XCTAssertGreaterThan(checker.computeRegimeDistance(from: a, to: beyond), 0.0,
                             "a difference exceeding the combined noise contributes real distance")
    }

    // MARK: - PA6 Absent ≠ zero regime (E1 regression guard)

    func test_PA6_AbsentMetricDoesNotManufactureAnomaly() {
        let baseline = stableBaseline(count: 9)   // energy present ≈ 0.5 throughout
        // Energy is ABSENT this week (mean 0.0 as construction yields), other metrics
        // match baseline, coverage is above the density floor. If the absent 0.0 were
        // treated as a real value it would read as a huge -0.5 deviation and detect.
        let absentEnergy = week(9, energy: 0.0, energyAbsent: true, density: 0.6)
        let detected = AnomalyDetector().detectAnomalies(regimes: baseline + [absentEnergy])
        XCTAssertFalse(detected.contains { $0 === absentEnergy },
                       "an absent metric's 0.0 mean must not be read as a deviation")
    }
}

// MARK: - C6B: honest event confidence (PB1–PB6)

/// A minimal regime for persistence-distance tests: present, low-uncertainty, with
/// only the fields the distance function reads meaningfully.
private func eventRegime(energy: Double, stress: Double, u: Double = 0.05) -> WeeklyRegime {
    WeeklyRegime(
        weekStart: Date(),
        energyMean: energy, energyStddev: 0.0,
        stressMean: stress, stressStddev: 0.0,
        focusMean: 0.5, focusStddev: 0.0,
        moodMean: 0.6, moodStddev: 0.0,
        scheduleRegularity: 0.7,
        locationDiversity: 0.3,
        socialEngagement: 0.3,
        activityLevel: 0.5,
        energyUncertainty: u, stressUncertainty: u,
        focusUncertainty: u, moodUncertainty: u,
        energyAbsent: false, stressAbsent: false,
        focusAbsent: false, moodAbsent: false,
        dataDensity: 1.0
    )
}

final class EventConfidenceTests: XCTestCase {

    // PB1: a clean anomalous + persistent + unambiguous shift is high-confidence.
    func test_PB1_CleanEventIsConfident() {
        let c = combinedEventConfidence(
            anomaly: anomalyConfidence(anomalyScore: 10),      // strong anomaly
            persistence: persistenceConfidence(distance: 0.5), // strong persistence
            classification: classificationConfidence(topScore: 0.5, secondScore: 0.1) // clear winner
        )
        XCTAssertGreaterThan(c, 0.6, "a clean, unambiguous event should be confident")
    }

    // PB2: a classification tie collapses event confidence, even if anomalous+persistent.
    func test_PB2_ClassificationTieIsLowConfidence() {
        let tie = classificationConfidence(topScore: 0.41, secondScore: 0.40)
        XCTAssertLessThan(tie, 0.1, "a near-tie is genuinely ambiguous")

        let c = combinedEventConfidence(anomaly: 0.8, persistence: 0.8, classification: tie)
        XCTAssertLessThan(c, 0.5, "ambiguous classification must drag event confidence below the bar")
    }

    // PB3: weak persistence caps the event via weakest-link, even with strong others.
    func test_PB3_WeakPersistenceCapsConfidence() {
        let c = combinedEventConfidence(
            anomaly: 0.83,
            persistence: persistenceConfidence(distance: 0.01), // barely persistent
            classification: 0.9
        )
        XCTAssertLessThan(c, 0.5, "a shift that doesn't persist is not a confident event")
    }

    // PB4: no fabricated confidence — no signal ⇒ 0; a lone winner ⇒ full margin.
    func test_PB4_NoFabricatedConfidence() {
        XCTAssertEqual(classificationConfidence(topScore: 0, secondScore: 0), 0.0, accuracy: 1e-9)
        XCTAssertEqual(classificationConfidence(topScore: 0.5, secondScore: 0.0), 1.0, accuracy: 1e-9)
    }

    // PB5: the persistence threshold (0.08) is now clearable by a real shift and not
    // by within-noise divergence — the pipeline is no longer inert.
    func test_PB5_PersistenceThresholdIsReachable() {
        let checker = RegimePersistenceChecker()
        let base = eventRegime(energy: 0.5, stress: 0.4)

        let realShift = eventRegime(energy: 0.95, stress: 0.9)         // large, tight
        XCTAssertGreaterThan(checker.computeRegimeDistance(from: base, to: realShift), 0.08,
                             "a genuine sustained shift must clear the 0.08 persistence threshold")

        let noise = eventRegime(energy: 0.55, stress: 0.44, u: 0.1)    // within combined noise
        XCTAssertLessThan(checker.computeRegimeDistance(from: base, to: noise), 0.08,
                          "within-noise divergence must not clear the threshold")
    }

    // PB6: monotonicity — a larger classification margin yields higher confidence.
    func test_PB6_MarginMonotonic() {
        let narrow = classificationConfidence(topScore: 0.5, secondScore: 0.4)
        let wide   = classificationConfidence(topScore: 0.5, secondScore: 0.2)
        XCTAssertGreaterThan(wide, narrow, "a clearer winner is more confident")
    }
}
