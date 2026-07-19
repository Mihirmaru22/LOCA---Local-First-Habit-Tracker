//
//  HabitGridLayoutView.swift
//  LOCA
//
//  Phase 14.4 — Grid layout for habit display.
//
//  2-column grid of compact habit cards. Removes zone organization
//  in favor of dense visual scanning. Same cards, rearranged.
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

    // Sort by state priority, but keep visual density
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
                    HabitGridCard(
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

// MARK: - Grid Card

struct HabitGridCard: View {
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
            // Header: name + badge
            HStack(spacing: DS.Space.sm) {
                Text(board.name)
                    .font(DS.Text.footnote)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Spacer()

                // State badge
                Image(systemName: stateBadgeIcon)
                    .font(.caption2)
                    .foregroundStyle(stateColor)
            }

            // Progress bar
            ProgressView(value: min(todaysTotal / board.effectiveTarget, 1.0))
                .tint(ColorPalette[board.colorIndex])

            // Value display
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                ValueText(
                    todaysTotal.formatted(.number.precision(.fractionLength(0...1))),
                    font: DS.Text.body
                )
                .foregroundStyle(
                    todaysTotal >= board.effectiveTarget
                        ? ColorPalette[board.colorIndex]
                        : DS.Color.textSecondary
                )

                if let unitLabel = board.unitLabel, !unitLabel.isEmpty {
                    Text("\(unitLabel)")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }

            Spacer(minLength: 0)

            // Streak + quick action
            HStack(spacing: DS.Space.sm) {
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Text("Streak")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                    ValueText(
                        String(board.currentStreak),
                        font: DS.Text.body
                    )
                    .foregroundStyle(ColorPalette[board.colorIndex])
                }

                Spacer()

                // Quick check-in button for binary/needsAction
                if state == .needsAction && board.metricType == 0 {
                    Button(action: onCheckBinary) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(ColorPalette[board.colorIndex])
                    }
                }
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private var stateBadgeIcon: String {
        switch state {
        case .needsAction:
            return "exclamationmark.circle.fill"
        case .inProgress:
            return "hourglass.circle.fill"
        case .behind:
            return "minus.circle.fill"
        case .done:
            return "checkmark.circle.fill"
        }
    }
}
