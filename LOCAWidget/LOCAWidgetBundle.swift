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
        DiagnosticWidget()   // TEMP (Phase 9 debug): remove once registration is confirmed
    }
}

// MARK: - DiagnosticWidget (TEMPORARY)

/// A minimal `StaticConfiguration` widget with no App Intents and no store
/// access. Used only to bisect a macOS registration failure: if this appears in
/// the widget gallery but `LOCAHeatmapWidget` does not, the problem is isolated
/// to App Intents metadata for the configurable widget (not the extension
/// itself). Delete once the heatmap widget is confirmed to register.
struct DiagnosticWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "com.mihirmaru.loca.DiagnosticWidget",
            provider: DiagnosticProvider()
        ) { _ in
            Text("LOCA ✓")
                .font(.headline)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("LOCA Test")
        .description("Temporary diagnostic widget.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DiagnosticEntry: TimelineEntry {
    let date: Date
}

struct DiagnosticProvider: TimelineProvider {
    func placeholder(in context: Context) -> DiagnosticEntry {
        DiagnosticEntry(date: Date())
    }
    func getSnapshot(in context: Context, completion: @escaping (DiagnosticEntry) -> Void) {
        completion(DiagnosticEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DiagnosticEntry>) -> Void) {
        completion(Timeline(entries: [DiagnosticEntry(date: Date())], policy: .never))
    }
}
