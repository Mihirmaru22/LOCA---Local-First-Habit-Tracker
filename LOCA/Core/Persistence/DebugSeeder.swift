#if DEBUG
import SwiftData
import Foundation

// MARK: - DebugSeeder

/// Populates the store with minimal sample data on Debug builds, so
/// `HabitDetailView`, `HeatmapView`, and `AnalyticsCardsView` can be
/// exercised in a running app before Phase 7 (New Habit creation) exists.
///
/// Entirely excluded from Release builds via `#if DEBUG` around this whole
/// file — there is no code path, symbol, or reference to this type in a
/// Release/App Store binary. This is temporary scaffolding, not a feature:
/// once Phase 7 ships a real habit-creation flow, this file is deleted
/// outright, not folded into production code.
///
/// ## Usage
///
/// No action needed — `LOCAApp.init()` calls `seedIfNeeded(context:)`
/// automatically after container construction. It checks for existing
/// active boards first and does nothing if any exist, so it seeds exactly
/// once per fresh store and never duplicates or overwrites real data.
///
/// To re-seed from scratch: delete the app from the Simulator/device (or
/// delete its Application Support container) so `ModelContainerFactory`
/// starts from an empty store on next launch.
enum DebugSeeder {

    /// Inserts two sample `HabitBoard`s with ~60 days of log history each,
    /// only if no active board already exists.
    ///
    /// Streak values are hardcoded rather than derived by replaying
    /// `HabitBoard.updateStreak(using:)` over the synthetic entries — that
    /// method is designed for one-new-entry-at-a-time incremental updates,
    /// not batch historical replay, and introducing that dependency here
    /// would make this "minimal" seeder noticeably less minimal for no
    /// benefit. This matches the same hardcoded-streak convention every
    /// `#Preview` in this codebase already uses.
    ///
    /// - Parameter context: The live app's `ModelContext`, from
    ///   `container.mainContext`. Must be called on `@MainActor`.
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<HabitBoard>(predicate: HabitBoard.activePredicate)
        guard let existing = try? context.fetch(descriptor), existing.isEmpty else {
            return // Real data already exists — never overwrite it.
        }

        let calendar = Calendar.current

        let running = HabitBoard(
            name: "Running",
            metricType: HabitBoard.MetricType.quantitative.rawValue,
            targetValue: 3.0,
            unitLabel: "mi",
            colorIndex: 0
        )
        running.currentStreak = 4
        running.longestStreak = 9
        context.insert(running)

        for offset in stride(from: 0, to: 60, by: 2) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            context.insert(LogEntry(
                timestamp: date,
                value: Double.random(in: 1.5...4.5),
                boardID: running.id,
                board: running
            ))
        }

        let meditate = HabitBoard(name: "Meditate", colorIndex: 5)
        meditate.currentStreak = 2
        meditate.longestStreak = 15
        context.insert(meditate)

        for offset in stride(from: 0, to: 60, by: 3) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }
            context.insert(LogEntry(
                timestamp: date,
                value: 1.0,
                boardID: meditate.id,
                board: meditate
            ))
        }

        do {
            try context.save()
        } catch {
            // Debug-only convenience seeding — a failure here means the app
            // simply launches with an empty store, same as if seeding had
            // never run. Not worth a full PersistenceError/logging path for
            // scaffolding that gets deleted once Phase 7 exists.
        }
    }
}
#endif
