//
//  HabitGridLayoutView.swift
//  LOCA
//
//  Phase 15.1 — Grid layout with adaptive columns (simplified).
//

import SwiftUI
import SwiftData

struct HabitGridLayoutView: View {
    let boardsWithState: [(board: HabitBoard, state: HabitState)]
    let onCheckBinary: (HabitBoard) -> Void

    @Environment(\.horizontalSizeClass) var sizeClass

    private var columnCount: Int {
        // Adaptive based on device size class
        sizeClass == .compact ? 2 : 3
    }

    private var spacing: CGFloat { 14 }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount),
            spacing: spacing
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

    private var todayValue: Double {
        (board.logs ?? [])
            .filter { Calendar.current.isDateInToday($0.timestamp) }
            .reduce(0, { $0 + $1.value })
    }

    private var todayLogged: Bool { todayValue > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack(alignment: .center, spacing: 7) {
                if let emoji = board.emoji, !emoji.isEmpty {
                    Text(emoji).font(.system(size: 16))
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

            GridMiniHeatmap(board: board)
                .padding(.horizontal, 10)

            Spacer(minLength: 0)

            GridCheckButton(
                board: board,
                todayLogged: todayLogged,
                todayValue: todayValue,
                onCheck: {
                    if board.metric == .binary {
                        onCheck()
                    } else {
                        showingCheckIn = true
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

// MARK: - Mini Heatmap

private struct GridMiniHeatmap: View {
    let board: HabitBoard
    private let cols = 8
    private let rows = 7
    private let gap: CGFloat = 3.5

    var body: some View {
        GeometryReader { geo in
            let cellSize = (geo.size.width - gap * CGFloat(cols - 1)) / CGFloat(cols)

            VStack(alignment: .leading, spacing: gap) {
                ForEach(0..<rows, id: \.self) { dayIdx in
                    HStack(spacing: gap) {
                        ForEach(0..<cols, id: \.self) { weekIdx in
                            GridMiniCell(
                                board: board,
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
    }

    private func heatmapHeight() -> CGFloat {
        let approxCellW: CGFloat = (121 - gap * CGFloat(cols - 1)) / CGFloat(cols)
        return approxCellW * CGFloat(rows) + gap * CGFloat(rows - 1)
    }
}

// MARK: - Mini Cell

private struct GridMiniCell: View {
    let board: HabitBoard
    let dayIndex: Int
    let weekIndex: Int
    let totalWeeks: Int
    let size: CGFloat

    private var date: Date? {
        let today = Calendar.current.startOfDay(for: .now)
        let weeksBack = totalWeeks - 1 - weekIndex
        let daysBack  = weeksBack * 7 + dayIndex
        return Calendar.current.date(byAdding: .day, value: -daysBack, to: today)
    }

    private var isToday: Bool {
        guard let d = date else { return false }
        return Calendar.current.isDateInToday(d)
    }

    private var isFuture: Bool {
        guard let d = date else { return false }
        return d > Date()
    }

    private var total: Double {
        guard let d = date else { return 0 }
        let start = Calendar.current.startOfDay(for: d)
        guard let end = Calendar.current.date(byAdding: .day, value: 1, to: start) else { return 0 }
        return (board.logs ?? [])
            .filter { $0.timestamp >= start && $0.timestamp < end }
            .reduce(0, { $0 + $1.value })
    }

    private var opacity: Double {
        if isFuture { return 0.07 }
        guard total > 0 else { return 0.15 }
        let r = total / board.effectiveTarget
        if r >= 1.0 { return 1.0 }
        if r >= 0.5 { return 0.55 }
        return 0.30
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .fill(ColorPalette[board.colorIndex].opacity(opacity))
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
                    .background(ColorPalette[board.colorIndex],
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(white: 0.45))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Color(white: 0.15),
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        HabitGridLayoutView(boardsWithState: [], onCheckBinary: { _ in })
    }
}
