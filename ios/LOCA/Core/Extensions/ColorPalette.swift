import SwiftUI

// MARK: - ColorPalette

/// The application's fixed set of habit board colours, indexed by `HabitBoard.colorIndex`.
///
/// ## Why Indexed Rather Than Hex (ADR-002)
/// `HabitBoard` stores a `colorIndex: Int` rather than a `colorHex: String`. This
/// eliminates hex string parsing from the heatmap's render path: the 365-cell grid
/// calls `ColorPalette[board.colorIndex]` once per board, which is a bounds-checked
/// array subscript — O(1) with no allocation.
///
/// ## Index Stability
/// Index positions are **permanent**. Inserting a colour at any position other than
/// the end would shift all existing boards to the wrong colour. When adding new
/// colours, always append. Never insert. Never remove.
///
/// ## Accessibility — WCAG AA Contrast Analysis (T16, 2026-07-22)
///
/// Colors are used as UI-element fills (arc rings, FAB, heatmap cells), not as
/// foreground text, so the operative WCAG AA threshold is **3:1** for non-text
/// elements, not the 4.5:1 text threshold.
///
/// Dark mode (color on black): all 12 pass 4.5:1 (min: #3 Lavender 5.16:1). ✓
///
/// Light mode (color on white) — 3:1 UI-element threshold:
///   0 Ocean Blue  3.42 PASS  · 1 Mint       2.40 FAIL ⚠
///   2 Terracotta  3.55 PASS  · 3 Lavender   4.07 PASS
///   4 Amber       2.14 FAIL ⚠ · 5 Teal      2.53 FAIL ⚠
///   6 Rose        3.73 PASS  · 7 Sage       2.46 FAIL ⚠
///   8 Sunset      2.66 FAIL ⚠ · 9 Slate     3.36 PASS
///  10 Warm Sand   3.04 PASS  · 11 Sea Foam  2.50 FAIL ⚠
///
/// Indices 1, 4, 5, 7, 8, 11 fail 3:1 vs pure white. In practice these accents
/// render on DS.Color.surface (≈ Color(white: 0.105) in dark mode) where all 12
/// pass comfortably. If a pure-white light-mode context is introduced, darken the
/// six failing entries by ~10–15% to clear the 3:1 threshold.
///
/// ## Out-of-Bounds Safety
/// The subscript operator clamps out-of-range indices to index 0 (Ocean Blue) rather
/// than trapping. This ensures a board carrying a `colorIndex` from a future app
/// version (with additional palette entries) displays gracefully on older builds.
enum ColorPalette {

    // MARK: - Palette Definition

    /// The ordered set of available habit board colours.
    ///
    /// Defined as RGB component triples to enable O(1) `SwiftUI.Color` construction
    /// without string parsing or colour space conversion at render time.
    ///
    /// To add a colour: append an entry at the end and document its index in the
    /// inline comment. Do not reorder existing entries.
    static let colors: [Color] = [
        Color(red: 0.22, green: 0.56, blue: 0.87),  //  0 — Ocean Blue
        Color(red: 0.20, green: 0.74, blue: 0.53),  //  1 — Mint
        Color(red: 0.85, green: 0.40, blue: 0.25),  //  2 — Terracotta
        Color(red: 0.62, green: 0.38, blue: 0.85),  //  3 — Lavender
        Color(red: 0.92, green: 0.64, blue: 0.20),  //  4 — Amber
        Color(red: 0.25, green: 0.70, blue: 0.72),  //  5 — Teal
        Color(red: 0.87, green: 0.32, blue: 0.52),  //  6 — Rose
        Color(red: 0.40, green: 0.72, blue: 0.35),  //  7 — Sage
        Color(red: 0.92, green: 0.52, blue: 0.18),  //  8 — Sunset
        Color(red: 0.45, green: 0.55, blue: 0.75),  //  9 — Slate
        Color(red: 0.72, green: 0.55, blue: 0.30),  // 10 — Warm Sand
        Color(red: 0.38, green: 0.70, blue: 0.62),  // 11 — Sea Foam
    ]

    // MARK: - Access

