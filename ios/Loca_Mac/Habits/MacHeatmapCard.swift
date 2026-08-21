import SwiftUI

// MARK: - MacHeatmapCard   (H3)

/// 182-day (26-week) heatmap for the Mac detail column.
///
/// Reuses the `RefHeatCell` rendering from `HabitDetailView` directly —
/// same intensity tiers, same today-ring, same future-cell rule. The 26-week
/// grid fills the detail column cleanly with a stable fixed-column layout.
struct MacHeatmapCard: View {

    let board: HabitBoard

    private let cols:   Int     = 26
    private let gap:    CGFloat = DS.Mac.heatmapCellGap
    private let cell:   CGFloat = DS.Mac.heatmapCellSize
    private let labelW: CGFloat = 32
    private let hPad:   CGFloat = DS.Space.lg
    private let vPad:   CGFloat = DS.Space.md

    private let dayLabels = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

    @State private var cellsByDate: [Date: DayCell] = [:]

    var body: some View {
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
            ScrollView(.horizontal, showsIndicators: false) {
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
                                    cellSize:    cell
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, hPad)
                .padding(.bottom, vPad)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(DS.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .stroke(DS.Color.border.opacity(0.35), lineWidth: 1)
        )
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
            await MainActor.run {
                cellsByDate = Dictionary(uniqueKeysWithValues: cells.map { ($0.date, $0) })
            }
        }
    }
}
