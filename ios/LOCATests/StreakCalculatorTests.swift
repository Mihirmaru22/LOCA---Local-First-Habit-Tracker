//
//  StreakCalculatorTests.swift
//  LOCATests
//
//  Unit coverage for the pure streak kernel, the four mandatory DST transition
//  dates (Engineering Principles §8.3), and regression coverage for the C-1/C-2
//  fixes. Every call injects an explicit `referenceDate` so results never depend
//  on the system clock at test-run time (§8.1).
//

import XCTest
import Foundation
@testable import LOCA

final class StreakCalculatorTests: XCTestCase {

    // MARK: - Helpers

    /// A Gregorian calendar pinned to a specific time zone and POSIX locale, so day
    /// boundaries are deterministic regardless of where the test runs.
    private func gregorian(_ timeZoneIdentifier: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    private func date(
        _ year: Int, _ month: Int, _ day: Int,
        _ hour: Int = 12, _ minute: Int = 0,
        in calendar: Calendar
    ) -> Date {
        var components = DateComponents()
        components.year = year; components.month = month; components.day = day
        components.hour = hour; components.minute = minute
        return calendar.date(from: components)!
    }

    private func binarySnapshots(days: [Date]) -> [LogSnapshot] {
        days.map { LogSnapshot(timestamp: $0, value: 1.0) }
    }

    // MARK: - Basic Semantics

    func testCalculate_EmptySnapshots_ReturnsZero() async {
        let result = await StreakCalculator.calculate(snapshots: [], target: 1.0)
        XCTAssertEqual(result, .zero)
    }

    func testCalculate_NonPositiveTarget_ReturnsZero() async {
        let cal = gregorian("America/New_York")
        let today = date(2024, 6, 10, 9, 0, in: cal)
        let result = await StreakCalculator.calculate(
            snapshots: binarySnapshots(days: [today]),
            target: 0.0, calendar: cal, referenceDate: today
        )
        XCTAssertEqual(result, .zero)
    }

    func testCalculate_SingleCompletedToday_StreakIsOne() async {
        let cal = gregorian("America/New_York")
        let today = date(2024, 6, 10, 9, 0, in: cal)
        let result = await StreakCalculator.calculate(
            snapshots: binarySnapshots(days: [today]),
            target: 1.0, calendar: cal, referenceDate: today
        )
        XCTAssertEqual(result.currentStreak, 1)
        XCTAssertEqual(result.longestStreak, 1)
    }

    func testCalculate_ThreeConsecutiveDays_StreakIsThree() async {
        let cal = gregorian("America/New_York")
        let days = [
            date(2024, 6, 8, 9, 0, in: cal),
            date(2024, 6, 9, 9, 0, in: cal),
            date(2024, 6, 10, 9, 0, in: cal),
        ]
        let result = await StreakCalculator.calculate(
            snapshots: binarySnapshots(days: days),
            target: 1.0, calendar: cal, referenceDate: days[2]
        )
        XCTAssertEqual(result.currentStreak, 3)
        XCTAssertEqual(result.longestStreak, 3)
        XCTAssertEqual(cal.startOfDay(for: result.lastCompletedDate!),
                       cal.startOfDay(for: days[2]))
    }

    func testCalculate_GapBeforeYesterday_StreakBroken() async {
        let cal = gregorian("America/New_York")
        // Completed four and three days ago, nothing since → last complete day is old.
        let days = [
            date(2024, 6, 6, 9, 0, in: cal),
            date(2024, 6, 7, 9, 0, in: cal),
        ]
        let reference = date(2024, 6, 10, 9, 0, in: cal)
        let result = await StreakCalculator.calculate(
            snapshots: binarySnapshots(days: days),
            target: 1.0, calendar: cal, referenceDate: reference
        )
        XCTAssertEqual(result.currentStreak, 0)
        XCTAssertEqual(result.longestStreak, 2)
    }

    func testCalculate_LastCompletedYesterday_StreakStillActive() async {
        let cal = gregorian("America/New_York")
        let yesterday = date(2024, 6, 9, 9, 0, in: cal)
        let reference = date(2024, 6, 10, 9, 0, in: cal)
        let result = await StreakCalculator.calculate(
            snapshots: binarySnapshots(days: [yesterday]),
            target: 1.0, calendar: cal, referenceDate: reference
        )
        // Today may still be in progress, so a run ending yesterday stays active.
        XCTAssertEqual(result.currentStreak, 1)
    }

    func testCalculate_FutureDatedEntry_ExcludedFromStreak() async {
        let cal = gregorian("America/New_York")
        let today = date(2024, 6, 10, 9, 0, in: cal)
        let future = date(2024, 6, 25, 9, 0, in: cal)
        let result = await StreakCalculator.calculate(
            snapshots: binarySnapshots(days: [today, future]),
            target: 1.0, calendar: cal, referenceDate: today
        )
        // A clock-skewed future entry must neither become lastCompletedDate nor
        // suppress today's active streak.
        XCTAssertEqual(result.currentStreak, 1)
        XCTAssertEqual(cal.startOfDay(for: result.lastCompletedDate!),
                       cal.startOfDay(for: today))
    }

    func testCalculate_QuantitativeMultipleEntriesReachTarget() async {
        let cal = gregorian("America/New_York")
        let today = date(2024, 6, 10, 9, 0, in: cal)
        let snapshots = [
            LogSnapshot(timestamp: date(2024, 6, 10, 8, 0, in: cal), value: 2.0),
            LogSnapshot(timestamp: date(2024, 6, 10, 18, 0, in: cal), value: 3.0),
        ]
        let result = await StreakCalculator.calculate(
            snapshots: snapshots, target: 5.0, calendar: cal, referenceDate: today
        )
        XCTAssertEqual(result.currentStreak, 1)
    }

    // MARK: - Mandatory DST Transitions (Engineering Principles §8.3)

    /// Four consecutive civil days centered on a DST transition must count as an
    /// unbroken 4-day streak — the clock shift must not fabricate a missed day.
    private func assertStreakUnbrokenAcrossTransition(
        timeZone: String,
        transition year: Int, _ month: Int, _ day: Int,
        file: StaticString = #filePath, line: UInt = #line
    ) async {
        let cal = gregorian(timeZone)
        let transitionDay = date(year, month, day, 12, 0, in: cal)
        let days = [
            cal.date(byAdding: .day, value: -1, to: transitionDay)!,
            transitionDay,
            cal.date(byAdding: .day, value: 1, to: transitionDay)!,
            cal.date(byAdding: .day, value: 2, to: transitionDay)!,
        ]
        let result = await StreakCalculator.calculate(
            snapshots: binarySnapshots(days: days),
            target: 1.0, calendar: cal, referenceDate: days[3]
        )
        XCTAssertEqual(result.currentStreak, 4,
                       "streak broken across DST transition in \(timeZone)",
                       file: file, line: line)
        XCTAssertEqual(result.longestStreak, 4, file: file, line: line)
    }

    func testStreakCalculator_DSTFallBack_Australia_DoesNotBreakStreak() async {
        // 2024-04-07 AEDT → AEST (clocks back)
        await assertStreakUnbrokenAcrossTransition(timeZone: "Australia/Sydney", transition: 2024, 4, 7)
    }

    func testStreakCalculator_DSTFallBack_USEastern_DoesNotBreakStreak() async {
        // 2024-11-03 EDT → EST (clocks back)
        await assertStreakUnbrokenAcrossTransition(timeZone: "America/New_York", transition: 2024, 11, 3)
    }

    func testStreakCalculator_DSTSpringForward_USEastern_DoesNotBreakStreak() async {
        // 2024-03-10 EST → EDT (clocks forward)
        await assertStreakUnbrokenAcrossTransition(timeZone: "America/New_York", transition: 2024, 3, 10)
    }

    func testStreakCalculator_DSTSpringForward_CentralEurope_DoesNotBreakStreak() async {
        // 2024-03-31 CET → CEST (clocks forward)
        await assertStreakUnbrokenAcrossTransition(timeZone: "Europe/Berlin", transition: 2024, 3, 31)
    }

    // MARK: - Regression: C-2 (recalculation the mutation paths now delegate to)

    // These assert the kernel behaviour that T1/T2 rely on: after a non-today mutation,
    // a full recalculation from the resulting snapshot set yields the correct streak —
    // exactly the "Done when" criteria for C-2, expressed at the calculator level.

    func testRegression_BackdatingFillsGap_ExtendsStreak() async {
        let cal = gregorian("America/New_York")
        let twoAgo    = date(2024, 6, 8, 9, 0, in: cal)
        let yesterday = date(2024, 6, 9, 9, 0, in: cal)
        let today     = date(2024, 6, 10, 9, 0, in: cal)

        // Before backdating: today and two-days-ago complete, yesterday missing.
        let before = await StreakCalculator.calculate(
            snapshots: binarySnapshots(days: [twoAgo, today]),
            target: 1.0, calendar: cal, referenceDate: today
        )
        XCTAssertEqual(before.currentStreak, 1)

        // After a backdated check-in fills yesterday, the recalculation yields 3.
        let after = await StreakCalculator.calculate(
            snapshots: binarySnapshots(days: [twoAgo, yesterday, today]),
            target: 1.0, calendar: cal, referenceDate: today
        )
        XCTAssertEqual(after.currentStreak, 3)
    }

    func testRegression_DeletingTodaysOnlyEntry_LowersStreak() async {
        let cal = gregorian("America/New_York")
        let today = date(2024, 6, 10, 9, 0, in: cal)

        let withEntry = await StreakCalculator.calculate(
            snapshots: binarySnapshots(days: [today]),
            target: 1.0, calendar: cal, referenceDate: today
        )
        XCTAssertEqual(withEntry.currentStreak, 1)

        // Deleting the only entry leaves no completed day → streak drops to zero.
        let afterDelete = await StreakCalculator.calculate(
            snapshots: [], target: 1.0, calendar: cal, referenceDate: today
        )
        XCTAssertEqual(afterDelete.currentStreak, 0)
    }

    func testRegression_EditingMiddleDayBelowTarget_BreaksRun() async {
        let cal = gregorian("America/New_York")
        let d1 = date(2024, 6, 8, 9, 0, in: cal)
        let d2 = date(2024, 6, 9, 9, 0, in: cal)
        let d3 = date(2024, 6, 10, 9, 0, in: cal)

        // Three consecutive complete days → streak 3.
        let intact = await StreakCalculator.calculate(
            snapshots: [
                LogSnapshot(timestamp: d1, value: 1.0),
                LogSnapshot(timestamp: d2, value: 1.0),
                LogSnapshot(timestamp: d3, value: 1.0),
            ],
            target: 1.0, calendar: cal, referenceDate: d3
        )
        XCTAssertEqual(intact.currentStreak, 3)

        // Editing the middle day below target breaks the run; only today remains.
        let edited = await StreakCalculator.calculate(
            snapshots: [
                LogSnapshot(timestamp: d1, value: 1.0),
                LogSnapshot(timestamp: d2, value: 0.4),
                LogSnapshot(timestamp: d3, value: 1.0),
            ],
            target: 1.0, calendar: cal, referenceDate: d3
        )
        XCTAssertEqual(edited.currentStreak, 1)
        XCTAssertEqual(edited.longestStreak, 1)
    }
}
