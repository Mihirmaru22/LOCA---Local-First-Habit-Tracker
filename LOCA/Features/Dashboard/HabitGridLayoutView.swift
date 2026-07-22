//
//  HabitGridLayoutView.swift
//  LOCA
//
//  Phase 15.1 — Grid layout, pixel-perfect.
//  No NavigationStack — lives inside HabitListView's existing stack.
//

import SwiftUI
import SwiftData

// MARK: - HabitGridLayoutView

struct HabitGridLayoutView: View {
    // Passed from HabitListView — avoids double @Query
    let boardsWithState: [(board: HabitBoard, state: HabitState)]
    let onCheckBinary: (HabitBoard) -> Void

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
            spacing: 14
        ) {
            ForEach(boardsWithState, id: \.board.id) { item in
                NavigationLink(destination: HabitDetailView(board: item.board)) {
                    GridHabitCard(board: item.board, onCheck: { onCheckBinary(item.board) })
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Grid Habit Card

struct GridHabitCard: View {
    let board: HabitBoard
    let onCheck: () -> Void

    @State private var showingCheckIn = false

    // Today's logged value
    private var todayValue: Double {
        (board.logs ?? [])
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .reduce(0, { $0 + $1.value })
    }

    private var todayLogged: Bool { todayValue > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ──────────────────────────────────────────────
            HStack(alignment: .center, spacing: 7) {
                if let emoji = board.emoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 16))
                }
                Text(board.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 13)
            .padding(.top, 13)
            .padding(.bottom, 10)

            // ── Mini heatmap ─────────────────────────────────────────
            GridMiniHeatmap(board: board)
                .padding(.horizontal, 10)

            Spacer(minLength: 0)

            // ── Check button ─────────────────────────────────────────
            GridCheckButton(
                board: board,
                todayLogged: todayLogged,
                todayValue: todayValue,
                onCheck: {
                    if board.metric == .binary {
                        onCheck()           // direct DB write via HabitListView
                    } else {
                        showingCheckIn = true   // open sheet for amount
                    }
                }
            )
            .padding(.horizontal, 13)
            .padding(.top, 10)
            .padding(.bottom, 13)
        }
        .frame(height: 236)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ColorPalette[board.colorIndex].opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(ColorPalette[board.colorIndex].opacity(0.18), lineWidth: 0.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .sheet(isPresented: $showingCheckIn) {
            AddCheckInSheetView(board: board)
        }
    }
}

// MARK: - Mini Heatmap (8 cols × 7 rows = 56 days)

private struct GridMiniHeatmap: View {
    let board: HabitBoard
    private let cols    = 8
    private let rows    = 7
    private let gap: CGFloat = 3.5

    // Pre-aggregated off-main; O(1) lookup per cell at render time.
    @State private var cellsByDate: [Date: DayCell] = [:]

    var body: some View {
        GeometryReader { geo in
            let cellSize = (geo.size.width - gap * CGFloat(cols - 1)) / CGFloat(cols)

            VStack(alignment: .leading, spacing: gap) {
                ForEach(0..<rows, id: \.self) { dayIdx in
                    HStack(spacing: gap) {
                        ForEach(0..<cols, id: \.self) { weekIdx in
                            GridMiniCell(
                                colorIndex: board.colorIndex,
                                cellsByDate: cellsByDate,
                                dayIndex: dayIdx,
                                weekIndex: weekIdx,
                                totalWeeks: cols,
                                size: cellSize
                            )
                        }
                    }
                }
            }
        }
        .frame(height: heatmapHeight())
        // 56 days covers all cells in the 8×7 grid regardless of day-of-week alignment.
        .task(id: "\(board.id)-\(board.logs?.count ?? -1)") {
            let snapshots = (board.logs ?? []).map(LogSnapshot.init(from:))
            let target    = board.effectiveTarget
            let newCells  = await HeatmapDataProvider.buildDayGrid(
                snapshots:  snapshots,
                target:     target,
                windowDays: 56
            )
            cellsByDate = Dictionary(uniqueKeysWithValues: newCells.map { ($0.date, $0) })
        }
    }

    private func heatmapHeight() -> CGFloat {
        // We estimate cell width based on card width (~161pt inner - 20pt pad = 141pt)
        let approxCellW: CGFloat = (141 - gap * CGFloat(cols - 1)) / CGFloat(cols)
        return approxCellW * CGFloat(rows) + gap * CGFloat(rows - 1)
    }
}

// MARK: - Mini Heatmap Cell

private struct GridMiniCell: View {
    let colorIndex: Int
    let cellsByDate: [Date: DayCell]
    let dayIndex: Int
    let weekIndex: Int
    let totalWeeks: Int
    let size: CGFloat

    // Week-anchor date: Sunday of the column's week + dayIndex days.
    private var cellDate: Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let todayWeekday = cal.component(.weekday, from: today) - 1  // 0 = Sunday
        guard let currentSunday = cal.date(byAdding: .day, value: -todayWeekday, to: today),
              let columnSunday  = cal.date(byAdding: .weekOfYear, value: -(totalWeeks - 1 - weekIndex), to: currentSunday),
              let date           = cal.date(byAdding: .day, value: dayIndex, to: columnSunday)
        else { return nil }
        return date
    }

    private var isToday: Bool {
        guard let d = cellDate else { return false }
        return Calendar.current.isDateInToday(d)
    }

    private var isFuture: Bool {
        guard let d = cellDate else { return false }
        return d > Calendar.current.startOfDay(for: Date())
    }

    private var cell: DayCell? { cellsByDate[cellDate ?? .distantPast] }

    private var opacity: Double {
        if isFuture { return 0.07 }
        let intensity = cell?.intensity ?? 0
        if intensity <= 0 { return 0.15 }
        if intensity >= 1.0 { return 1.0 }
        if intensity >= 0.5 { return 0.55 }
        return 0.30
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .fill(ColorPalette[colorIndex].opacity(opacity))
                .frame(width: size, height: size)

            if isToday {
                RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                    .stroke(Color.white.opacity(0.80), lineWidth: 1.2)
                    .frame(width: size, height: size)
            }
        }
    }
}

// MARK: - Check Button

private struct GridCheckButton: View {
    let board: HabitBoard
    let todayLogged: Bool
    let todayValue: Double
    let onCheck: () -> Void

    var body: some View {
        Button(action: onCheck) {
            Group {
                if todayLogged {
                    // Logged — habit color fill, dark content
                    HStack(spacing: 7) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                        if board.metric == .quantitative {
                            Text(String(format: todayValue.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", todayValue))
                                .font(.system(size: 15, weight: .semibold))
                        }
                    }
                    .foregroundStyle(Color.black.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(ColorPalette[board.colorIndex], in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    // Unlogged — neutral dark fill, muted plus
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(white: 0.45))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color(white: 0.15), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            HabitGridLayoutView(boardsWithState: [], onCheckBinary: { _ in })
        }
    }
}
