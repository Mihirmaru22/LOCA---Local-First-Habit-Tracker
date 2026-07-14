import SwiftUI

// MARK: - Layout Constants

private enum CardsLayout {
    static let cardSpacing: CGFloat = 10
    static let cardCornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 12
    static let iconSize: CGFloat = 18
}

// MARK: - AnalyticsCardsView

/// Three compact summary stat cards: 30-day completion rate, total check-ins,
/// and either average-per-check-in (quantitative habits) or longest streak
/// (binary habits).
///
/// ## Why 30 Days, Not 365 (ADR-010)
///
/// Completion rate is computed via `HeatmapDataProvider.buildDayGrid(windowDays: 30)` —
/// a separate, independent call from `HeatmapView`'s own 365-day computation, not a
/// shared one. A 365-day completion rate on a multi-year habit stays permanently
/// depressed by a rough first month; 30 days is the more actionable, more honest
/// number for "how am I doing lately." See ADR-010 for the full reasoning, including
/// why this doesn't touch `HeatmapView`'s already-closed Phase 5.2 implementation.
///
/// ## No New Compute Algorithms
///
/// Total check-ins is a plain count over an already-loaded relationship. Average
/// and longest streak read already-cached or already-summed values. Only completion
/// rate touches Phase 2, and it does so by calling `HeatmapDataProvider` exactly as
/// documented — never reimplementing day-grouping.
struct AnalyticsCardsView: View {

    let board: HabitBoard

    @State private var completionRate: Double?
    @State private var isLoading = true

    private static let completionRateWindowDays = 30

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 60)
            } else {
                HStack(spacing: CardsLayout.cardSpacing) {
                    StatCard(
                        icon: "checkmark.circle.fill",
                        value: completionRateText,
                        label: "30-Day Rate",
                        tint: ColorPalette[board.colorIndex]
                    )
                    StatCard(
                        icon: "number.circle.fill",
                        value: totalCheckInsText,
                        label: "Check-ins",
                        tint: ColorPalette[board.colorIndex]
                    )
                    StatCard(
                        icon: thirdCardIcon,
                        value: thirdCardValue,
                        label: thirdCardLabel,
                        tint: ColorPalette[board.colorIndex]
                    )
                }
            }
        }
        .task(id: board.logs?.count ?? 0) {
            await recomputeCompletionRate()
        }
    }

    // MARK: - Completion Rate (consumes HeatmapDataProvider exactly as designed)

    // MARK: @MainActor Snapshot Extraction, Then Off-Main Aggregation
    //
    // Identical pattern to HeatmapView (Phase 5.2): LogSnapshot.init(from:) is
    // @MainActor-isolated, so the snapshot map happens here before the await;
    // buildDayGrid itself runs on the cooperative thread pool with the
    // resulting Sendable value, never touching ModelContext directly.

    private func recomputeCompletionRate() async {
        let snapshots = (board.logs ?? []).map(LogSnapshot.init(from:))
        let cells = await HeatmapDataProvider.buildDayGrid(
            snapshots: snapshots,
            target: board.effectiveTarget,
            windowDays: Self.completionRateWindowDays,
            calendar: .current
        )
        // Same cancellation guard as HeatmapView (Phase 5.2 review M1) —
        // buildDayGrid doesn't check Task.isCancelled internally, so an
        // older, still-in-flight computation could otherwise overwrite a
        // newer one's result.
        guard !Task.isCancelled else { return }

        let completedDays = cells.filter { $0.intensity >= 1.0 }.count
        completionRate = Double(completedDays) / Double(cells.count)
        isLoading = false
    }

    // MARK: - Display Text (no new computation — formatting only)

    private var completionRateText: String {
        guard let rate = completionRate else { return "—" }
        return rate.formatted(.percent.precision(.fractionLength(0)))
    }

    private var totalCheckInsText: String {
        "\((board.logs ?? []).count)"
    }

    private var thirdCardIcon: String {
        switch board.metric {
        case .binary: return "trophy.fill"
        case .quantitative: return "chart.bar.fill"
        }
    }

    private var thirdCardLabel: String {
        switch board.metric {
        case .binary: return "Best Streak"
        case .quantitative: return "Avg / Entry"
        }
    }

    private var thirdCardValue: String {
        switch board.metric {
        case .binary:
            return "\(board.longestStreak)"
        case .quantitative:
            let logs = board.logs ?? []
            guard !logs.isEmpty else { return "—" }
            let total = logs.reduce(0.0) { $0 + $1.value }
            let average = total / Double(logs.count)
            let unit = board.unitLabel ?? ""
            let averageText = average.formatted(.number.precision(.fractionLength(0...1)))
            return unit.isEmpty ? averageText : "\(averageText) \(unit)"
        }
    }
}

// MARK: - StatCard

/// A single compact stat card: icon, large value, small label underneath.
/// Matches the card visual language already established in `HabitCardView`
/// (Phase 4) — icon + tinted accent, system text styles throughout.
private struct StatCard: View {

    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: CardsLayout.iconSize))
                .foregroundStyle(tint)

            // Engineering Principles §3: SF Pro Rounded for numbers in the
            // analytics dashboard. .title3.bold() produces the default
            // design variant; .system(.title3, design: .rounded, weight: .bold)
            // applies the Rounded variant explicitly. Phase 5.5 fix (E1).
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CardsLayout.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: CardsLayout.cardCornerRadius, style: .continuous)
                .fill(.quaternary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Preview

#Preview {
    let quantitative = HabitBoard(name: "Running", metricType: HabitBoard.MetricType.quantitative.rawValue,
                                   targetValue: 3.0, unitLabel: "mi", colorIndex: 0)
    var logs: [LogEntry] = []
    let calendar = Calendar.current
    for offset in 0..<20 {
        guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
        logs.append(LogEntry(timestamp: date, value: Double.random(in: 1...5),
                              boardID: quantitative.id, board: quantitative))
    }
    quantitative.logs = logs

    return AnalyticsCardsView(board: quantitative)
        .padding()
}
