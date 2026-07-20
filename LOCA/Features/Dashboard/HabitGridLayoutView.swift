//
//  HabitGridLayoutView.swift
//  LOCA
//
//  Phase 15.1 — Grid layout, adaptive to window width.
//
//  Uses GeometryReader to compute column count dynamically:
//  - < 600pt  : 2 columns (iPhone)
//  - 600–900  : 3 columns (iPad portrait / small Mac window)
//  - 900–1200 : 4 columns (iPad landscape / medium Mac window)
//  - > 1200pt : 5 columns (large Mac window / external display)
//
//  Card height scales with column width to maintain proportions.
//

import SwiftUI
import SwiftData

// MARK: - HabitGridLayoutView

struct HabitGridLayoutView: View {
    let boardsWithState: [(board: HabitBoard, state: HabitState)]
    let onCheckBinary: (HabitBoard) -> Void

    var body: some View {
        GeometryReader { geo in
            let columnCount = columnCount(for: geo.size.width)
            let spacing: CGFloat = 14
            let totalSpacing = spacing * CGFloat(columnCount - 1)
            let horizontalPad: CGFloat = 16
            let cardWidth = (geo.size.width - totalSpacing - horizontalPad * 2) / CGFloat(columnCount)
            let cardHeight = cardHeight(for: cardWidth)

            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columnCount),
                    spacing: spacing
                ) {
                    ForEach(boardsWithState, id: \.board.id) { item in
                        NavigationLink(destination: HabitDetailView(board: item.board)) {
                            GridHabitCard(
                                board: item.board,
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                onCheck: { onCheckBinary(item.board) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, horizontalPad)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Adaptive helpers

    private func columnCount(for width: CGFloat) -> Int {
        switch width {
        case ..<600:   return 2
        case 600..<900: return 3
        case 900..<1200: return 4
        default:       return 5
        }
    }

    /// Card height scales with card width to maintain visual balance.
    private func cardHeight(for width: CGFloat) -> CGFloat {
        // Approx ratio from reference: card is ~1.3× taller than wide on iPhone.
        // On wider screens we flatten slightly for information density.
        let ratio: CGFloat = width < 200 ? 1.35 : width < 280 ? 1.25 : 1.15
        return (width * ratio).rounded()
    }
}

// MARK: - Grid Habit Card

struct GridHabitCard: View {
    let board: HabitBoard
    let cardWidth: CGFloat
    let cardHeight: CGFloat
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

            // ── Header ──────────────────────────────────────────────
            HStack(alignment: .center, spacing: 7) {
                if let emoji = board.emoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: clamp(cardWidth * 0.095, min: 13, max: 20)))
                }
                Text(board.name)
                    .font(.system(size: clamp(cardWidth * 0.09, min: 12, max: 16), weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 13)
            .padding(.top, 13)
            .padding(.bottom, 8)

            // ── Mini heatmap ─────────────────────────────────────────
            GridMiniHeatmap(board: board, cardWidth: cardWidth)
                .padding(.horizontal, 10)

            Spacer(minLength: 0)

            // ── Check button ─────────────────────────────────────────
            GridCheckButton(
                board: board,
                todayLogged: todayLogged,
                todayValue: todayValue,
                cardWidth: cardWidth,
                onCheck: {
                    if board.metric == .binary {
                        onCheck()
                    } else {
                        showingCheckIn = true
                    }
                }
            )
            .padding(.horizontal, 13)
            .padding(.top, 8)
            .padding(.bottom, 13)
        }
        .frame(width: cardWidth, height: cardHeight)
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

    private func clamp(_ value: CGFloat, min minVal: CGFloat, max maxVal: CGFloat) -> CGFloat {
        Swift.max(minVal, Swift.min(maxVal, value))
    }
}

// MARK: - Mini Heatmap (adaptive cols × 7 rows)

private struct GridMiniHeatmap: View {
    let board: HabitBoard
    let cardWidth: CGFloat

    private var cols: Int {
        // More columns on wider cards
        switch cardWidth {
        case ..<160: return 7
        case 160..<220: return 8
        case 220..<300: return 10
        default: return 12
        }
    }

    private let rows = 7
    private let gap: CGFloat = 3.5

    var body: some View {
        let innerWidth = cardWidth - 20  // subtract horizontal padding
        let cellSize = (innerWidth - gap * CGFloat(cols - 1)) / CGFloat(cols)
        let height = cellSize * CGFloat(rows) + gap * CGFloat(rows - 1)

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
        .frame(height: height)
    }
}

// MARK: - Mini Heatmap Cell

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
    let cardWidth: CGFloat
    let onCheck: () -> Void

    private var buttonHeight: CGFloat { clamp(cardWidth * 0.18, min: 36, max: 48) }
    private var fontSize: CGFloat     { clamp(cardWidth * 0.075, min: 12, max: 16) }

    var body: some View {
        Button(action: onCheck) {
            Group {
                if todayLogged {
                    HStack(spacing: 7) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: fontSize, weight: .semibold))
                        if board.metric == .quantitative {
                            Text(String(
                                format: todayValue.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f",
                                todayValue))
                                .font(.system(size: fontSize, weight: .semibold))
                        }
                    }
                    .foregroundStyle(Color.black.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(ColorPalette[board.colorIndex],
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: fontSize + 2, weight: .semibold))
                        .foregroundStyle(Color(white: 0.45))
                        .frame(maxWidth: .infinity)
                        .frame(height: buttonHeight)
                        .background(Color(white: 0.15),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func clamp(_ value: CGFloat, min minVal: CGFloat, max maxVal: CGFloat) -> CGFloat {
        Swift.max(minVal, Swift.min(maxVal, value))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HabitGridLayoutView(boardsWithState: [], onCheckBinary: { _ in })
    }
}
