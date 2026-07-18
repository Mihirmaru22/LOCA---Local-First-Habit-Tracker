import SwiftUI

// MARK: - Layout Constants

private enum HeatmapLayout {
    static let cellSize: CGFloat = 14
    static let cellSpacing: CGFloat = 3
    static let cellCornerRadius: CGFloat = 3
    static let rowsPerColumn = 7            // one calendar week per column
    static let todayBorderWidth: CGFloat = 1.5
}

// MARK: - HeatmapView

/// The calendar heatmap: a horizontally-scrolling grid of week-columns, each
/// seven days tall, colour-intensity-coded by daily completion against target.
///
/// ## Why `LazyHGrid`, Not `LazyVGrid`
///
/// A calendar heatmap (GitHub's contribution graph, Apple's own Screen Time
/// weekly view — the visual convention this project's own IP is modeled on
/// per the original System Context Document) reads as fixed-height weeks
/// growing horizontally over time, not fixed-width weeks growing vertically.
/// `LazyHGrid` with `rows: [GridItem](repeating: .fixed(cellSize), count: 7)`
/// inside a horizontal `ScrollView` is the structurally correct match — a
/// `LazyVGrid` would produce a top-to-bottom week reading, which is not this
/// convention.
///
/// ## Data Flow (Consumes Phase 2 Exactly As Designed)
///
/// `HeatmapDataProvider.buildDayGrid` is `nonisolated async` — it runs off the
/// main thread on the cooperative pool. This view creates `[LogSnapshot]` on
/// `@MainActor` inside `.task(id:)`, awaits the result, and stores it as
/// `@State`. No new aggregation, no new colour math — `DayCell.intensity` and
/// `ColorPalette.heatmapColor(forColorIndex:ratio:)` are used exactly as
/// Phase 1/2 documented them.
///
/// `.task(id: board.logs?.count ?? 0)` re-triggers the async rebuild whenever
/// the log count changes — the same `Int`-proxy pattern used for
/// `onChange(of: activeBoards.count)` in `RootNavigationView` (Phase 3),
/// avoiding any dependency on `HabitBoard`/`LogEntry` `Equatable` conformance,
/// which isn't guaranteed.
struct HeatmapView: View {

    let board: HabitBoard

    @State private var cells: [DayCell] = []
    @State private var isLoading = true

    /// Number of trailing days to render. Matches `HeatmapDataProvider`'s own
    /// default and the System Context Document's specified 100–365 day range.
    var windowDays: Int = 365

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: gridHeight)
            } else if cells.isEmpty {
                // Defensive fallback — buildDayGrid returns one cell per day in
                // the window for any valid target/windowDays, so an empty result
                // here would only occur from an invalid target (target <= 0),
                // which effectiveTarget already guards against upstream. Kept as
                // a non-crashing fallback rather than an assumption this can
                // never happen.
                ContentUnavailableView {
                    Label("No History Yet", systemImage: "square.grid.3x3")
                } description: {
                    Text("Your habit history will appear here.")
                }
                .frame(minHeight: gridHeight)
            } else {
                HStack(alignment: .top, spacing: DS.Space.sm) {
                    // Day labels (left column, fixed width)
                    VStack(spacing: HeatmapLayout.cellSpacing) {
                        ForEach(0..<HeatmapLayout.rowsPerColumn, id: \.self) { rowIdx in
                            let dayName = ["S", "M", "T", "W", "T", "F", "S"][rowIdx % 7]
                            Text(dayName)
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                                .frame(width: 20, height: HeatmapLayout.cellSize, alignment: .center)
                        }
                    }
                    .padding(.vertical, 2)

                    // Heatmap grid (scrollable)
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHGrid(
                            rows: Array(
                                repeating: GridItem(.fixed(HeatmapLayout.cellSize), spacing: HeatmapLayout.cellSpacing),
                                count: HeatmapLayout.rowsPerColumn
                            ),
                            spacing: HeatmapLayout.cellSpacing
                        ) {
                            ForEach(cells) { cell in
                                HeatmapCellView(cell: cell, colorIndex: board.colorIndex, unitLabel: board.unitLabel)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .defaultScrollAnchor(.trailing)
                    // On macOS, the outer List's scroll gesture handler can consume
                    // horizontal trackpad events before the inner ScrollView sees them.
                    // Adding a simultaneous DragGesture gives the inner ScrollView
                    // priority for horizontal swipes without blocking List's vertical
                    // scroll (they run in parallel).
                    .simultaneousGesture(DragGesture(minimumDistance: 0))
                }
            }
        }
        .task(id: taskID) {
            await rebuildGrid()
        }
    }

    /// A stable task identifier that changes whenever logs are added/removed.
    /// Uses `board.logs?.count` but falls back to timestamp-based triggers via
    /// `board.id` so the task always fires at least once on appearance, even
    /// if the lazy relationship hasn't loaded yet. The double-trigger (once with
    /// nil count, once when the relationship loads) is intentional and safe:
    /// `rebuildGrid` is idempotent and `Task.isCancelled` guards stale writes.
    private var taskID: some Hashable {
        "\(board.id)-\(board.logs?.count ?? -1)"
    }

    private var gridHeight: CGFloat {
        CGFloat(HeatmapLayout.rowsPerColumn) * HeatmapLayout.cellSize
            + CGFloat(HeatmapLayout.rowsPerColumn - 1) * HeatmapLayout.cellSpacing
    }

    // MARK: - Grid Construction

    // MARK: @MainActor Snapshot Extraction, Then Off-Main Aggregation
    //
    // LogSnapshot.init(from:) is @MainActor-isolated (Phase 2) because reading
    // properties on a @Model type from a different actor is a Swift 6 data-race
    // violation. The map over board.logs happens here, on @MainActor, before
    // the await — buildDayGrid itself then runs on the cooperative thread pool
    // with the resulting Sendable [LogSnapshot] value, never touching
    // ModelContext or the @Model objects directly.

    private func rebuildGrid() async {
        isLoading = true
        let snapshots = (board.logs ?? []).map(LogSnapshot.init(from:))
        let result = await HeatmapDataProvider.buildDayGrid(
            snapshots: snapshots,
            target: board.effectiveTarget,
            windowDays: windowDays,
            calendar: .current
        )
        // .task(id:) cancels the prior task when id changes, but
        // buildDayGrid doesn't check Task.isCancelled internally — without
        // this guard, an older, still-in-flight computation could complete
        // after a newer one and overwrite its result with stale data.
        guard !Task.isCancelled else { return }
        cells = result
        isLoading = false
    }
}

