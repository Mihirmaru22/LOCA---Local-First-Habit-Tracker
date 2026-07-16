//
//  HeatmapWidget.swift
//  LOCAWidget
//
//  Phase 9.1 — WidgetKit: Widget Definition & Configuration
//
//  The configurable habit-heatmap widget (AppIntentConfiguration, per the
//  System Context Document) and its configuration intent, which reuses the
//  Phase 8 HabitBoardEntity for the habit picker.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - SelectHabitIntent

/// Widget configuration: which habit the heatmap shows.
///
/// The habit parameter is resolved by `HabitBoardEntityQuery` (Phase 8), which
/// offers only active (non-archived) boards. Optional — an unconfigured widget
/// falls back to the first active habit (see `HeatmapProvider`).
///
/// Statics are `let` (not stored `var`) so they satisfy the intent requirements
/// without tripping Swift 6's "global shared mutable state" check.
struct SelectHabitIntent: WidgetConfigurationIntent {

    static let title: LocalizedStringResource = "Select Habit"

    static let description = IntentDescription("Choose which habit the heatmap shows.")

    @Parameter(title: "Habit")
    var board: HabitBoardEntity?
}

// MARK: - LOCAHeatmapWidget

/// The habit-heatmap Home Screen widget.
///
/// Reads the shared App Group SwiftData store through `HeatmapProvider`, renders
/// the heatmap and today's progress, and (Phase 9.2) offers an interactive
/// check-in button. Supports the medium and large families — the heatmap needs
/// horizontal room to read.
struct LOCAHeatmapWidget: Widget {

    static let kind = "com.mihirmaru.loca.HeatmapWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
            intent: SelectHabitIntent.self,
            provider: HeatmapProvider()
        ) { entry in
            HeatmapWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Habit Heatmap")
        .description("See a habit's progress and check in.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
