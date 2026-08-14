import SwiftUI

// MARK: - MacStatBar   (H4)

/// Horizontal strip of three stat tiles shown below the heatmap in the Mac
/// detail column: current streak · this-month consistency · total logged.
///
/// Uses the same derivations as `RefStreakCard` / `RefConsistencyCard` in the
/// iOS detail view, refactored into computed properties here so the three values
/// sit in one compact row instead of two stacked cards.
struct MacStatBar: View {

    let board: HabitBoard

    var body: some View {
        HStack(spacing: DS.Space.md) {
            StatTile(
                icon: "flame.fill",
                label: "STREAK",
                value: "\(board.currentStreak)",
                unit: board.currentStreak == 1 ? "day" : "days",
                color: ColorPalette[board.colorIndex]
            )

            Divider().frame(height: 44)

            StatTile(
                icon: "leaf",
                label: "THIS MONTH",
                value: "\(Int((monthlyConsistency * 100).rounded()))%",
                unit: "done",
                color: DS.Color.textSecondary
            )

            Divider().frame(height: 44)

            StatTile(
                icon: "checkmark.circle",
                label: "TOTAL",
                value: "\(totalLogged)",
                unit: totalLogged == 1 ? "time" : "times",
                color: DS.Color.textSecondary
            )
        }
        .padding(DS.Space.lg)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.border.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - Derived values

    private var totalLogged: Int {
        Set((board.logs ?? []).map { Calendar.current.startOfDay(for: $0.timestamp) }).count
    }

    private var monthlyConsistency: Double {
        guard let monthStart = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: .now)
        ) else { return 0 }
        let elapsed = max(1, (Calendar.current.dateComponents([.day], from: monthStart, to: .now).day ?? 0) + 1)
        var daily = [Date: Double]()
        for log in board.logs ?? [] {
            guard log.timestamp >= monthStart else { continue }
            let day = Calendar.current.startOfDay(for: log.timestamp)
            daily[day, default: 0] += log.value
        }
        return Double(daily.filter { $0.value >= board.effectiveTarget }.count) / Double(elapsed)
    }
}

// MARK: - StatTile

private struct StatTile: View {

    let icon:  String
    let label: String
    let value: String
    let unit:  String
    let color: SwiftUI.Color

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(label)
                    .font(DS.Text.footnote)
                    .foregroundStyle(DS.Color.textSecondary)
                    .tracking(0.5)
            }

            HStack(alignment: .lastTextBaseline, spacing: DS.Space.xs) {
                Text(value)
                    .font(DS.Text.value)
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