// MARK: - HeatmapCellView

/// A single calendar-day cell. Pure presentation over an already-computed
/// `DayCell` — no aggregation, no date math, nothing beyond colour lookup and
/// accessibility label formatting.
private struct HeatmapCellView: View {

    let cell: DayCell
    let colorIndex: Int
    let unitLabel: String?

    var body: some View {
        RoundedRectangle(cornerRadius: HeatmapLayout.cellCornerRadius, style: .continuous)
            .fill(ColorPalette.heatmapColor(forColorIndex: colorIndex, ratio: cell.intensity))
            .frame(width: HeatmapLayout.cellSize, height: HeatmapLayout.cellSize)
            .overlay {
                if cell.isToday {
                    RoundedRectangle(cornerRadius: HeatmapLayout.cellCornerRadius, style: .continuous)
                        .strokeBorder(.primary, lineWidth: HeatmapLayout.todayBorderWidth)
                }
            }
            .accessibilityLabel(accessibilityLabelText)
            // Dynamic Type does not resize fixed-geometry grid cells — scaling
            // 365 cells with text size would make the grid unusably large at
            // accessibility text sizes. The cell's fixed size is a deliberate,
            // intensity-conveying visual element, not text content; its meaning
            // is fully available via VoiceOver's accessibilityLabel regardless
            // of the user's Dynamic Type setting. This mirrors how Apple's own
            // Screen Time / Activity heatmap-style visualizations handle the
            // same tradeoff.
    }

    // MARK: Accessibility Label Formatting
    //
    // Matches the pattern established for HabitCardView (Phase 4) and
    // HabitDetailView's header (Phase 5.1): natural-language date, value, and
    // goal comparison — no raw ratios or unformatted Doubles read aloud.

    private var accessibilityLabelText: String {
        let dateText = cell.date.formatted(.dateTime.weekday(.wide).month(.wide).day())

        guard cell.hasEntry else {
            return "\(dateText), no entry"
        }

        let totalText = cell.total.formatted(.number.precision(.fractionLength(0...1)))
        let unit = unitLabel ?? ""
        let comparison = cell.intensity >= 1.0 ? "at or above goal" : "below goal"
        let valueText = unit.isEmpty ? totalText : "\(totalText) \(unit)"

        return "\(dateText), \(valueText), \(comparison)"
    }
}

// MARK: - Preview

// MARK: Preview Fixture Setup
//
// Same fix applied to RootNavigationView.swift's Preview: #Preview's
// macro-synthesized closure applies a ViewBuilder-style transform to every
// statement inside it, and a bare assignment (board.logs = logs) is a
// Void-evaluating expression the transform can't accept. Extracting fixture
// setup into a plain, non-ViewBuilder function removes the restriction
// entirely.

@MainActor
private func makeSeededPreviewBoard() -> HabitBoard {
    let board = HabitBoard(name: "Running", metricType: HabitBoard.MetricType.quantitative.rawValue,
                            targetValue: 5.0, unitLabel: "mi", colorIndex: 0)
    var logs: [LogEntry] = []
    let calendar = Calendar.current
    for offset in stride(from: 0, to: 200, by: 3) {
        guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
        logs.append(LogEntry(timestamp: date, value: Double.random(in: 1...6), boardID: board.id, board: board))
    }
    board.logs = logs
    return board
}

#Preview {
    ScrollView {
        HeatmapView(board: makeSeededPreviewBoard())
            .padding()
    }
}
