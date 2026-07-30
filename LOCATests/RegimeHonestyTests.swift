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
