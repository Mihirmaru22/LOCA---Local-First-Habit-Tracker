//
//  DS+Typography.swift
//  LOCA
//
//  Phase 11 — Typographic scale and LOCA's numeric voice.
//
//  Two rules define LOCA's typography: (1) semantic styles only, so everything
//  scales with Dynamic Type by construction; (2) numbers render in rounded SF,
//  prose in default SF. LOCA tracks quantities — its numeric voice is rounded.
//

import SwiftUI

extension DS {

    /// Typographic tokens. Prefer these over ad-hoc `.font(...)` so hierarchy and
    /// the rounded-numeral voice stay consistent across every screen and module.
    enum Text {

        // MARK: Prose (default SF)

        /// Screen / hero titles.
        static let title = Font.title2.weight(.bold)
        /// Section headers.
        static let heading = Font.headline
        /// Primary body / row titles.
        static let body = Font.subheadline.weight(.medium)
        /// Secondary supporting text.
        static let caption = Font.caption
        /// Tertiary / metadata.
        static let footnote = Font.caption2

        // MARK: Numeric voice (rounded SF)

        /// Hero numeric value (large stat, e.g. a streak count on a detail screen).
        static let valueHero = Font.system(.largeTitle, design: .rounded).weight(.bold)
        /// Standard numeric value (metric tiles, ring labels).
        static let value = Font.system(.title2, design: .rounded).weight(.bold)
        /// Compact numeric value (inline, list rows).
        static let valueCompact = Font.system(.subheadline, design: .rounded).weight(.semibold)
        /// Small numeric label (chart axes, cell counts).
        static let valueSmall = Font.system(.caption, design: .rounded).weight(.semibold)
    }
}

// MARK: - ValueText (numeric-voice primitive)

/// Renders a numeric string in LOCA's rounded numeral voice. Use for any quantity —
/// values, streaks, percentages, chart labels — so the numeric identity stays uniform.
struct ValueText: View {

    private let text: String
    private let font: Font

    /// - Parameters:
    ///   - text: The already-formatted numeric string (caller controls precision/units).
    ///   - font: A rounded numeric token from `DS.Text` (defaults to `.value`).
    init(_ text: String, font: Font = DS.Text.value) {
        self.text = text
        self.font = font
    }

    var body: some View {
        Text(text)
            .font(font)
            .monospacedDigit()
    }
}
