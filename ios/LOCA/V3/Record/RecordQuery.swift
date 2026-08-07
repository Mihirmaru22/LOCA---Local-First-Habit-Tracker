import Foundation

// MARK: - RecordDateRange

/// A closed date interval for filtering facts by occurrence time.
/// Named RecordDateRange to avoid collision with other DateRange types in the module.
struct RecordDateRange: Sendable {
    let start: Date
    let end: Date

    func contains(_ date: Date) -> Bool {
        date >= start && date <= end
    }

    static func lastDays(_ n: Int, from reference: Date = Date()) -> RecordDateRange {
        let end = reference
        let start = Calendar.current.date(byAdding: .day, value: -n, to: reference) ?? reference
        return RecordDateRange(start: start, end: end)
    }

    static func week(containing date: Date, calendar: Calendar = .current) -> RecordDateRange {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let weekStart = calendar.date(from: components) ?? date
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? date
        return RecordDateRange(start: weekStart, end: weekEnd)
    }
}

// MARK: - RecordOrder

/// Sort order for fact queries. All queries return a deterministic order —
/// there is no "unordered" mode.
enum RecordOrder: Sendable {
    /// Oldest recorded first. Use for chronological display and replay.
    case recordedAtAscending
    /// Newest recorded first. Use for "most recent" views.
    case recordedAtDescending
    /// Oldest occurrence first. Preferred for time-of-event analysis.
    case occurredAtAscending
    /// Newest occurrence first.
    case occurredAtDescending
}

// MARK: - RecordQuery

/// A deterministic, composable query against the Record.
///
/// All fields are optional filters; omitting a field means "no restriction."
/// The query never modifies the Record — it is a pure read specification.
///
/// Usage:
///   let query = RecordQuery(kinds: [.habitLogged], dateRange: .lastDays(7))
///   let facts = try await reader.facts(matching: query)
struct RecordQuery: Sendable {

    /// Restrict results to these fact kinds. nil = all kinds.
    let kinds: Set<FactKind>?

    /// Restrict results to facts whose `occurredAt` falls within this range.
    /// nil = all time.
    let dateRange: RecordDateRange?

    /// Restrict results to facts from these sources. nil = all sources.
    let sources: Set<FactSource>?

    /// Sort order. Default: occurredAtAscending (chronological).
    let order: RecordOrder

    /// Maximum number of results. nil = no limit.
    let limit: Int?

    /// Skip this many results (for pagination).
    let offset: Int

    init(
        kinds: Set<FactKind>? = nil,
        dateRange: RecordDateRange? = nil,
        sources: Set<FactSource>? = nil,
        order: RecordOrder = .occurredAtAscending,
        limit: Int? = nil,
        offset: Int = 0
    ) {
        self.kinds = kinds
        self.dateRange = dateRange
        self.sources = sources
        self.order = order
        self.limit = limit
        self.offset = offset
    }
}

// MARK: - Convenience query factories

extension RecordQuery {

    /// All facts in the Record, oldest-occurred first.
    static var all: RecordQuery {
        RecordQuery()
    }

    /// All facts of a single kind, oldest-occurred first.
    static func kind(_ k: FactKind) -> RecordQuery {
        RecordQuery(kinds: [k])
    }

    /// All facts within a date range, oldest-occurred first.
    static func inRange(_ range: RecordDateRange) -> RecordQuery {
        RecordQuery(dateRange: range)
    }

    /// The N most recently recorded facts of a given kind.
    static func recentOf(kind k: FactKind, limit n: Int) -> RecordQuery {
        RecordQuery(kinds: [k], order: .recordedAtDescending, limit: n)
    }
}
