import Foundation

// MARK: - DayCell

/// A single renderable cell in the heatmap grid, representing one calendar day.
///
/// `DayCell` is a pure value type produced by `HeatmapDataProvider.buildDayGrid`.
/// It carries everything `HeatmapGridView` needs to render a single cell without
/// accessing `ModelContext`, performing Calendar arithmetic, or touching any `@Model`
/// object at render time.
///
/// ## Colour Rendering
/// Pass `intensity` to `ColorPalette.heatmapColor(forColorIndex:ratio:)` along with
/// `board.colorIndex` to obtain the cell's display colour:
///
/// ```swift
/// // In HeatmapGridView.body:
/// ColorPalette.heatmapColor(forColorIndex: board.colorIndex, ratio: cell.intensity)
/// ```
///
/// The 0.15 minimum opacity floor described in Engineering Principles Appendix C is
/// applied inside `ColorPalette.heatmapColor`, not in `DayCell.intensity`. `intensity`
/// is a raw ratio in `[0, 1]` — a pure data value with no rendering assumptions baked in.
///
/// `intensity` is computed with floating-point tolerance (see `buildDayGrid`'s algorithm
/// note): any day whose total is within `DayTotal.completionEpsilon` of the target, or
/// above it, produces `intensity == 1.0` exactly — never `0.9999999999999998`.
///
/// ## Accessibility
/// `HeatmapGridView` uses `DayCell` properties to build `accessibilityLabel` strings
/// per Engineering Principles §6.2. Example:
///
/// ```swift
/// let label: String = {
///     guard cell.hasEntry else { return "\(cell.date.formatted(accessibilityDateStyle)), no entry" }
///     let comparison = cell.intensity >= 1.0 ? "above or at" : "below"
///     return "\(cell.date.formatted(accessibilityDateStyle)) · \(cell.total) \(unitLabel) · \(comparison) goal"
/// }()
/// cell.accessibilityLabel(label)
/// ```
///
/// This `cell.intensity >= 1.0` comparison is now safe: `buildDayGrid` guarantees
/// `intensity` lands exactly on `1.0` (not a near-1.0 floating-point approximation)
/// for any day that genuinely met its target, including days where the total was
/// reached through repeated fractional increments.
///
/// `DayCell` deliberately does not include a pre-formatted `accessibilityLabel` property
/// because label formatting requires `board.unitLabel` (a render-time concern, not a
/// data-layer concern) and locale-aware number formatting.
struct DayCell: Sendable, Identifiable, Hashable {

    /// The start-of-day date for this cell's calendar day. Used as the stable identity
    /// for `ForEach` and `LazyVGrid` enumeration. Produced by `Date.trailingDays`.
    let date: Date

    /// The sum of all `LogEntry.value` for this calendar day (primary attribution only,
    /// no DST grace credits). Used for numeric display in the detail panel and in
    /// the accessibility label.
    ///
    /// Zero for days with no log entries.
    let total: Double

    /// The completion ratio for colour intensity. Always in `[0.0, 1.0]`. Zero for days
    /// with no entries. Exactly `1.0` (not a near-1.0 approximation) for any day whose
    /// `total` is at or within floating-point tolerance of the target — see `buildDayGrid`.
    ///
    /// Pass directly to `ColorPalette.heatmapColor(forColorIndex:ratio:)`.
    /// The 0.15 opacity floor is applied inside `ColorPalette`, not here.
    let intensity: Double

    /// `true` if this cell represents the current calendar day.
    /// Used by `HeatmapGridView` to apply a distinct border or highlight.
    let isToday: Bool

    /// `true` if at least one `LogEntry` exists for this day (`entryCount > 0`).
    ///
    /// Distinct from `total > 0`: a user could theoretically log a value of `0.0`
    /// (e.g., recording zero miles as an explicit failed attempt). `hasEntry` correctly
    /// reflects "was there any logging activity?" while `total > 0` reflects "was
    /// there positive progress?"
    ///
    /// Used for accessibility labels: "no entry" vs. logged-but-zero.
    let hasEntry: Bool

    // MARK: Identifiable

    /// Stable identity is the calendar day's start-of-day date. Unique within any
    /// single board's grid for a given window.
    var id: Date { date }
}

// MARK: - HeatmapDataProvider

