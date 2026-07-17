import SwiftUI

// MARK: - HabitCardView

/// A compact, Fitness-inspired dashboard row.
///
/// Layout anatomy:
///   [ArcRing]  [Name (bold)]
///              [Today progress (tinted on completion)]
///              [🔥 N-day streak · Best: Nd]
///
/// All data logic preserved from Phase 4. Visual presentation only.
struct HabitCardView: View {

    let board: HabitBoard

    private enum Layout {
        static let ringSize: CGFloat  = 42
        static let dotSize:  CGFloat  = 7
    }

    var body: some View {
        let total    = todaysTotal
        let fraction = progressFraction(for: total)
        let accent   = ColorPalette[board.colorIndex]

        HStack(alignment: .center, spacing: 12) {

            // Progress ring (left anchor)
            ringView(fraction: fraction, accent: accent)

            // Text block
            VStack(alignment: .leading, spacing: 1) {

                // Primary — name
                Text(board.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                // Secondary — today's progress
                Text(todayProgressText(total: total, fraction: fraction))
                    .font(.caption)
                    .foregroundStyle(fraction >= 1 ? accent : .secondary)
                    .lineLimit(1)

                // Tertiary — streak
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                    Text(streakText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if board.longestStreak > board.currentStreak {
                        Text("· Best: \(board.longestStreak)d")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText(total: total, fraction: fraction))
    }

    // MARK: Ring

    @ViewBuilder
    private func ringView(fraction: Double, accent: Color) -> some View {
        ZStack {
            ArcProgressView(fraction: fraction, color: accent, size: Layout.ringSize)

            switch board.metric {
            case .binary:
                Image(systemName: fraction >= 1 ? "checkmark" : "")
                    .font(.body.bold())
                    .foregroundStyle(accent)
            case .quantitative:
                Text(percentLabel(for: fraction))
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(accent)
            }
        }
        .frame(width: Layout.ringSize, height: Layout.ringSize)
    }

    private func percentLabel(for fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    // MARK: Data Logic (unchanged from Phase 4)

    private var todaysTotal: Double {
        (board.logs ?? [])
            .filter { $0.timestamp.isToday() }
            .reduce(0.0) { $0 + $1.value }
    }

    private func progressFraction(for total: Double) -> Double {
        max(0.0, min(1.0, total / board.effectiveTarget))
    }

    private var streakText: String {
        board.currentStreak == 1 ? "1 day streak" : "\(board.currentStreak) day streak"
    }

    private func todayProgressText(total: Double, fraction: Double) -> String {
        switch board.metric {
        case .binary:
            return fraction >= 1 ? "Done today" : targetText
        case .quantitative:
            let unit    = board.unitLabel.flatMap { $0.isEmpty ? nil : " \($0)" } ?? ""
            let doneStr = total.formatted(.number.precision(.fractionLength(0...1)))
            let goalStr = board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))
            return fraction >= 1
                ? "\(doneStr)\(unit) · Goal met ✓"
                : "\(doneStr) / \(goalStr)\(unit)"
        }
    }

    private var targetText: String {
        switch board.metric {
        case .binary:      return "Check off daily"
        case .quantitative:
            let unit   = board.unitLabel ?? ""
            let target = board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))
            return "Goal: \(target) \(unit)/day"
        }
    }

    private func todayStatusText(total: Double, fraction: Double) -> String {
        switch board.metric {
        case .binary:
            return fraction >= 1 ? "logged today" : "not logged today"
        case .quantitative:
            let unit      = board.unitLabel ?? ""
            let totalText = total.formatted(.number.precision(.fractionLength(0...1)))
            let target    = board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))
            return "\(totalText) of \(target) \(unit) today"
        }
    }

    private func accessibilityLabelText(total: Double, fraction: Double) -> String {
        "\(board.name), \(streakText), \(todayStatusText(total: total, fraction: fraction))"
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

    let p = HabitBoard(name: "Reading — a very long habit name indeed", colorIndex: 2)
    p.currentStreak = 0; p.longestStreak = 8

    return List {
        HabitCardView(board: q)
        HabitCardView(board: b)
        HabitCardView(board: p)
    }
    .listStyle(.sidebar)
}

