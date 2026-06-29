import Foundation

// MARK: - Date + Calendar Helpers

extension Date {

    // MARK: - Day Boundary

    /// Returns the start of the calendar day for this date using the given calendar.
    ///
    /// Delegates to `Calendar.startOfDay(for:)`, which is DST-aware: on a DST
    /// fall-back transition night, `startOfDay` returns the correct local midnight
    /// even though the day is 25 hours long. On a spring-forward night (23-hour day)
    /// it likewise returns the correct local midnight.
    ///
    /// All date-boundary computations in this project use this method rather than
    /// manual `DateComponents` construction, to avoid timezone arithmetic errors.
    ///
    /// - Parameter calendar: The calendar to use. Always pass `Calendar.current`
    ///                       from the call site — do not cache a `Calendar` instance
    ///                       across timezone changes.
    /// - Returns: The `Date` value representing midnight at the start of this date's
    ///            calendar day in `calendar.timeZone`.
    func startOfDay(using calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }

    // MARK: - Day Comparison

    /// Returns `true` if this date and `other` fall on the same calendar day.
    ///
    /// - Parameters:
    ///   - other: The date to compare against.
    ///   - calendar: The calendar to use. Defaults to `Calendar.current`.
    func isSameDay(as other: Date, using calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, inSameDayAs: other)
    }

    /// Returns `true` if this date falls on the calendar day immediately before today.
    ///
    /// Used by `StreakCalculator` (Phase 2) to determine whether a missed check-in
    /// breaks an active streak.
    ///
    /// - Parameter calendar: The calendar to use. Defaults to `Calendar.current`.
    func isYesterday(using calendar: Calendar = .current) -> Bool {
        calendar.isDateInYesterday(self)
    }

    /// Returns `true` if this date falls on today's calendar day.
    ///
    /// - Parameter calendar: The calendar to use. Defaults to `Calendar.current`.
    func isToday(using calendar: Calendar = .current) -> Bool {
        calendar.isDateInToday(self)
    }

    /// Returns `true` if this date falls on a calendar day strictly before today.
    ///
    /// A date on today's calendar day returns `false`.
    ///
    /// - Parameter calendar: The calendar to use. Defaults to `Calendar.current`.
    func isBeforeToday(using calendar: Calendar = .current) -> Bool {
        startOfDay(using: calendar) < Date().startOfDay(using: calendar)
    }

    // MARK: - Date Range

    /// Returns all calendar day start-dates from `start` through `end`, inclusive.
    ///
    /// Used by `HeatmapDataProvider` (Phase 2) to produce the full date grid for
    /// the heatmap, including days with no `LogEntry` records, which are rendered
    /// as empty cells.
    ///
    /// Both `start` and `end` are normalised to their calendar day starts before
    /// enumeration begins, so passing any time-of-day within a given day produces
    /// the same result as passing midnight.
    ///
    /// - Parameters:
    ///   - start: The first date to include (inclusive). Time component is ignored.
    ///   - end:   The last date to include (inclusive). Time component is ignored.
    ///   - calendar: The calendar to use. Defaults to `Calendar.current`.
    /// - Returns: A sorted array of `Date` values, each at the start of its calendar
    ///            day. Returns an empty array when `end` is before `start`.
    static func dayRange(
        from start: Date,
        through end: Date,
        using calendar: Calendar = .current
    ) -> [Date] {
        var result: [Date] = []
        var current = calendar.startOfDay(for: start)
        let endDay   = calendar.startOfDay(for: end)

        while current <= endDay {
            result.append(current)
            // calendar.date(byAdding:) is nil-safe for supported calendar/timezone
            // combinations. The guard exits defensively on the astronomically unlikely
            // case where arithmetic overflows.
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else {
                break
            }
            current = next
        }

        return result
    }

    // MARK: - Convenience Ranges

    /// Returns the trailing `days` calendar days ending today, inclusive.
    ///
    /// For example, `Date.trailingDays(365)` returns the last 365 days — the
    /// default heatmap window. The first element in the returned array is the
    /// oldest day; the last element is today.
    ///
    /// - Parameters:
    ///   - days: The number of days to include. Must be ≥ 1.
    ///   - calendar: The calendar to use. Defaults to `Calendar.current`.
    /// - Returns: A sorted ascending array of `Date` values, each at day start.
    static func trailingDays(
        _ days: Int,
        using calendar: Calendar = .current
    ) -> [Date] {
        precondition(days >= 1, "days must be at least 1")
        let today = Date()
        guard let start = calendar.date(byAdding: .day, value: -(days - 1), to: today) else {
            return [calendar.startOfDay(for: today)]
        }
        return dayRange(from: start, through: today, using: calendar)
    }
}
