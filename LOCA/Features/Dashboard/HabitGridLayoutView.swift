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

    private var needsActionBoards: [(board: HabitBoard, state: HabitState)] {
        boardsWithState.filter { $0.state == .needsAction }
    }

    private var inProgressBoards: [(board: HabitBoard, state: HabitState)] {
        boardsWithState.filter { $0.state == .inProgress }
    }

    private var behindBoards: [(board: HabitBoard, state: HabitState)] {
        boardsWithState.filter { $0.state == .behind }
    }

    private var doneBoards: [(board: HabitBoard, state: HabitState)] {
        boardsWithState.filter { $0.state == .done }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xxl) {

            // NEEDS ACTION ZONE
            if !needsActionBoards.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("To Do")

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(needsActionBoards, id: \.board.id) { item in
                            NavigationLink(destination: HabitDetailView(board: item.board)) {
                                GridHabitCard(board: item.board, onCheck: { onCheckBinary(item.board) })
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.lg)
            }

            // IN PROGRESS ZONE
            if !inProgressBoards.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("In Progress")

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(inProgressBoards, id: \.board.id) { item in
                            NavigationLink(destination: HabitDetailView(board: item.board)) {
                                GridHabitCard(board: item.board, onCheck: { onCheckBinary(item.board) })
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.lg)
            }

            // BEHIND ZONE
            if !behindBoards.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("Needs Attention")

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(behindBoards, id: \.board.id) { item in
                            NavigationLink(destination: HabitDetailView(board: item.board)) {
                                GridHabitCard(board: item.board, onCheck: { onCheckBinary(item.board) })
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.lg)
            }

            // DONE ZONE
            if !doneBoards.isEmpty {
                VStack(alignment: .leading, spacing: DS.Space.lg) {
                    SectionHeader("Done Today")

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(doneBoards, id: \.board.id) { item in
                            NavigationLink(destination: HabitDetailView(board: item.board)) {
                                GridHabitCard(board: item.board, onCheck: { onCheckBinary(item.board) })
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.lg)
            }

            Spacer(minLength: DS.Space.xxxl)
        }
        .padding(.vertical, DS.Space.xl)
    }
}

// MARK: - Grid Habit Card

