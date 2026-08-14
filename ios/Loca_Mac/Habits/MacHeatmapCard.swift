import SwiftUI

// MARK: - MacHeatmapCard   (H3)

/// 182-day (26-week) heatmap for the Mac detail column.
///
/// Reuses the `RefHeatCell` rendering from `HabitDetailView` directly —
/// same intensity tiers, same today-ring, same future-cell rule. The only
/// Mac-specific adaptation is the cell size: `DS.Mac.heatmapCellSize` (13 pt)
/// vs iOS's 11 pt, so the 26-week grid fills the 380+ pt detail column
/// without scrolling.
///
/// The grid is calculated via `GeometryReader` so the column count adjusts
/// if the user resizes the window — columns are added or removed to fill
/// the available width at the current cell size.
struct MacHeatmapCard: View {

    let board: HabitBoard

    private let gap:    CGFloat = DS.Mac.heatmapCellGap
    private let cell:   CGFloat = DS.Mac.heatmapCellSize
    private let labelW: CGFloat = 32
    private let hPad:   CGFloat = DS.Space.lg
    private let vPad:   CGFloat = DS.Space.md

    private let dayLabels = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

    @State private var cellsByDate: [Date: DayCell] = [:]

    var body: some View {
        GeometryReader { geo in
            let usable = geo.size.width - hPad * 2 - labelW - gap
            let cols   = max(1, Int((usable + gap) / (cell + gap)))
            let cSize  = (usable - gap * CGFloat(cols - 1)) / CGFloat(cols)
            let gridH  = (cSize + gap) * 7 - gap + vPad * 2

            VStack(alignment: .leading, spacing: DS.Space.sm) {
                // Title row
                HStack(spacing: DS.Space.xs) {
                    Image(systemName: "calendar.circle")
                        .font(.caption)
                        .foregroundStyle(ColorPalette[board.colorIndex])
                    Text("26-WEEK HEATMAP")
                        .font(DS.Text.footnote)
                        .foregroundStyle(DS.Color.textSecondary)
                        .tracking(0.5)
                }
                .padding(.horizontal, hPad)
                .padding(.top, vPad)

                // Grid
                VStack(spacing: gap) {
                    ForEach(0..<7, id: \.self) { d in
                        HStack(spacing: gap) {
                            Text(dayLabels[d])
                                .font(DS.Text.footnote)
                                .foregroundStyle(DS.Color.textSecondary)
                                .frame(width: labelW, alignment: .leading)
                            ForEach(0..<cols, id: \.self) { w in
                                RefHeatCell(
                                    colorIndex:  board.colorIndex,
                                    cellsByDate: cellsByDate,
                                    dayIndex:    d,
                                    weekIndex:   w,
                                    totalCols:   cols,
                                    cellSize:    cSize
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, hPad)
                .padding(.bottom, vPad)
                .frame(height: gridH)
            }
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .fill(DS.Color.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                    .stroke(DS.Color.border.opacity(0.35), lineWidth: 1)
            )
        }
        .frame(height: heatmapCardHeight())
        .task(id: "\(board.id)-\(board.logs?.count ?? -1)-\(board.targetValue ?? -1)") {
            let snapshots = (board.logs ?? []).map(LogSnapshot.init(from:))
            let logs = board.logs ?? []
            let target: Double
            if board.metric == .quantitative && board.targetValue == nil && !logs.isEmpty {
                let average = logs.reduce(0.0) { $0 + $1.value } / Double(logs.count)
                target = max(average, 1.0)
            } else {
                target = board.effectiveTarget
            }
            let cells = await HeatmapDataProvider.buildDayGrid(
                snapshots:  snapshots,
                target:     target,
                windowDays: 182
            )
            cellsByDate = Dictionary(uniqueKeysWithValues: cells.map { ($0.date, $0) })
        }
    }

    private func heatmapCardHeight() -> CGFloat {
        // Title row ~28 + top-pad + grid + bottom-pad
        28 + vPad + (cell + gap) * 7 - gap + vPad * 2
    }
}
