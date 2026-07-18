//
//  ArcGaugeView.swift
//  LOCA
//
//  Phase 11.3 — Consistency gauge component.
//
//  A complementary arc visualization to ArcProgressView, showing a ratio rather
//  than daily progress. Used in detail metrics to answer "what's my consistency
//  this month?" — fewer days completed means a smaller arc; full completion
//  means a full circle.
//

import SwiftUI

// MARK: - ArcGaugeView

/// An arc gauge showing a completion ratio as a visual indicator.
///
/// Unlike `ArcProgressView` (which shows today's progress toward a daily goal),
/// this gauge shows a ratio like "21 of 30 days this month completed" — a
/// consistency measure. The arc fills proportionally to the ratio (0…1), and
/// a label below shows the completion count.
struct ArcGaugeView: View {

    /// The numerator: days completed, items done, etc.
    let completedCount: Int
    /// The denominator: total days in period, total items, etc.
    let totalCount: Int
    /// The habit's color.
    let accentColor: Color
    /// Optional custom label (defaults to "Days")
    var label: String = "Days"
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fraction: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var body: some View {
        VStack(spacing: DS.Space.md) {
            // Arc gauge
            Canvas { context in
                let size = CGSize(width: 100, height: 100)
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = size.width / 2 - 5

                // Track (background arc)
                let trackPath = arcPath(center: center, radius: radius, fraction: 1.0)
                context.stroke(
                    trackPath,
                    with: .color(accentColor.opacity(0.15)),
                    lineWidth: 5
                )

                // Progress arc
                let progressPath = arcPath(center: center, radius: radius, fraction: fraction)
                context.stroke(
                    progressPath,
                    with: .color(accentColor),
                    lineWidth: 5
                )
            }
            .frame(width: 100, height: 100)

            // Label: "X of Y"
            VStack(spacing: DS.Space.xs) {
                ValueText("\(completedCount)", font: DS.Text.value)
                    .foregroundStyle(accentColor)

                Text("of \(totalCount) \(label.lowercased())")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .animation(
            reduceMotion ? .linear(duration: 0.1) : DS.Motion.settle,
            value: fraction
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) completed: \(completedCount) of \(totalCount)")
    }

    // MARK: - Arc path geometry

    private func arcPath(center: CGPoint, radius: CGFloat, fraction: Double) -> Path {
        var path = Path()
        let startAngle: Double = -90  // Top of circle
        let endAngle = startAngle + (360 * fraction)

        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )

        return path.strokedPath(.init(lineWidth: 5, lineCap: .round))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DS.Space.xxl) {
        HStack(spacing: DS.Space.xl) {
            VStack(alignment: .leading, spacing: DS.Space.sm) {
                Text("Consistency Gauge")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)

                ArcGaugeView(
                    completedCount: 21,
                    totalCount: 30,
                    accentColor: ColorPalette[0],
                    label: "Days"
                )
            }

            VStack(alignment: .leading, spacing: DS.Space.sm) {
                Text("Lower completion")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)

                ArcGaugeView(
                    completedCount: 5,
                    totalCount: 30,
                    accentColor: ColorPalette[3],
                    label: "Days"
                )
            }
        }

        VStack(alignment: .leading, spacing: DS.Space.sm) {
            Text("Perfect month")
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)

            ArcGaugeView(
                completedCount: 30,
                totalCount: 30,
                accentColor: ColorPalette[5],
                label: "Days"
            )
        }
    }
    .padding(DS.Space.xl)
}
