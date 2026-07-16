//
//  HeatmapProvider.swift
//  LOCAWidget
//
//  Phase 9.1 — WidgetKit: Timeline Provider & Entry
//
//  Reads the shared App Group SwiftData store and builds a heatmap timeline
//  entry for the configured habit, reusing the app's compute layer
//  (HeatmapDataProvider) — no parallel persistence or aggregation.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - HeatmapEntry

/// A single timeline entry: a value-type snapshot of one habit plus its
/// pre-computed heatmap cells. Everything the widget view needs to render
/// without touching a `ModelContext` or a live `@Model` at render time.
struct HeatmapEntry: TimelineEntry {

    let date: Date

    /// The habit to display, or `nil` when nothing is configured and no active
    /// habit exists — the view renders its empty state.
    let board: BoardSnapshot?

    /// Pre-computed heatmap cells (oldest → newest), from `HeatmapDataProvider`.
    let cells: [DayCell]

    /// A transport-safe snapshot of a `HabitBoard`'s display fields.
    struct BoardSnapshot: Sendable {
        let id: UUID
        let name: String
        let colorIndex: Int
        let metric: HabitBoard.MetricType
        let unitLabel: String?
        let effectiveTarget: Double
        let currentStreak: Int
        let todayTotal: Double
    }
}

// MARK: - HeatmapProvider

/// Supplies timeline entries for the configurable habit-heatmap widget.
///
/// ## Shared Store, No Singleton
/// Each entry opens its own container via `ModelContainerFactory
/// .makeConfiguredContainer()` — the App Group store in production, the local
/// store under `LOCAL_DEVELOPMENT` (ADR-009) — the same discipline the App
/// Intents use. Fetches run on `@MainActor` (SwiftData `mainContext`), then the
/// grid is built off-main by `HeatmapDataProvider` (ADR-005 snapshot pattern).
///
/// ## Board Resolution
/// Uses the board chosen in the widget's configuration (`SelectHabitIntent`).
/// If none is chosen, falls back to the first active board so a freshly-added
/// widget is useful immediately. A configured board that has since been
/// archived resolves to `nil` (empty state), never a soft-deleted board.
struct HeatmapProvider: AppIntentTimelineProvider {

    typealias Entry = HeatmapEntry
    typealias Intent = SelectHabitIntent

    /// Days of history built into each entry. The view crops this to the widget
    /// family; 140 (20 weeks) fills `.systemLarge` and leaves headroom for
    /// `.systemMedium` (which shows the trailing ~14 weeks).
    private static let windowDays = 140

    // MARK: Placeholder

    func placeholder(in context: Context) -> HeatmapEntry {
        HeatmapEntry(date: Date(), board: nil, cells: [])
    }

    // MARK: Snapshot / Timeline

    func snapshot(for configuration: SelectHabitIntent, in context: Context) async -> HeatmapEntry {
        await makeEntry(configuredBoardID: configuration.board?.id)
    }

    func timeline(for configuration: SelectHabitIntent, in context: Context) async -> Timeline<HeatmapEntry> {
        let entry = await makeEntry(configuredBoardID: configuration.board?.id)

        // Reload at the next local midnight so "today", the streak, and the grid
        // roll over. Interactive check-ins (Phase 9.2) reload out-of-band via
        // WidgetRefreshCoordinator; this policy covers the passive day boundary.
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(60 * 60)

        return Timeline(entries: [entry], policy: .after(nextMidnight))
    }

    // MARK: Entry Construction

    /// Resolves the board, reads its logs from the shared store, and builds the
    /// heatmap grid. Returns an empty-state entry on any miss or failure so the
    /// widget always renders something.
    private func makeEntry(configuredBoardID: UUID?) async -> HeatmapEntry {
        do {
            let fetched = try await MainActor.run {
                () -> (snapshotFields: HeatmapEntry.BoardSnapshot, logs: [LogSnapshot], target: Double)? in
                let context = try ModelContainerFactory.makeConfiguredContainer().mainContext

                let board: HabitBoard?
                if let id = configuredBoardID {
                    var descriptor = FetchDescriptor<HabitBoard>(predicate: #Predicate { $0.id == id })
                    descriptor.fetchLimit = 1
                    board = try context.fetch(descriptor).first
                } else {
                    var descriptor = FetchDescriptor<HabitBoard>(
                        predicate: HabitBoard.activePredicate,
                        sortBy: [SortDescriptor(\.createdAt, order: .forward)]
                    )
                    descriptor.fetchLimit = 1
                    board = try context.fetch(descriptor).first
                }

                guard let board, board.archivedAt == nil else { return nil }

                // Logs fetched by denormalised boardID (ADR-003), not the relationship keypath.
                let boardID = board.id
                let logDescriptor = FetchDescriptor<LogEntry>(predicate: #Predicate { $0.boardID == boardID })
                let logs = try context.fetch(logDescriptor)

                let calendar = Calendar.current
                let startOfToday = calendar.startOfDay(for: Date())
                let todayTotal = logs
                    .filter { calendar.startOfDay(for: $0.timestamp) == startOfToday }
                    .reduce(0.0) { $0 + $1.value }

                let snapshot = HeatmapEntry.BoardSnapshot(
                    id: board.id,
                    name: board.name,
                    colorIndex: board.colorIndex,
                    metric: board.metric,
                    unitLabel: board.unitLabel,
                    effectiveTarget: board.effectiveTarget,
                    currentStreak: board.currentStreak,
                    todayTotal: todayTotal
                )
                return (snapshot, logs.map(LogSnapshot.init(from:)), board.effectiveTarget)
            }

            guard let fetched else {
                return HeatmapEntry(date: Date(), board: nil, cells: [])
            }

            let cells = await HeatmapDataProvider.buildDayGrid(
                snapshots: fetched.logs,
                target: fetched.target,
                windowDays: Self.windowDays
            )
            return HeatmapEntry(date: Date(), board: fetched.snapshotFields, cells: cells)
        } catch {
            return HeatmapEntry(date: Date(), board: nil, cells: [])
        }
    }
}