struct GridHabitCard: View {
    let board: HabitBoard
    let onCheck: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingCheckIn = false
    @State private var isLoggingQuick = false
    @State private var showSuccessBadge = false
    @State private var successValue: Double = 0

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
                        .font(DS.Text.body)
                }
                Text(board.name)
                    .font(DS.Text.body)
                    .fontWeight(.bold)
                    .foregroundStyle(DS.Color.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 13)
            .padding(.top, 13)
            .padding(.bottom, 10)

            // ── Mini heatmap ─────────────────────────────────────────
            GridMiniHeatmap(board: board)
                .padding(.horizontal, 10)

            Spacer(minLength: 16)

            // ── Check button ─────────────────────────────────────────
            GridCheckButton(
                board: board,
                todayLogged: todayLogged,
                todayValue: todayValue,
                isLogging: isLoggingQuick,
                showSuccess: showSuccessBadge,
                successValue: successValue,
                onCheck: {
                    if board.metric == .binary {
                        logBinaryQuick()
                    } else {
                        showingCheckIn = true
                    }
                }
            )
            .padding(.horizontal, 13)
            .padding(.top, 8)
            .padding(.bottom, 13)
        }
        // minHeight (not fixed height) so the card grows rather than clips at large
        // Dynamic Type sizes; P7.1 verifies row symmetry across the pair.
        .frame(minHeight: 236)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .fill(board.useColorBackground
                    ? ColorPalette[board.colorIndex].opacity(0.12)
                    : DS.Color.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .stroke(ColorPalette[board.colorIndex].opacity(0.18), lineWidth: 0.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .sheet(isPresented: $showingCheckIn) {
            CheckInEditorView(mode: .create, board: board)
                .presentationDetents([.medium, .large])
        }
        .id("\(board.id)-\(board.logs?.count ?? -1)")
    }

    private func logBinaryQuick() {
        isLoggingQuick = true
        Haptics.impact(.light)

        do {
            let isNowLogged = try CheckInWriter.toggleBinary(board: board, context: modelContext)
            if isNowLogged {
                Haptics.notify(.success)
                withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                    showSuccessBadge = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                        showSuccessBadge = false
                    }
                    isLoggingQuick = false
                }
            } else {
                withAnimation(DS.Motion.settle(reduceMotion: reduceMotion)) {
                    isLoggingQuick = false
                }
            }
        } catch {
            isLoggingQuick = false
            Haptics.notify(.error)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .opacity(cellsByDate.isEmpty ? 0.5 : 1.0)
        .animation(DS.Motion.settle(reduceMotion: reduceMotion), value: cellsByDate.isEmpty)
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Week-anchor date: locale's week-start of the column's week + dayIndex days.
    private var cellDate: Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let todayWeekday = cal.component(.weekday, from: today)
        let daysFromWeekStart = (todayWeekday - cal.firstWeekday + 7) % 7
        guard let currentWeekStart = cal.date(byAdding: .day, value: -daysFromWeekStart, to: today),
              let columnWeekStart  = cal.date(byAdding: .weekOfYear, value: -(totalWeeks - 1 - weekIndex), to: currentWeekStart),
              let date             = cal.date(byAdding: .day, value: dayIndex, to: columnWeekStart)
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

    // Active-cell opacity tiers — applied only when intensity > 0
    private var activeOpacity: Double {
        let intensity = cell?.intensity ?? 0
        if intensity >= 1.0 { return 1.0 }
        if intensity >= 0.5 { return 0.55 }
        return 0.30
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .fill(
                    isFuture
                        // Future: neutral recessed tone — conveys "not yet" in both themes
                        ? DS.Color.heatmapCellFuture
                        : (cell?.intensity ?? 0) > 0
                            ? ColorPalette[colorIndex].opacity(activeOpacity)
                            // Inactive: neutral adaptive tone — visible in light and dark
                            : DS.Color.heatmapCellEmpty
                )
                .frame(width: size, height: size)

            if isToday {
                RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                    .stroke(DS.Color.textPrimary.opacity(0.80), lineWidth: 1.2)
                    .frame(width: size, height: size)
            }
        }
        .transition(.opacity)
        .animation(DS.Motion.settle(reduceMotion: reduceMotion), value: cellsByDate)
    }
}

// MARK: - Check Button

private struct GridCheckButton: View {
    let board: HabitBoard
    let todayLogged: Bool
    let todayValue: Double
    let isLogging: Bool
    let showSuccess: Bool
    let successValue: Double
    let onCheck: () -> Void

    var body: some View {
        Button(action: onCheck) {
            Group {
                if showSuccess && board.metric == .binary {
                    // Success state: checkmark for binary
                    Image(systemName: "checkmark.circle.fill")
                        .font(DS.Text.body)
                        .foregroundStyle(Color.black.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(ColorPalette[board.colorIndex], in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
                        .scaleEffect(1.0)
                } else if isLogging {
                    // Loading state: spinner
                    ProgressView()
                        .tint(DS.Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(DS.Color.textPrimary.opacity(0.06), in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
                } else if todayLogged {
                    // Logged — solid accent fill. Content stays dark for contrast on the
                    // saturated fill (consistent across light/dark since the accent is the
                    // same hue in both).
                    HStack(spacing: 7) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(DS.Text.body)
                        if board.metric == .quantitative {
                            ValueText(
                                String(format: todayValue.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", todayValue),
                                font: DS.Text.valueCompact
                            )
                        }
                    }
                    .foregroundStyle(Color.black.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(ColorPalette[board.colorIndex], in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
                } else {
                    // Unlogged — recessed neutral control (concentric: control radius
                    // inside a card radius), muted plus.
                    Image(systemName: "plus")
                        .font(DS.Text.heading)
                        .foregroundStyle(DS.Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(DS.Color.textPrimary.opacity(0.06), in: RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous))
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLogging)
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
