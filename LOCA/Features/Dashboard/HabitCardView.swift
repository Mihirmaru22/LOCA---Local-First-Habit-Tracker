import SwiftUI

// MARK: - Layout Constants

private enum CardLayout {
    static let colorDotSize: CGFloat = 8
    static let gaugeSize: CGFloat = 32       // down from 44 — less dominant
    static let ringStrokeWidth: CGFloat = 3  // used for the manual ring fallback
}

// MARK: - HabitCardView

/// A single dashboard row: habit identity, streak history, and today's progress
/// toward its daily target.
///
/// All values displayed here are either cached stored properties from `HabitBoard`
/// (`currentStreak`, `longestStreak`, `effectiveTarget`) or a simple filter+sum over
/// `board.logs` for today's total — no `StreakCalculator` or `HeatmapDataProvider`
/// call occurs in this view. See the algorithm note on `todaysTotal` below for why
/// that boundary is deliberate, not an oversight.
struct HabitCardView: View {

    let board: HabitBoard

    var body: some View {
        // Computed exactly once per body evaluation (Phase 4 review finding M1).
        let total = todaysTotal
        let fraction = progressFraction(for: total)
        let accent = ColorPalette[board.colorIndex]

        HStack(alignment: .center, spacing: 10) {

            // MARK: Left — identity + supporting info
            VStack(alignment: .leading, spacing: 2) {

                // Tier 1 — Name (primary)
                HStack(spacing: 6) {
                    Circle()
                        .fill(accent)
                        .frame(width: CardLayout.colorDotSize,
                               height: CardLayout.colorDotSize)
                    Text(board.name)
                        .font(.system(.subheadline, weight: .semibold))
                        .lineLimit(1)
                }

                // Tier 2 — Today's progress (secondary)
                Text(todayProgressText(total: total, fraction: fraction))
                    .font(.caption)
                    .foregroundStyle(fraction >= 1 ? accent : .secondary)
                    .lineLimit(1)

                // Tier 3 — Streak + best (supporting)
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange.opacity(0.8))
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

            Spacer(minLength: 4)

            // MARK: Right — progress indicator
            // Binary: filled/empty checkmark circle (no "–").
            // Quantitative: circular capacity gauge with % label.
            progressIndicator(fraction: fraction, accent: accent)
        }
        .padding(.vertical, 6)
        // Single collapsed VoiceOver element per Engineering Principles §6.4.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText(total: total, fraction: fraction))
    }

    // MARK: Progress Indicator

