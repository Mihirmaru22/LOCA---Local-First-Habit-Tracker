//
//  AggregationTests.swift
//  LOCATests
//
//  Coverage for the shared aggregation kernel: aggregateByDay (primary attribution
//  only, used by HeatmapDataProvider) and aggregateByDayWithGrace (adds the ±90-minute
//  DST grace credits, used by StreakCalculator). Boundary conditions per Engineering
//  Principles §8.1: empty, single entry, same-day entries, entry at midnight, grace window.
//

import XCTest
import Foundation
@testable import LOCA

final class AggregationTests: XCTestCase {

    private func gregorian(_ timeZoneIdentifier: String = "America/New_York") -> Calendar {
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

    // MARK: - Empty

    func testAggregateByDay_EmptyLogs_ReturnsEmptyArray() {
        XCTAssertTrue(aggregateByDay(snapshots: [], calendar: gregorian()).isEmpty)
    }

    func testAggregateByDayWithGrace_EmptyLogs_ReturnsEmptyArray() {
        XCTAssertTrue(aggregateByDayWithGrace(snapshots: [], calendar: gregorian()).isEmpty)
    }

    // MARK: - Primary attribution

    func testAggregateByDay_SameDayEntries_SummedIntoOneDay() {
        let cal = gregorian()
        let snapshots = [
            LogSnapshot(timestamp: date(2024, 6, 10, 8, 0, in: cal), value: 2.0),
            LogSnapshot(timestamp: date(2024, 6, 10, 20, 0, in: cal), value: 3.0),
        ]
        let totals = aggregateByDay(snapshots: snapshots, calendar: cal)
        XCTAssertEqual(totals.count, 1)
        XCTAssertEqual(totals[0].total, 5.0, accuracy: 1e-9)
        XCTAssertEqual(totals[0].entryCount, 2)
        // aggregateByDay applies no grace, so graceTotal mirrors total.
        XCTAssertEqual(totals[0].graceTotal, totals[0].total, accuracy: 1e-9)
    }

    func testAggregateByDay_ResultSortedAscending() {
        let cal = gregorian()
        let snapshots = [
            LogSnapshot(timestamp: date(2024, 6, 12, 12, 0, in: cal), value: 1),
            LogSnapshot(timestamp: date(2024, 6, 10, 12, 0, in: cal), value: 1),
            LogSnapshot(timestamp: date(2024, 6, 11, 12, 0, in: cal), value: 1),
        ]
        let totals = aggregateByDay(snapshots: snapshots, calendar: cal)
        XCTAssertEqual(totals.count, 3)
        XCTAssertLessThan(totals[0].date, totals[1].date)
        XCTAssertLessThan(totals[1].date, totals[2].date)
    }

    func testAggregateByDay_EntryExactlyAtMidnight_AttributedToThatDay() {
        let cal = gregorian()
        let midnight = cal.startOfDay(for: date(2024, 6, 10, 12, 0, in: cal))
        let totals = aggregateByDay(
            snapshots: [LogSnapshot(timestamp: midnight, value: 1)],
            calendar: cal
        )
        XCTAssertEqual(totals.count, 1)
        XCTAssertEqual(totals[0].date, midnight)
        XCTAssertEqual(totals[0].entryCount, 1)
    }

    // MARK: - Completion tolerance

    func testDayTotal_CompletionEpsilon_ToleratesFloatingPointSum() {
        let cal = gregorian()
        let day = cal.startOfDay(for: date(2024, 6, 10, 12, 0, in: cal))
        // Ten 0.1 increments sum to a Double slightly below 1.0; must still read complete.
        let snapshots = (0..<10).map {
            LogSnapshot(timestamp: cal.date(byAdding: .minute, value: $0, to: day)!, value: 0.1)
        }
        let totals = aggregateByDay(snapshots: snapshots, calendar: cal)
        XCTAssertEqual(totals.count, 1)
        XCTAssertTrue(totals[0].isComplete(for: 1.0))
    }

    // MARK: - Grace window

    func testAggregateByDayWithGrace_JustAfterMidnight_CreditsPreviousDay() {
        let cal = gregorian()
        let dayN = date(2024, 6, 10, 12, 0, in: cal)               // primary 0.7 on N
        let justAfterMidnight = date(2024, 6, 11, 0, 30, in: cal)  // 30 min into N+1

        let totals = aggregateByDayWithGrace(
            snapshots: [
                LogSnapshot(timestamp: dayN, value: 0.7),
                LogSnapshot(timestamp: justAfterMidnight, value: 0.5),
            ],
            calendar: cal
        )
        let nDay = cal.startOfDay(for: dayN)
        let n = totals.first { $0.date == nDay }!

        XCTAssertEqual(n.total, 0.7, accuracy: 1e-9)          // display total unchanged
        XCTAssertEqual(n.graceTotal, 1.2, accuracy: 1e-9)     // 0.7 + 0.5 grace credit
        XCTAssertTrue(n.isCompleteWithGrace(for: 1.0))        // grace pushes over target
        XCTAssertFalse(n.isComplete(for: 1.0))                // primary alone does not
    }

    func testAggregateByDayWithGrace_MiddayEntry_NoGraceCredit() {
        let cal = gregorian()
        let a = date(2024, 6, 10, 12, 0, in: cal)
        let b = date(2024, 6, 11, 12, 0, in: cal)
        let totals = aggregateByDayWithGrace(
            snapshots: [
                LogSnapshot(timestamp: a, value: 0.5),
                LogSnapshot(timestamp: b, value: 0.5),
            ],
            calendar: cal
        )
        // Neither entry is within 90 minutes of a boundary, so grace == primary everywhere.
        for total in totals {
            XCTAssertEqual(total.graceTotal, total.total, accuracy: 1e-9)
        }
    }
}
