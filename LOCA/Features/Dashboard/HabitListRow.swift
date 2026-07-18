//
//  HabitListRow.swift
//  LOCA
//
//  Phase 11.1 — Habit List: the row component.
//
//  A single row template that renders across all habit states (needs action,
//  in progress, done, behind) using visual weight alone — no position or size
//  changes. Stable position preserves spatial memory; emphasis through
//  typography + color hierarchy communicates priority.
//
//  Interaction model:
//  - Tap row: open habit detail
//  - Tap trailing check (binary only): complete today in place
//

import SwiftUI

// MARK: - HabitListRow

struct HabitListRow: View {

    let board: HabitBoard
    let state: HabitState
    let onTap: () -> Void
    let onCheckBinary: () -> Void

    // Track today's logs for this habit
    private var todaysTotal: Double {
        (board.logs ?? [])
            .filter { $0.timestamp.isToday() }
            .reduce(0.0) { $0 + $1.value }
    }

    private var progressFraction: Double {
        max(0.0, min(1.0, todaysTotal / board.effectiveTarget))
    }

    private var isBinaryDone: Bool {
        board.metric == .binary && progressFraction >= 1
    }

    var body: some View {
        HStack(alignment: .center, spacing: DS.Space.md) {

            // Left: Name + context (subtitle or mini-history)
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text(board.name)
                    .font(rowNameFont)
                    .foregroundStyle(rowNameColor)
                    .lineLimit(1)

                HStack(spacing: DS.Space.xs) {
                    if board.metric == .quantitative {
                        ValueText(
                            todaysTotal.formatted(.number.precision(.fractionLength(0...1))),
                            font: DS.Text.valueCompact
                        )
                        .foregroundStyle(rowSubtextColor)

                        Text(board.unitLabel ?? "")
                            .font(DS.Text.caption)
                            .foregroundStyle(rowSubtextColor)
                    } else {
                        Text(isBinaryDone ? "Done" : "Not logged")
                            .font(DS.Text.caption)
                            .foregroundStyle(rowSubtextColor)
                    }
                }
            }

            Spacer(minLength: DS.Space.sm)

            // Center: Progress indicator (mini weekly chart or progress bar)
            miniProgressView
                .frame(width: 80, height: 24)

            // Right: Trailing control (binary check or detail arrow)
            trailingControl
                .frame(width: 44, height: 44)
        }
        .padding(DS.Space.lg)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .opacity(state == .done ? 0.7 : 1.0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(state == .needsAction ? "Double tap to open" : nil)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var miniProgressView: some View {
        if board.metric == .binary {
            // Binary: simple checkmark indicator
            if isBinaryDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(ColorPalette[board.colorIndex])
            } else {
                Circle()
                    .strokeBorder(ColorPalette[board.colorIndex], lineWidth: 1.5)
                    .opacity(0.3)
            }
        } else {
            // Quantitative: mini progress bar
            HStack(spacing: DS.Space.xs) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(ColorPalette[board.colorIndex].opacity(0.15))

                        // Progress
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(ColorPalette[board.colorIndex])
                            .frame(width: geo.size.width * progressFraction)
                    }
                }
                .frame(height: 4)

