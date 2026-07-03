import WidgetKit
import SwiftUI

// MARK: - LOCAWidgetBundle

/// The Widget Extension's entry point.
///
/// Empty by design — zero widgets are registered here. This file exists purely
/// so the LOCAWidgetExtension target has a valid principal class to build
/// against; Xcode requires a `@main WidgetBundle` conformer for any Widget
/// Extension target to compile at all; without one, the target fails to build
/// regardless of what else is or isn't in it.
///
/// This is scaffolding, not a Phase 9 feature — the same standard applied to
/// `LOCAApp.swift` in Phase 0 (an entry point with real setup logic but zero
/// user-facing feature content). Actual widget definitions (timeline providers,
/// widget views, configurations) are Phase 9 scope and do not appear here.
@main
struct LOCAWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Intentionally empty. Phase 9 adds widget definitions here.
    }
}
