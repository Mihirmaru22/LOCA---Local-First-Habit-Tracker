//
//  HabitGridLayoutView.swift
//  LOCA
//
//  Phase 14.4 — Grid layout with mini heatmaps.
//
//  2-column grid of habit cards. Each card displays a small heatmap
//  (7-14 recent days) with intensity-coded cells, streak count, and
//  today's value.
//

import SwiftUI
import SwiftData

struct HabitGridLayoutView: View {
    let boardsWithState: [(board: HabitBoard, state: HabitState)]
    let onCheckBinary: (HabitBoard) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: DS.Space.md),
        GridItem(.flexible(), spacing: DS.Space.md)
    ]

    private var sortedBoards: [(board: HabitBoard, state: HabitState)] {
        boardsWithState.sorted { a, b in
            let stateOrder: [HabitState] = [.needsAction, .behind, .inProgress, .done]
            let aIndex = stateOrder.firstIndex(of: a.state) ?? 4
            let bIndex = stateOrder.firstIndex(of: b.state) ?? 4
            return aIndex < bIndex
        }
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: DS.Space.md) {
            ForEach(sortedBoards, id: \.board.id) { item in
                NavigationLink(destination: HabitDetailView(board: item.board)) {
                    HabitGridCardWithHeatmap(
                        board: item.board,
                        state: item.state,
                        onCheckBinary: { onCheckBinary(item.board) }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DS.Space.lg)
    }
}

// MARK: - Grid Card with Mini Heatmap

struct HabitGridCardWithHeatmap: View {
    let board: HabitBoard
    let state: HabitState
    let onCheckBinary: () -> Void

    private var todaysTotal: Double {
        (board.logs ?? [])
            .filter { $0.timestamp.isToday() }
            .reduce(0.0) { $0 + $1.value }
    }

    private var currentStreakValue: Int {
        board.currentStreak
    }

    private var cardBackgroundColor: Color {
        ColorPalette[board.colorIndex].opacity(0.15)
    }

    private var heatmapDays: [Date] {
        let today = Calendar.current.startOfDay(for: .now)
        let dayCount = 14
        return (0..<dayCount)
            .compactMap { offset in
                Calendar.current.date(byAdding: .day, value: -(dayCount - 1 - offset), to: today)
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            // Header: emoji + name
            HStack(spacing: DS.Space.sm) {
                Text(board.emoji)
                    .font(.title3)
                Text(board.name)
                    .font(DS.Text.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }

            // Mini heatmap grid (14 days in 2 rows of 7)
            VStack(spacing: 2) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<7, id: \.self) { col in
                            let index = row * 7 + col
                            if index < heatmapDays.count {
                                let date = heatmapDays[index]
                                MiniHeatmapCell(
                                    board: board,
                                    date: date
                                )
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Bottom: Streak + Value
            HStack(spacing: DS.Space.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Streak")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                    ValueText(
                        String(currentStreakValue),
                        font: DS.Text.valueCompact
                    )
                    .foregroundStyle(ColorPalette[board.colorIndex])
                }

                Spacer()

                // Today's value or check button
                if board.metricType == 0 {
                    // Binary: show checkmark or button
                    if todaysTotal >= 1.0 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(ColorPalette[board.colorIndex])
                    } else {
                        Button(action: onCheckBinary) {
                            Image(systemName: "circle")
                                .font(.title3)
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                    }
                } else {
                    // Quantitative: show value
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(board.unitLabel ?? "")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                        ValueText(
                            todaysTotal.formatted(.number.precision(.fractionLength(0...1))),
                            font: DS.Text.valueCompact
                        )
                        .foregroundStyle(
                            todaysTotal >= board.effectiveTarget
                                ? ColorPalette[board.colorIndex]
                                : DS.Color.textSecondary
                        )
                    }
                }
            }
        }
        .padding(DS.Space.md)
        .background(cardBackgroundColor, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(ColorPalette[board.colorIndex].opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - Mini Heatmap Cell

struct MiniHeatmapCell: View {
    let board: HabitBoard
    let date: Date

    private var dayLogs: [LogEntry] {
        (board.logs ?? [])
            .filter { Calendar.current.isDate($0.timestamp, inSameDayAs: date) }
    }

    private var totalValue: Double {
        dayLogs.reduce(0.0) { $0 + $1.value }
    }

    private var cellOpacity: Double {
        let ratio = totalValue / board.effectiveTarget
        return min(1.0, max(0.2, ratio))
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(
                dayLogs.isEmpty
                    ? DS.Color.surface
                    : ColorPalette[board.colorIndex].opacity(cellOpacity)
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
    }
}