/// Builds the complete heatmap cell grid for a `HabitBoard`.
///
/// `HeatmapDataProvider` is a pure-computation namespace with no mutable state.
/// Its single method, `buildDayGrid`, is `async` and `nonisolated` (by virtue of
/// `enum` membership — ADR-005), running on the cooperative thread pool when called
/// with `await` from `@MainActor`. No `ModelContext` is accessed.
///
/// ## Architecture (ADR-005)
///
/// The caller creates `[LogSnapshot]` on `@MainActor`, passes it to `buildDayGrid`,
/// and stores the returned `[DayCell]` as `@State` in the view. The grid is rebuilt
/// whenever the snapshot set changes (driven by SwiftData's `@Query` observation):
///
/// ```swift
/// // In HeatmapGridView or its parent:
/// @State private var cells: [DayCell] = []
/// @Query private var logs: [LogEntry]
///
/// .task(id: logs) {
///     // logs is observed by @Query; this task re-runs on every insert
///     let snapshots = logs.map(LogSnapshot.init(from:))
///     cells = await HeatmapDataProvider.buildDayGrid(
///         snapshots: snapshots,
///         target:    board.effectiveTarget,
///         windowDays: 365
///     )
/// }
/// ```
///
/// ## Relationship to StreakCalculator (Phase 2 review finding H3)
///
/// Both types are built on the shared aggregation kernel in `StreakCalculator.swift`,
/// but they call **different** functions from it. `HeatmapDataProvider` calls
/// `aggregateByDay` — primary attribution only, no grace-window computation.
/// `StreakCalculator` calls `aggregateByDayWithGrace`, which additionally computes
/// DST grace credits that only streak logic needs.
///
/// An earlier draft had `HeatmapDataProvider` call a single combined function that
/// always computed grace credits, meaning every heatmap render unconditionally paid
/// for work it never used (`DayTotal.graceTotal` was never read here). Calling the
/// lighter `aggregateByDay` instead removes that wasted cost from the heatmap's hot path.
///
/// ## Performance
///
/// For 10,000 log entries over a 365-day window:
/// - `aggregateByDay`: O(N) = one Calendar call and one dictionary accumulation per entry
/// - Date range construction: O(W) = 365 calendar additions
/// - Grid mapping: O(W) = 365 dictionary lookups + struct allocations
/// - Result array: 365 `DayCell` structs × ~48 bytes each ≈ 17 KB
///
/// Typical wall-clock time: well under 5 ms. Runs off the main thread; no frame budget impact.
enum HeatmapDataProvider {

    // MARK: - Public API

