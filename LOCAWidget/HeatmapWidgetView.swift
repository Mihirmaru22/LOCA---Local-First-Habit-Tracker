//
//  HeatmapWidgetView.swift
//  LOCAWidget
//
//  Phase 9.1 — WidgetKit: Widget View
//
//  Renders a habit's heatmap, streak, and today's progress from a HeatmapEntry.
//  Interactive check-in (Button(intent:)) is added in Phase 9.2.
//

import WidgetKit
import SwiftUI

// MARK: - HeatmapWidgetView

struct HeatmapWidgetView: View {

    let entry: HeatmapEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let board = entry.board {
            content(for: board)
        } else {
            EmptyHabitView()
        }
    }

    // MARK: Configured Content

    @ViewBuilder
    private func content(for board: HeatmapEntry.BoardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            header(for: board)
            heatmap(for: board)
            Spacer(minLength: 0)
            Text(todayText(for: board))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: Header

    @ViewBuilder
    private func header(for board: HeatmapEntry.BoardSnapshot) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(ColorPalette[board.colorIndex])
                .frame(width: 10, height: 10)
            Text(board.name)
                .font(.headline)
                .lineLimit(1)
            Spacer(minLength: 4)
            if board.currentStreak > 0 {
                Label("\(board.currentStreak)", systemImage: "flame.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
            }
        }
    }

    // MARK: Heatmap

    @ViewBuilder
    private func heatmap(for board: HeatmapEntry.BoardSnapshot) -> some View {
        let metrics = gridMetrics
        let visible = Array(entry.cells.suffix(metrics.dayCount))
        let rows = Array(
            repeating: GridItem(.fixed(metrics.cell), spacing: metrics.spacing),
            count: 7
        )

        LazyHGrid(rows: rows, spacing: metrics.spacing) {
            ForEach(visible) { cell in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(ColorPalette.heatmapColor(forColorIndex: board.colorIndex, ratio: cell.intensity))
                    .frame(width: metrics.cell, height: metrics.cell)
                    .overlay {
                        if cell.isToday {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .strokeBorder(.primary.opacity(0.5), lineWidth: 1)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Cell size, spacing, and day count tuned per widget family so the grid
    /// fills the available width without clipping.
    private var gridMetrics: (cell: CGFloat, spacing: CGFloat, dayCount: Int) {
        switch family {
        case .systemLarge:
            return (cell: 13, spacing: 3, dayCount: 140)   // 20 weeks
        default:
            return (cell: 11, spacing: 2.5, dayCount: 98)  // 14 weeks (medium)
        }
    }

    // MARK: Today Text

    private func todayText(for board: HeatmapEntry.BoardSnapshot) -> String {
        switch board.metric {
        case .binary:
            return board.todayTotal > 0 ? "Done today" : "Not logged today"
        case .quantitative:
            let done = board.todayTotal.formatted(.number.precision(.fractionLength(0...1)))
            let goal = board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))
            let unit = board.unitLabel.flatMap { $0.isEmpty ? nil : " \($0)" } ?? ""
            return "Today: \(done) / \(goal)\(unit)"
        }
    }
}

// MARK: - EmptyHabitView

/// Shown when no habit is configured and none can be defaulted to (e.g. before
/// any habit exists, or after the configured one was deleted).
struct EmptyHabitView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No habit yet")
                .font(.subheadline.weight(.semibold))
            Text("Add a habit in LOCA, then long-press to choose it.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
