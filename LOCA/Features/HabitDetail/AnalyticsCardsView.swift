import SwiftUI

// MARK: - AnalyticsCardsView

/// Three compact summary stat cards: 30-day completion rate, total check-ins,
/// and either average-per-check-in (quantitative) or best streak (binary).
struct AnalyticsCardsView: View {

    let board: HabitBoard

    @State private var completionRate: Double?
    @State private var isLoading = true

    private static let windowDays = 30

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 72)
            } else {
                HStack(spacing: 10) {
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
                .padding(.horizontal, 16)
            }
        }
        // Same stable id fix as HeatmapView — lazy relationship fires late.
        .task(id: "\(board.id)-\(board.logs?.count ?? -1)") {
            await recompute()
        }
    }

    // MARK: Compute

    private func recompute() async {
        isLoading = true
        let snapshots = (board.logs ?? []).map(LogSnapshot.init(from:))
        let cells = await HeatmapDataProvider.buildDayGrid(
            snapshots: snapshots,
            target: board.effectiveTarget,
            windowDays: Self.windowDays,
            calendar: .current
        )
        guard !Task.isCancelled else { return }
        let completed = cells.filter { $0.intensity >= 1 }.count
        completionRate = Double(completed) / Double(cells.count)
        isLoading = false
    }

    // MARK: Display Text

    private var completionRateText: String {
        guard let r = completionRate else { return "—" }
        return r.formatted(.percent.precision(.fractionLength(0)))
    }

    private var totalCheckInsText: String { "\((board.logs ?? []).count)" }

    private var thirdCardIcon: String {
        board.metric == .binary ? "trophy.fill" : "chart.bar.fill"
    }

    private var thirdCardLabel: String {
        board.metric == .binary ? "Best Streak" : "Avg / Entry"
    }

    private var thirdCardValue: String {
        switch board.metric {
        case .binary:
            return "\(board.longestStreak)"
        case .quantitative:
            let logs = board.logs ?? []
            guard !logs.isEmpty else { return "—" }
            let avg  = logs.reduce(0.0) { $0 + $1.value } / Double(logs.count)
            let unit = board.unitLabel ?? ""
            let text = avg.formatted(.number.precision(.fractionLength(0...1)))
            return unit.isEmpty ? text : "\(text) \(unit)"
        }
    }
}

// MARK: - StatCard

private struct StatCard: View {

    let icon: String
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.background.secondary)
                .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}
