import SwiftUI

// MARK: - TodoPalette   (T-Phase8 — day-planner accent treatment)

/// Shared visual treatment for day-planner icon bubbles.
///
/// The signature look of the planner is a two-tone violet gradient bubble with a
/// soft coloured glow — `AccentColor` → `AccentColor2` on a 150° diagonal, lifted
/// by a shadow tinted with the accent. Centralised here so timeline blocks, the
/// detail icon, and the icon picker all render identically.
enum TodoPalette {

    /// Second gradient stop (lighter violet). Falls back to the primary accent
    /// if the asset is missing so the bubble never renders black.
    static let accent2 = Color("AccentColor2")

    /// The two-tone bubble fill. `topLeading → bottomTrailing` approximates the
    /// mockup's 150° gradient angle.
    static var bubbleGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.42, green: 0.31, blue: 0.88), // Rich Royal Violet
                Color(red: 0.64, green: 0.42, blue: 0.98)  // Electric Lavender
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Coloured glow beneath an active bubble (`box-shadow: 0 1px 3px accent@40%`).
    static let bubbleGlow = Color(red: 0.52, green: 0.36, blue: 0.95).opacity(0.40)
}

// MARK: - Bubble modifier

extension View {

    /// Wraps a (white) glyph in the LOCA day-planner icon bubble: two-tone violet
    /// gradient + coloured glow. When `done`, the bubble flattens to a neutral
    /// tertiary fill with no glow, matching the struck-through block treatment.
    ///
    /// - Parameters:
    ///   - diameter: Bubble edge length (34 pt on the timeline, 42 pt in detail).
    ///   - done: Completed state — flattens the fill and removes the glow.
    func todoBubble(diameter: CGFloat, done: Bool = false) -> some View {
        self
            .foregroundStyle(.white)
            .frame(width: diameter, height: diameter)
            .background {
                Circle()
                    .fill(done ? AnyShapeStyle(DS.Color.textTertiary)
                               : AnyShapeStyle(TodoPalette.bubbleGradient))
                    .shadow(color: done ? .clear : TodoPalette.bubbleGlow,
                            radius: 3, x: 0, y: 1)
            }
    }
}
