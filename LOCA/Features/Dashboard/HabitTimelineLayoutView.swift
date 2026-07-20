//
//  HabitTimelineLayoutView.swift
//  LOCA
//
//  Phase 15.1 — Timeline layout, adaptive to window width.
//
//  Narrow (iPhone): single-column full-width cards.
//  Wide (iPad/Mac): two-column grid capped at 1100pt centered.
//

import SwiftUI
import SwiftData

struct HabitTimelineLayoutView: View {
    let boardsWithState: [(board: HabitBoard, state: HabitState)]
    let onCheckBinary: (HabitBoard) -> Void

    private var sortedBoards: [(board: HabitBoard, state: HabitState)] {
        boardsWithState.sorted { $0.board.createdAt > $1.board.createdAt }
    }

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width >= 700
            let maxContentWidth: CGFloat = isWide ? 1100 : geo.size.width
            let hPad: CGFloat = isWide ? 0 : DS.Space.lg
            let spacing: CGFloat = DS.Space.md

            ScrollView {
                Group {
                    if isWide {
                        // 2-column layout on Mac / iPad landscape
                        let cols = [GridItem(.flexible(), spacing: spacing),
                                    GridItem(.flexible(), spacing: spacing)]
                        LazyVGrid(columns: cols, spacing: spacing) {
                            ForEach(sortedBoards, id: \.board.id) { item in
                                NavigationLink(destination: HabitDetailView(board: item.board)) {
                                    HabitTimelineCard(
                                        board: item.board,
                                        state: item.state,
                                        onCheckBinary: { onCheckBinary(item.board) }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        // Single-column on iPhone
                        VStack(alignment: .leading, spacing: spacing) {
                            ForEach(sortedBoards, id: \.board.id) { item in
                                NavigationLink(destination: HabitDetailView(board: item.board)) {
                                    HabitTimelineCard(
                                        board: item.board,
                                        state: item.state,
                                        onCheckBinary: { onCheckBinary(item.board) }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxWidth: maxContentWidth)
                .padding(.horizontal, hPad)
                .padding(.vertical, DS.Space.lg)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Timeline Card

struct HabitTimelineCard: View {
    let board: HabitBoard
    let state: HabitState
    let onCheckBinary: () -> Void

    private var todaysTotal: Double {
        (board.logs ?? [])
            .filter { $0.timestamp.isToday() }
            .reduce(0.0) { $0 + $1.value }
    }

    private var stateColor: Color {
        switch state {
        case .needsAction, .behind: return ColorPalette[board.colorIndex]
        case .inProgress:           return DS.Color.textSecondary
        case .done:                 return DS.Color.textTertiary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            // Header: state dot + name + label
            HStack(spacing: DS.Space.md) {
                Circle()
                    .fill(stateColor)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(DS.Color.background, lineWidth: 2))

                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    HStack {
                        Text(board.name)
                            .font(DS.Text.heading)
                            .lineLimit(1)
                        Spacer()
                        Text(stateLabel)
                            .font(DS.Text.caption)
                            .foregroundStyle(stateColor)
                            .tracking(0.5)
                    }
                    if let unit = board.unitLabel, !unit.isEmpty {
                        Text("\(unit) daily target")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
                Spacer()

                if state == .needsAction && board.metricType == 0 {
                    Button(action: onCheckBinary) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(ColorPalette[board.colorIndex])
                    }
                }
            }

            // Stats row
            HStack(spacing: DS.Space.lg) {
                statCell(label: "Today",
                         value: todaysTotal.formatted(.number.precision(.fractionLength(0...1))),
                         highlight: todaysTotal >= board.effectiveTarget)
                Divider().frame(height: 24)
                statCell(label: "Streak", value: String(board.currentStreak), highlight: true)
                Divider().frame(height: 24)
                statCell(label: "Best", value: String(board.longestStreak), highlight: false)
                Spacer()
            }

            // 7-day activity bars
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("Last 7 days")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
                HStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { offset in
                        let checkDate = Calendar.current.date(byAdding: .day, value: -(6 - offset), to: .now)!
                        let hasLog = (board.logs ?? [])
                            .contains { Calendar.current.isDate($0.timestamp, inSameDayAs: checkDate) }
                        RoundedRectangle(cornerRadius: 2)
                            .fill(hasLog
                                  ? ColorPalette[board.colorIndex].opacity(0.6)
                                  : DS.Color.surface)
                            .frame(maxWidth: .infinity)
                            .frame(height: 6)
                    }
                }
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    @ViewBuilder
    private func statCell(label: String, value: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(label)
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)
            ValueText(value, font: DS.Text.body)
                .foregroundStyle(highlight ? ColorPalette[board.colorIndex] : DS.Color.textPrimary)
        }
    }

    private var stateLabel: String {
        switch state {
        case .needsAction: return "TODO"
        case .inProgress:  return "IN PROGRESS"
        case .behind:      return "BEHIND"
        case .done:        return "DONE"
        }
    }
}
