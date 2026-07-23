//
//  HabitTimelineLayoutView.swift
//  LOCA
//
//  Phase 14.4 — Timeline layout for habit display.
//
//  Habits sorted by creation date (newest first) with expanded streak
//  and analytics. Emphasizes depth over breadth.
//

import SwiftUI
import SwiftData

struct HabitTimelineLayoutView: View {
    let boardsWithState: [(board: HabitBoard, state: HabitState)]
    let onCheckBinary: (HabitBoard) -> Void

    // Sort by creation date (newest first)
    private var sortedBoards: [(board: HabitBoard, state: HabitState)] {
        boardsWithState.sorted { a, b in
            a.board.createdAt > b.board.createdAt
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {
            ForEach(sortedBoards, id: \.board.id) { item in
                NavigationLink(destination: HabitDetailView(board: item.board)) {
                    HabitTimelineCard(
                        board: item.board,
                        state: item.state,
                        onCheckBinary: { onCheckBinary(item.board) }
                    )
                }
                .buttonStyle(.pressable)
            }

            Spacer(minLength: DS.Space.xxxl)
        }
        .padding(DS.Space.lg)
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

    private var recentLogsCount: Int {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now)!
        return (board.logs ?? [])
            .filter { $0.timestamp >= sevenDaysAgo }
            .count
    }

    private var stateColor: Color {
        switch state {
        case .needsAction, .behind:
            return ColorPalette[board.colorIndex]
        case .inProgress:
            return DS.Color.textSecondary
        case .done:
            return DS.Color.textTertiary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            // Timeline marker + header
            HStack(spacing: DS.Space.md) {
                // Timeline dot
                Circle()
                    .fill(stateColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(DS.Color.background, lineWidth: 2)
                    )

                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    HStack {
                        Text(board.name)
                            .font(DS.Text.heading)
                            .lineLimit(1)

                        Spacer()

                        // State label
                        Text(stateLabel)
                            .font(DS.Text.caption)
                            .foregroundStyle(stateColor)
                            .tracking(0.5)
                    }

                    if let unitLabel = board.unitLabel, !unitLabel.isEmpty {
                        Text("\(unitLabel) daily target")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }

                Spacer()

                // Quick action
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
                // Today
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text("Today")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                    ValueText(
                        todaysTotal.formatted(.number.precision(.fractionLength(0...1))),
                        font: DS.Text.body
                    )
                    .foregroundStyle(
                        todaysTotal >= board.effectiveTarget
                            ? ColorPalette[board.colorIndex]
                            : DS.Color.textSecondary
                    )
                    .contentTransition(.numericText())
                }

                Divider()
                    .frame(height: 24)

                // Current streak
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text("Streak")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                    ValueText(
                        String(board.currentStreak),
                        font: DS.Text.body
                    )
                    .foregroundStyle(ColorPalette[board.colorIndex])
                    .contentTransition(.numericText())
                }

                Divider()
                    .frame(height: 24)

                // Longest streak
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text("Best")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                    ValueText(
                        String(board.longestStreak),
                        font: DS.Text.body
                    )
                    .foregroundStyle(DS.Color.textPrimary)
                    .contentTransition(.numericText())
                }

                Spacer()
            }

            // Recent activity indicator
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("Last 7 days")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)

                HStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { dayOffset in
                        let checkDate = Calendar.current.date(byAdding: .day, value: -(6 - dayOffset), to: .now)!
                        let dayLogs = (board.logs ?? [])
                            .filter { Calendar.current.isDate($0.timestamp, inSameDayAs: checkDate) }

                        RoundedRectangle(cornerRadius: 2)
                            .fill(dayLogs.isEmpty ? DS.Color.surface : ColorPalette[board.colorIndex].opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 6)
                    }
                }
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private var stateLabel: String {
        switch state {
        case .needsAction:
            return "TODO"
        case .inProgress:
            return "IN PROGRESS"
        case .behind:
            return "BEHIND"
        case .done:
            return "DONE"
        }
    }
}
