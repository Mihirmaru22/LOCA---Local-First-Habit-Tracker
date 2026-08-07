//
//  HeatmapDataProviderTests.swift
//  LOCATests
//
//  Coverage for HeatmapDataProvider.buildDayGrid: window length, parameter guards,
//  empty-day cells, and the H2 epsilon-tolerant intensity formula (a day reached
//  through fractional increments must render at exactly 1.0, not a near-1.0 value).
//

import XCTest
import Foundation
@testable import LOCA

final class HeatmapDataProviderTests: XCTestCase {

    private func gregorian(_ timeZoneIdentifier: String = "America/New_York") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    // MARK: - Window & guards

    func testBuildDayGrid_WindowLength_MatchesRequestedDays() async {
        let cells = await HeatmapDataProvider.buildDayGrid(
            snapshots: [], target: 1.0, windowDays: 30, calendar: gregorian()
        )
        XCTAssertEqual(cells.count, 30)
    }

    func testBuildDayGrid_InvalidParameters_ReturnEmpty() async {
        let cal = gregorian()
        let zeroWindow = await HeatmapDataProvider.buildDayGrid(
            snapshots: [], target: 1.0, windowDays: 0, calendar: cal
        )
        XCTAssertTrue(zeroWindow.isEmpty)

        let badTarget = await HeatmapDataProvider.buildDayGrid(
            snapshots: [], target: 0.0, windowDays: 30, calendar: cal
        )
        XCTAssertTrue(badTarget.isEmpty)
    }

    func testBuildDayGrid_ResultSortedOldestToNewest() async {
        let cells = await HeatmapDataProvider.buildDayGrid(
            snapshots: [], target: 1.0, windowDays: 10, calendar: gregorian()
        )
        XCTAssertEqual(cells.count, 10)
        for i in 1..<cells.count {
            XCTAssertLessThan(cells[i - 1].date, cells[i].date)
        }
        XCTAssertTrue(cells.last!.isToday)
    }

    // MARK: - Empty days

    func testBuildDayGrid_EmptyDays_HaveZeroIntensityAndNoEntry() async {
        let cells = await HeatmapDataProvider.buildDayGrid(
            snapshots: [], target: 1.0, windowDays: 7, calendar: gregorian()
        )
        XCTAssertEqual(cells.count, 7)
        XCTAssertTrue(cells.allSatisfy { $0.intensity == 0 && !$0.hasEntry && $0.total == 0 })
    }

    // MARK: - Intensity formula (H2 epsilon tolerance)

    func testBuildDayGrid_CompletedToday_IntensityExactlyOne() async {
        let cal = gregorian()
        let snapshots = [LogSnapshot(timestamp: Date(), value: 1.0)]
        let cells = await HeatmapDataProvider.buildDayGrid(
            snapshots: snapshots, target: 1.0, windowDays: 7, calendar: cal
        )
        let todayCell = cells.last!
        XCTAssertTrue(todayCell.isToday)
        XCTAssertTrue(todayCell.hasEntry)
        XCTAssertEqual(todayCell.intensity, 1.0)   // exact, not 0.999…
    }

    func testBuildDayGrid_FractionalIncrementsReachTarget_IntensityExactlyOne() async {
        let cal = gregorian()
        let today = cal.startOfDay(for: Date())
        // Ten 0.1 increments today → Double sum slightly below 1.0.
        let snapshots = (0..<10).map {
            LogSnapshot(timestamp: cal.date(byAdding: .minute, value: $0, to: today)!, value: 0.1)
        }
        let cells = await HeatmapDataProvider.buildDayGrid(
            snapshots: snapshots, target: 1.0, windowDays: 2, calendar: cal
        )
        // Epsilon tolerance must land this exactly on 1.0.
        XCTAssertEqual(cells.last!.intensity, 1.0)
    }

    func testBuildDayGrid_BelowTarget_IntensityIsRatio() async {
        let cal = gregorian()
        let snapshots = [LogSnapshot(timestamp: Date(), value: 2.0)]
        let cells = await HeatmapDataProvider.buildDayGrid(
            snapshots: snapshots, target: 4.0, windowDays: 3, calendar: cal
        )
        XCTAssertEqual(cells.last!.intensity, 0.5, accuracy: 1e-9)
        XCTAssertTrue(cells.last!.hasEntry)
    }
}