    /// Builds a complete grid of `DayCell` values covering the trailing `windowDays`
    /// calendar days, ending today.
    ///
    /// ## Algorithm
    ///
    /// ```
    /// 1. aggregateByDay(snapshots, calendar)          → [DayTotal]    O(N log D)
    /// 2. Dictionary(uniqueKeysWithValues: dayTotals)  → [Date: DayTotal]  O(D)
    /// 3. Date.trailingDays(windowDays)                → [Date]         O(W)
    /// 4. Map each date to DayCell                     → [DayCell]      O(W)
    ///
    /// Total: O(N log D + W)  where N = snapshot count, D = distinct days, W = windowDays
    /// ```
    ///
    /// Steps 1–4 produce a result sorted ascending (oldest → newest), matching the
    /// left-to-right, top-to-bottom calendar order required by `HeatmapGridView`.
    ///
    /// ## Empty Days
    ///
    /// Every date in the window is represented in the result, including days with no
    /// log entries. Empty days have `total = 0`, `intensity = 0`, and `hasEntry = false`.
    /// Their cells render as `ColorPalette.emptyCellColor` (see `ColorPalette.heatmapColor`).
    ///
    /// ## Intensity Formula (Engineering Principles Appendix C, with floating-point
    /// tolerance per Phase 2 review finding H2)
    ///
    /// ```
    /// intensity = total <= 0                          ? 0.0
    ///           : total >= target - completionEpsilon  ? 1.0   // at-or-above goal, exact
    ///           : total / target                                // genuinely below goal
    /// ```
    ///
    /// The middle branch is the H2 fix: without it, a day reached through repeated
    /// fractional increments (e.g., ten 0.1-unit logs summing to a `Double` value of
    /// `0.9999999999999998` instead of exactly `1.0`) would render at slightly less
    /// than full intensity, and the `cell.intensity >= 1.0` accessibility-label pattern
    /// shown in `DayCell`'s documentation would incorrectly report "below goal." Any
    /// day at or within tolerance of the target now produces exactly `1.0`. Values
    /// genuinely below target are never clamped — the ratio is returned as-is, and
    /// by construction of the tolerance check it is always `< 1.0` in that branch.
    ///
    /// - Parameters:
    ///   - snapshots:   Log snapshots for a single board. Created on `@MainActor`;
    ///                  `Sendable`, safe to pass here.
    ///   - target:      The board's `effectiveTarget`. Must be `> 0`.
    ///   - windowDays:  Number of trailing days to include in the grid. Defaults to 365.
    ///                  Must be `≥ 1`.
    ///   - calendar:    Calendar for all day boundary computations.
    ///                  Pass `Calendar.current` at the call site.
    /// - Returns: `[DayCell]` sorted ascending by date (oldest first). Count equals
    ///            `windowDays` when `windowDays ≥ 1` and calendar arithmetic succeeds.
    ///            Returns an empty array for invalid parameters.
    static func buildDayGrid(
        snapshots:   [LogSnapshot],
        target:      Double,
        windowDays:  Int      = 365,
        calendar:    Calendar = .current
    ) async -> [DayCell] {

        // ── Parameter Guards ─────────────────────────────────────────────────────
        // Defensive exits rather than preconditions: HeatmapGridView should degrade
        // to an empty grid rather than crashing if somehow called with bad parameters.
        guard windowDays >= 1 else { return [] }
        guard target > 0       else { return [] }

        // ── Step 1: Aggregate by Day (primary attribution only) ─────────────────
        // Calls aggregateByDay, NOT aggregateByDayWithGrace — the heatmap never reads
        // DayTotal.graceTotal, so it does not pay for grace-window computation
        // (Phase 2 review finding H3; see the "Relationship to StreakCalculator" note
        // on this type).
        let dayTotals = aggregateByDay(snapshots: snapshots, calendar: calendar)

        // ── Step 2: Build Lookup Dictionary ─────────────────────────────────────
        // O(D) construction; O(1) per lookup in Step 4.
        // `uniqueKeysWithValues` is safe here: aggregateByDay guarantees one entry
        // per distinct calendar day (duplicate dates cannot exist in its output).
        let totalsByDate: [Date: DayTotal] = Dictionary(
            uniqueKeysWithValues: dayTotals.map { ($0.date, $0) }
        )

        // ── Step 3: Build Full Date Range ────────────────────────────────────────
        // Date.trailingDays returns windowDays calendar day-starts, oldest first.
        // All dates are startOfDay-normalised, matching the keys in totalsByDate.
        let dateRange = Date.trailingDays(windowDays, using: calendar)
        let today     = calendar.startOfDay(for: Date())

        // ── Step 4: Map Dates to DayCells ────────────────────────────────────────
        //
        // MARK: Intensity Calculation (Appendix C, Engineering Principles; H2 fix above)
        //
        // `total` uses primary attribution only (not graceTotal) — the heatmap shows
        // what the user actually logged on each day, not the DST-adjusted value.
        // See the doc comment on `buildDayGrid` above for the full epsilon-tolerant
        // formula and why the middle branch exists.

        var cells: [DayCell] = []
        cells.reserveCapacity(dateRange.count)

        for date in dateRange {
            let dayTotal = totalsByDate[date]
            let total    = dayTotal?.total ?? 0.0

            let intensity: Double
            if total <= 0 {
                intensity = 0.0
            } else if total >= target - DayTotal.completionEpsilon {
                // At or within floating-point tolerance of the target — exactly 1.0,
                // not a near-1.0 approximation. This is the H2 fix.
                intensity = 1.0
            } else {
                // Genuinely below target. By construction of the branch above,
                // total / target < 1.0 here — no additional clamp needed.
                intensity = total / target
            }

            cells.append(DayCell(
                date:      date,
                total:     total,
                intensity: intensity,
                isToday:   date == today,
                hasEntry:  (dayTotal?.entryCount ?? 0) > 0
            ))
        }

        return cells
    }
}