                // Percentage
                ValueText(
                    "\(Int((progressFraction * 100).rounded()))%",
                    font: DS.Text.valueSmall
                )
                .foregroundStyle(rowSubtextColor)
                .frame(width: 28, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    private var trailingControl: some View {
        if board.metric == .binary {
            // Binary: dedicated check button
            Button(action: onCheckBinary) {
                Image(systemName: isBinaryDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isBinaryDone ? ColorPalette[board.colorIndex] : .secondary)
                    .contentShape(Circle())
            }
            .disabled(isBinaryDone)
            .accessibilityLabel("Check off \(board.name)")
        } else {
            // Quantitative: open detail arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Styling by state

    private var rowNameFont: Font {
        switch state {
        case .needsAction:  return DS.Text.body
        case .inProgress:   return DS.Text.body
        case .done:         return DS.Text.caption
        case .behind:       return DS.Text.body
        }
    }

    private var rowNameColor: Color {
        switch state {
        case .needsAction:  return DS.Color.textPrimary
        case .inProgress:   return DS.Color.textPrimary
        case .done:         return DS.Color.textSecondary
        case .behind:       return DS.Color.textPrimary
        }
    }

    private var rowSubtextColor: Color {
        switch state {
        case .needsAction:  return DS.Color.textSecondary
        case .inProgress:   return DS.Color.textSecondary
        case .done:         return DS.Color.textTertiary
        case .behind:       return ColorPalette[board.colorIndex]  // Accent subtle urgency
        }
    }

    private var rowBackground: Color {
        switch state {
        case .needsAction:  return DS.Color.surface
        case .inProgress:   return DS.Color.surface
        case .done:         return DS.Color.background
        case .behind:       return DS.Color.surface
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let base = board.name
        let streakInfo = "Streak: \(board.currentStreak) days"
        let progressInfo: String
        if board.metric == .binary {
            progressInfo = isBinaryDone ? "Done today" : "Not logged today"
        } else {
            let total = todaysTotal.formatted(.number.precision(.fractionLength(0...1)))
            let goal = board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))
            progressInfo = "\(total) of \(goal) \(board.unitLabel ?? "")"
        }
        return "\(base). \(progressInfo). \(streakInfo)"
    }
}

// MARK: - HabitState (computed from board + today's logs)

enum HabitState {
    case needsAction   // Not done, day not over
    case inProgress    // Quantitative, partway to goal
    case behind        // Not done AND streak broken
    case done          // Completed today

    static func compute(for board: HabitBoard, todaysTotal: Double) -> HabitState {
        let isBinaryDone = board.metric == .binary && todaysTotal >= board.effectiveTarget
        let isQuantDone = board.metric == .quantitative && todaysTotal >= board.effectiveTarget

        if isBinaryDone || isQuantDone {
            return .done
        }

        let isBehind = board.currentStreak == 0 && !board.logs!.isEmpty
        if isBehind && todaysTotal == 0 {
            return .behind
        }

        if board.metric == .quantitative && todaysTotal > 0 && todaysTotal < board.effectiveTarget {
            return .inProgress
        }

        return .needsAction
    }
}

// MARK: - Preview

#Preview {
    let q = HabitBoard(name: "Running", metricType: 1, targetValue: 5, unitLabel: "mi", colorIndex: 0)
    q.currentStreak = 5; q.longestStreak = 12
    q.logs = [LogEntry(value: 3.2, boardID: q.id, board: q)]

    let b = HabitBoard(name: "Meditate", colorIndex: 5)
    b.currentStreak = 3; b.longestStreak = 3
    b.logs = [LogEntry(value: 1, boardID: b.id, board: b)]

    let behind = HabitBoard(name: "Read", colorIndex: 2)
    behind.currentStreak = 0; behind.longestStreak = 8
    behind.logs = [LogEntry(value: 0.5, boardID: behind.id, board: behind)]

    let done = HabitBoard(name: "Stretch", colorIndex: 3)
    done.currentStreak = 10; done.longestStreak = 10
    done.logs = [LogEntry(value: 1, boardID: done.id, board: done)]

    return VStack(spacing: 0) {
        HabitListRow(
            board: q,
            state: .inProgress,
            onTap: { print("tap running") },
            onCheckBinary: { print("check") }
        )

        HabitListRow(
            board: b,
            state: .needsAction,
            onTap: { print("tap meditate") },
            onCheckBinary: { print("check") }
        )

        HabitListRow(
            board: behind,
            state: .behind,
            onTap: { print("tap read") },
            onCheckBinary: { print("check") }
        )

        HabitListRow(
            board: done,
            state: .done,
            onTap: { print("tap stretch") },
            onCheckBinary: { print("check") }
        )
    }
    .padding(DS.Space.lg)
}