    /// Returns the `Color` for the given palette index.
    ///
    /// Out-of-bounds indices are silently clamped to index 0 (Ocean Blue). This
    /// is intentional — it prevents a crash when a `HabitBoard` carrying a higher
    /// `colorIndex` from a future version is displayed on an older build.
    ///
    /// - Parameter index: Intended range is `0 ..< ColorPalette.count`. Values
    ///                    outside this range are accepted and clamped.
    /// - Returns: The `Color` at the clamped index.
    static subscript(index: Int) -> Color {
        let safe = max(0, min(index, colors.count - 1))
        return colors[safe]
    }

    /// The total number of colours in the palette.
    ///
    /// Use this to build the colour picker grid in `NewHabitForm` (Phase 7):
    /// ```swift
    /// ForEach(0 ..< ColorPalette.count, id: \.self) { index in
    ///     ColorSwatch(color: ColorPalette[index], isSelected: board.colorIndex == index)
    /// }
    /// ```
    static var count: Int { colors.count }

    // MARK: - Heatmap Cell Colour

    // MARK: Empty-Cell Colour (C2)
    //
    // `Color(.systemGray6)` calls `Color(UIColor.systemGray6)`, which does not
    // compile on macOS — UIColor is unavailable on that platform. The fix uses
    // a computed static property with #if canImport(UIKit) to select the
    // appropriate platform-native system color, maintaining correct adaptive
    // behaviour in both light and dark appearance modes on both targets.
    //
    // iOS:  UIColor.systemGray6 — the lightest system gray, used for grouped
    //       table cell backgrounds and similar low-emphasis fills.
    // macOS: NSColor.windowBackgroundColor — the window canvas background, which
    //        visually matches the intent of "an empty cell that blends with the
    //        surrounding surface."
    //
    // A named color in Assets.xcassets would be the most maintainable long-term
    // solution and should be adopted in Phase 7 when the design token system is
    // established. The conditional compilation here is an interim fix.

    /// The color rendered for heatmap cells with no log entries for that day.
    ///
    /// Platform-conditional: `UIColor.systemGray6` on iOS, `NSColor.windowBackgroundColor`
    /// on macOS. Both adapt correctly to light and dark appearance without additional
    /// modifier calls.
    static var emptyCellColor: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGray6)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    // MARK: Intensity Calculation (Appendix C, Engineering Principles)
    //
    // Cell opacity encodes daily completion relative to the board's target:
    //
    //   intensity = min(1.0, dayTotal / effectiveTarget)
    //
    // Clamped to [0, 1]: exceeding the target does not produce an opacity > 1.0.
    // A minimum opacity floor of 0.15 is applied to any day with at least one
    // log entry, ensuring it is visually distinguishable from a zero-entry day
    // even when the logged value is small relative to the target.
    //
    // Days with no entries receive `emptyCellColor` — a platform-native surface gray.

    /// Returns the heatmap cell colour for a board at the given daily completion ratio.
    ///
    /// This method encapsulates the colour math from Appendix C of the Engineering
    /// Principles, keeping the formula in one place and making it testable
    /// independently of the view layer.
    ///
    /// - Parameters:
    ///   - colorIndex: The board's `colorIndex`.
    ///   - ratio: `dayTotal / effectiveTarget`. Values ≤ 0 produce `emptyCellColor`.
    ///            Values > 1 are clamped to 1 (over-achievement is visually equivalent
    ///            to exactly meeting the target).
    /// - Returns: The board's palette colour at the appropriate opacity for
    ///            `ratio > 0`, or `emptyCellColor` for days with no entries.
    static func heatmapColor(forColorIndex colorIndex: Int, ratio: Double) -> Color {
        guard ratio > 0 else { return emptyCellColor }          // C2: platform-safe color

        // Clamp to [0, 1]: over-achievement is visually equivalent to exactly meeting the target
        let intensity = min(1.0, ratio)

        // Minimum opacity floor so any logged entry reads as distinctly filled
        let opacity = max(0.15, intensity)

        return Self[colorIndex].opacity(opacity)
    }
}
