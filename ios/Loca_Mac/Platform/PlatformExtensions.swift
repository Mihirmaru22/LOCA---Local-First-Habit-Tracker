import SwiftUI

// MARK: - View + Mac helpers

extension View {

    /// Applies the standard LOCA macOS window frame constraints.
    /// Call on the root window content view rather than the scene level so
    /// previews work without a `WindowGroup`.
    func macWindowFrame() -> some View {
        self.frame(
            minWidth:  DS.Mac.windowMinWidth,
            minHeight: DS.Mac.windowMinHeight
        )
    }

    /// Hides the view on platforms other than macOS.
    @ViewBuilder
    func macOnly() -> some View {
        #if os(macOS)
        self
        #endif
    }

    /// Hides the view on macOS; visible everywhere else.
    @ViewBuilder
    func excludeOnMac() -> some View {
        #if !os(macOS)
        self
        #endif
    }
}

// MARK: - Conditional toolbar placement

extension ToolbarItemPlacement {
    /// Maps to `.primaryAction` on iOS, `.automatic` on macOS so toolbar
    /// buttons land in the right place on each platform without `#if os`.
    static var primaryActionCrossPlatform: ToolbarItemPlacement {
        #if os(macOS)
        .automatic
        #else
        .primaryAction
        #endif
    }
}

// MARK: - NSApplication helpers (macOS only)

#if os(macOS)
import AppKit

extension NSApplication {
    /// Opens the System Settings (macOS 13+) or System Preferences pane
    /// for the given URL scheme without a hard compile-time version check.
    static func openSystemSettings(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
#endif
