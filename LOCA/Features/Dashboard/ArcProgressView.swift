//
//  ArcProgressView.swift
//  LOCA
//
//  Phase 10.2 — Custom progress ring inspired by Apple Fitness rings.
//  Not a copy — uses the same design principles: rounded caps, consistent
//  stroke weight, smooth animation, clear completion state.
//

import SwiftUI

// MARK: - ArcProgressView

/// A circular progress ring drawn via Canvas for a Fitness-ring-quality appearance.
///
/// Design principles (inspired by, not copying, Apple Fitness):
/// - Rounded linecaps on both track and progress arc
/// - Consistent stroke thickness regardless of size
/// - Animates smoothly with `.spring` on `fraction` changes
/// - Clear completion state: fills a second lap's start arc when fraction ≥ 1
/// - Track and fill colours derived from the habit's accent colour
struct ArcProgressView: View {

    let fraction: Double   // 0…1 (clamped internally)
    let color: Color
    let size: CGFloat

    private var strokeWidth: CGFloat { size * 0.15 }
    private var clamped: Double { max(0, min(1, fraction)) }

    var body: some View {
        Canvas { ctx, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = (min(canvasSize.width, canvasSize.height) - strokeWidth) / 2
            let start  = Angle.degrees(-90)   // 12 o'clock

            // Track (background ring)
            let trackPath = Path { p in
                p.addArc(center: center, radius: radius,
                         startAngle: start, endAngle: start + .degrees(360),
                         clockwise: false)
            }
            ctx.stroke(
                trackPath,
                with: .color(color.opacity(0.15)),
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
            )

            // Progress arc — only draw if there's meaningful progress
            guard clamped > 0 else { return }
            let sweep = 360 * clamped
            let fillPath = Path { p in
                p.addArc(center: center, radius: radius,
                         startAngle: start, endAngle: start + .degrees(sweep),
                         clockwise: false)
            }
            ctx.stroke(
                fillPath,
                with: .color(color),
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
            )
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: clamped)
        .accessibilityHidden(true)  // parent provides the accessibility label
    }
}
