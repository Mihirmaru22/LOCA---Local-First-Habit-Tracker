//
//  DS+Color.swift
//  LOCA
//
//  Phase 11 — Semantic color roles.
//
//  These roles layer ON TOP OF the frozen 12-entry ColorPalette (ADR-002). The
//  palette is never reordered or replaced; DS.Color only adds semantic surface,
//  text, and separator roles plus a typed accent accessor.
//
//  Cross-platform note: iOS system background/label colors are UIKit-backed and
//  unavailable on macOS. Surface and line roles are therefore defined with
//  #if os(iOS) / #else(AppKit) branches so both platforms build and each uses its
//  native semantic colors. Text tiers use SwiftUI's cross-platform semantic colors.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension DS {

    /// Semantic color roles. Habit accent colors still come from `ColorPalette`
    /// (indexed, append-only); these roles cover surfaces, text tiers, and lines.
    enum Color {

        // MARK: Accent (bridges to the frozen palette)

        /// The accent color for a given palette index (ADR-002). Thin wrapper so
        /// views depend on `DS.Color` rather than reaching into `ColorPalette`.
        static func accent(_ colorIndex: Int) -> SwiftUI.Color {
            ColorPalette[colorIndex]
        }

        // MARK: Surfaces (container tiers) — platform-native

        /// App background — the base canvas.
        static let background: SwiftUI.Color = {
            #if canImport(UIKit)
            SwiftUI.Color(uiColor: .systemBackground)
            #else
            SwiftUI.Color(nsColor: .windowBackgroundColor)
            #endif
        }()

        /// Raised surface — cards, tiles (one step above background).
        static let surface: SwiftUI.Color = {
            #if canImport(UIKit)
            SwiftUI.Color(uiColor: .secondarySystemBackground)
            #else
            SwiftUI.Color(nsColor: .controlBackgroundColor)
            #endif
        }()

        /// Recessed / grouped surface.
        static let surfaceRecessed: SwiftUI.Color = {
            #if canImport(UIKit)
            SwiftUI.Color(uiColor: .tertiarySystemBackground)
            #else
            SwiftUI.Color(nsColor: .underPageBackgroundColor)
            #endif
        }()

        // MARK: Text tiers (cross-platform semantic)

        static let textPrimary = SwiftUI.Color.primary
        static let textSecondary = SwiftUI.Color.secondary
        static let textTertiary: SwiftUI.Color = {
            #if canImport(UIKit)
            SwiftUI.Color(uiColor: .tertiaryLabel)
            #else
            SwiftUI.Color(nsColor: .tertiaryLabelColor)
            #endif
        }()

        // MARK: Lines

        /// Hairline separator — LOCA prefers these over container nesting.
        static let separator: SwiftUI.Color = {
            #if canImport(UIKit)
            SwiftUI.Color(uiColor: .separator)
            #else
            SwiftUI.Color(nsColor: .separatorColor)
            #endif
        }()

        // MARK: Heatmap (contribution grid)

        /// Heatmap grid background — darker than surface to provide contrast for cell
        /// opacity tiers. In light mode, a medium gray; in dark mode, very dark to
        /// extend the dark theme that the opacity values were tuned for.
        static let heatmapBackground: SwiftUI.Color = {
            #if canImport(UIKit)
            SwiftUI.Color(uiColor: .systemGray5).opacity(0.8)
            #else
            SwiftUI.Color(nsColor: .controlBackgroundColor)
            #endif
        }()

        /// Grid stroke / boundary — subtle visual separation between heatmap and
        /// surrounding card. Invisible in dark mode (already separated by background
        /// color), faint in light mode (helps define the grid boundary).
        static let heatmapGridStroke: SwiftUI.Color = {
            #if canImport(UIKit)
            SwiftUI.Color(uiColor: .systemGray4).opacity(0.3)
            #else
            SwiftUI.Color(nsColor: .separatorColor)
            #endif
        }()
    }
}
