import SwiftUI

// MARK: - TodoProgressRing   (T8 — subtask completion ring)

/// A circular progress ring showing how many subtasks are complete.
///
/// - `progress` drives the arc trim (0 = empty, 1 = full).
/// - When complete (`progress >= 1`), the stroke switches from the accent
///   colour to green so the "done" state reads without checking the label.
/// - Animates via `DS.Motion.confirm` whenever `progress` changes.
struct TodoProgressRing: View {

    let progress:  Double
    var diameter:  CGFloat = 22
    var lineWidth: CGFloat = 3

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(DS.Color.surface, lineWidth: lineWidth)

            // Fill arc
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(
                    progress >= 1 ? Color.green : Color.accentColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(DS.Motion.confirm, value: progress)
        }
        .frame(width: diameter, height: diameter)
    }
}
