//
//  WeeklyBarChart.swift
//  LOCA
//
//  Phase 11.2 — Weekly bar visualization component.
//
//  A compact 7-day bar chart that scales intelligently to any metric type (time,
//  distance, weight, reps) and any magnitude (5 units or 500). Used in habit
//  list rows for quick weekly trends and in detail page analytics for deeper
//  context. One component, two contexts, future modules unchanged.
//

import SwiftUI

// MARK: - WeeklyBarChart

/// A 7-day vertical bar chart showing daily progress toward a goal.
///
/// - Parameters:
///   - dailyTotals: Array of 7 daily values (oldest to newest). If fewer than
///     7 entries, the array is padded with zeros to the left. If more than 7,
///     only the last 7 are used.
///   - target: The daily goal. Used to color-code bars (done = full opacity,
///     partial = dimmed, none = very dim).
///   - accentColor: The habit's palette color.
///   - size: `.compact` (24pt tall, habitat rows) or `.normal` (48pt, detail).
struct WeeklyBarChart: View {

    let dailyTotals: [Double]
    let target: Double
    let accentColor: Color
    var size: Size = .compact

    enum Size {
        case compact   // 24pt height
        case normal    // 48pt height
    }

    private var height: CGFloat {
        switch size {
        case .compact: return 24
        case .normal:  return 48
        }
    }

    /// Normalize the input to exactly 7 days (pad left with zeros if sparse).
    private var paddedDailyTotals: [Double] {
        guard !dailyTotals.isEmpty else { return Array(repeating: 0, count: 7) }
        let last7 = dailyTotals.suffix(7)
        let padCount = 7 - last7.count
        return Array(repeating: 0, count: padCount) + Array(last7)
    }

    /// The maximum daily value across the week (used for bar scaling).
    /// If no value reaches the goal, scale to the max. If all are at or above
    /// the goal, use the goal itself (so bars don't wildly spike for one
    /// exceptional day).
    private var maxDaily: Double {
        let absMax = paddedDailyTotals.max() ?? 0
        let effectiveGoal = max(target, 1) // Avoid division by zero
        return max(absMax, effectiveGoal)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<7, id: \.self) { idx in
                barView(for: paddedDailyTotals[idx])
            }
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Week overview: \(weekSummary)")
    }

    // MARK: - Bar rendering

    @ViewBuilder
    private func barView(for value: Double) -> some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer(minLength: 0)

            // Bar body: rounded rect, color and opacity by completeness
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(barColor(for: value))
                .frame(maxHeight: height * value / max(maxDaily, 1))
        }
        .contentShape(Rectangle())
        .accessibilityHidden(true)  // Rolled up into the parent's label
    }

    private func barColor(for value: Double) -> Color {
        let fraction = target > 0 ? value / target : 0
        // Done: full opacity. Partial: 60% opacity. None: 25% opacity.
        let opacity = value == 0 ? 0.25 : (fraction >= 1 ? 1.0 : 0.6)
        return accentColor.opacity(opacity)
    }

    // MARK: - Accessibility

    private var weekSummary: String {
        let total = paddedDailyTotals.reduce(0, +)
        let doneDays = paddedDailyTotals.filter { $0 >= target }.count
        return "\(doneDays) of 7 days met, \(Int(total)) total"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DS.Space.xl) {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Compact (habit row)")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)

            HStack(spacing: DS.Space.md) {
                WeeklyBarChart(
                    dailyTotals: [0, 0.5, 1.2, 0.8, 0, 1.5, 0.9],
                    target: 1.0,
                    accentColor: ColorPalette[0],
                    size: .compact
                )
                .frame(width: 80)

                Text("Running")
                    .font(DS.Text.body)
            }
        }

        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Normal (detail analytics)")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)

            WeeklyBarChart(
                dailyTotals: [150, 200, 0, 280, 300, 250, 180],
                target: 250,
                accentColor: ColorPalette[3],
                size: .normal
            )
            .frame(height: 48)
        }

        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Sparse data (pads left with zeros)")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)

            WeeklyBarChart(
                dailyTotals: [100, 90],
                target: 120,
                accentColor: ColorPalette[5],
                size: .normal
            )
            .frame(height: 48)
        }

        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Wide range (auto-scaled)")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)

            WeeklyBarChart(
                dailyTotals: [5, 10, 0, 15, 0, 8, 12],
                target: 10,
                accentColor: ColorPalette[2],
                size: .normal
            )
            .frame(height: 48)
        }
    }
    .padding(DS.Space.lg)
}
