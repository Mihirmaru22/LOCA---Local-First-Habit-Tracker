import WidgetKit
import SwiftUI

// MARK: - LOCAWidgetBundle

/// The Widget Extension's entry point.
///
/// Registers LOCA's Home Screen widgets. Phase 9.1 adds the configurable
/// habit-heatmap widget; further widgets (if any) are registered alongside it.
@main
struct LOCAWidgetBundle: WidgetBundle {
    var body: some Widget {
        LOCAHeatmapWidget()
    }
}