    @ViewBuilder
    private func progressIndicator(fraction: Double, accent: Color) -> some View {
        switch board.metric {
        case .binary:
            // A filled or empty check circle — intentional and readable at 32 pt.
            Image(systemName: fraction >= 1 ? "checkmark.circle.fill" : "circle")
                .font(.system(size: CardLayout.gaugeSize * 0.7, weight: .light))
                .foregroundStyle(fraction >= 1 ? accent : Color.primary.opacity(0.15))

        case .quantitative:
            Gauge(value: fraction) {
                EmptyView()
            } currentValueLabel: {
                Text(percentText(for: fraction))
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(accent)
            .frame(width: CardLayout.gaugeSize, height: CardLayout.gaugeSize)
        }
    }

    // MARK: - Display Text (new hierarchy-aware helpers)

    /// Tier 2 text: today's progress in context. For binary, "Done today" or
    /// the goal text. For quantitative, "X / Y unit" with "· Goal met" appended.
    private func todayProgressText(total: Double, fraction: Double) -> String {
        switch board.metric {
        case .binary:
            return fraction >= 1.0 ? "Done today" : targetText
        case .quantitative:
            let unit = board.unitLabel.flatMap { $0.isEmpty ? nil : " \($0)" } ?? ""
            let doneStr = total.formatted(.number.precision(.fractionLength(0...1)))
            let goalStr = board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))
            let met = fraction >= 1.0 ? " · Goal met" : ""
            return "\(doneStr) / \(goalStr)\(unit)\(met)"
        }
    }

    private func percentText(for fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    // MARK: - Today's Progress (Presentation-Layer Only)

    // MARK: Why This Is Not a HeatmapDataProvider Call
    //
    // HeatmapDataProvider.buildDayGrid performs a full aggregateByDay pass across
    // a board's ENTIRE log history to build a multi-day grid — calling it with
    // windowDays: 1 would still pay that full-history aggregation cost just to
    // extract a single day's total. For a board with years of history, that is
    // real, avoidable work repeated on every dashboard render, directly contrary
    // to this phase's performance mandate.
    //
    // Filtering board.logs — an already-loaded, in-memory relationship — to
    // today's entries via the existing Date.isToday(using:) helper (Phase 1's
    // Date+Calendar extension) is O(n) over one board's own logs, computed
    // synchronously with no async Task, loading state, or Swift 6 concurrency
    // surface required. It introduces zero new date/DST logic: all of it
    // delegates to the already-reviewed, already-DST-correct Calendar primitive
    // Date.isToday wraps. This is presentation-layer arithmetic over
    // already-computed stored values (LogEntry.value), not a new compute
    // algorithm in the StreakCalculator/HeatmapDataProvider sense.

    private var todaysTotal: Double {
        (board.logs ?? [])
            .filter { $0.timestamp.isToday() }
            .reduce(0.0) { $0 + $1.value }
    }

    // MARK: Bounds Clamping (Phase 4 review finding M2)
    //
    // Previously only min(1.0, ...) — upper bound only. LogEntry.value has no
    // model-level constraint preventing a negative value (no code path currently
    // produces one, but nothing structurally prevents a corrupted or malicious
    // CloudKit-synced record from carrying one either). An unclamped negative
    // fraction would pass an out-of-bounds value to Gauge (whose default range
    // is 0...1), producing undefined rendering, and gaugeLabel would show a
    // nonsensical negative percentage. Clamping both bounds matches the same
    // defensive posture already applied to corrupted CloudKit data elsewhere
    // (HabitBoard.effectiveTarget's guard against a non-positive target).

    private func progressFraction(for total: Double) -> Double {
        max(0.0, min(1.0, total / board.effectiveTarget))
    }

    // MARK: - Display Text

    private var streakText: String {
        board.currentStreak == 1 ? "1 day streak" : "\(board.currentStreak) day streak"
    }

    private var bestStreakText: String {
        "Best: \(board.longestStreak) days"
    }

    private var targetText: String {
        switch board.metric {
        case .binary:
            return "Check off daily"
        case .quantitative:
            let unit = board.unitLabel ?? ""
            let target = board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))
            return "Goal: \(target) \(unit)/day"
        }
    }

    private func gaugeLabel(for fraction: Double) -> String {
        switch board.metric {
        case .binary:
            return fraction >= 1.0 ? "✓" : "–"
        case .quantitative:
            return "\(Int((fraction * 100).rounded()))%"
        }
    }

    private func todayStatusText(total: Double, fraction: Double) -> String {
        switch board.metric {
        case .binary:
            return fraction >= 1.0 ? "logged today" : "not logged today"
        case .quantitative:
            let unit = board.unitLabel ?? ""
            let totalText = total.formatted(.number.precision(.fractionLength(0...1)))
            let target = board.effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))
            return "\(totalText) of \(target) \(unit) today"
        }
    }

    private func accessibilityLabelText(total: Double, fraction: Double) -> String {
        "\(board.name), \(streakText), \(todayStatusText(total: total, fraction: fraction))"
    }
}

// MARK: - Preview

#Preview {
    let quantitative = HabitBoard(name: "Running", metricType: HabitBoard.MetricType.quantitative.rawValue,
                                   targetValue: 5.0, unitLabel: "mi", colorIndex: 0)
    quantitative.currentStreak = 5
    quantitative.longestStreak = 12
    let entry = LogEntry(value: 3.0, boardID: quantitative.id, board: quantitative)
    quantitative.logs = [entry]

    let binaryCompleted = HabitBoard(name: "Meditate", colorIndex: 5)
    binaryCompleted.currentStreak = 3
    binaryCompleted.longestStreak = 3
    let binaryEntry = LogEntry(value: 1.0, boardID: binaryCompleted.id, board: binaryCompleted)
    binaryCompleted.logs = [binaryEntry]

    let binaryPending = HabitBoard(name: "Reading", colorIndex: 2)
    binaryPending.currentStreak = 0
    binaryPending.longestStreak = 8

    return List {
        HabitCardView(board: quantitative)
        HabitCardView(board: binaryCompleted)
        HabitCardView(board: binaryPending)
    }
    .listStyle(.sidebar)
}
