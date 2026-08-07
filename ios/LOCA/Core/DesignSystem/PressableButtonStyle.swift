//
//  PressableButtonStyle.swift
//  LOCA
//
//  Phase P.0.7 — The pressed-state primitive.
//
//  LOCA composes many tappable surfaces (habit rows, grid/timeline cards, selection
//  cards) as Buttons that then apply `.buttonStyle(.plain)` to sit inside a
//  NavigationLink or to drop the default tint. `.plain` also strips the platform's
//  press feedback, so tapping a whole card gives no acknowledgment.
//
//  This style restores that acknowledgment in one place: a subtle scale + opacity on
//  press — enough to feel the tap, never enough to announce itself (Phase P's
//  "inevitable, not decorative" rule). Reduce Motion is honored through the same
//  DS.Motion token contract every other animation uses, so no view hand-writes the
//  check.
//

import SwiftUI

/// The single pressed-state treatment for card- and row-like tappable surfaces that
/// are not system-styled buttons. Apply via `.buttonStyle(.pressable)`.
struct PressableButtonStyle: ButtonStyle {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            // Reduce Motion collapses the scale (opacity alone still confirms the tap).
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? 0.97 : 1.0))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(DS.Motion.confirm(reduceMotion: reduceMotion), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {

    /// LOCA's pressed-state style for card/row-like tappable surfaces. Replaces
    /// `.buttonStyle(.plain)` wherever a whole surface is the tap target and should
    /// acknowledge the press.
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}
