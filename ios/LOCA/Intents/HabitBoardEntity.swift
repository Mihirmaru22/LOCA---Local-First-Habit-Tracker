//
//  HabitBoardEntity.swift
//  LOCA
//
//  Phase 8.1 — App Intents: Habit Entity Exposure
//
//  Exposes `HabitBoard` to the App Intents system so Siri and the Shortcuts
//  app can present, match, and select a habit as an intent parameter
//  (consumed by `LogHabitIntent`, Phase 8.2).
//

import AppIntents
import SwiftData
import Foundation
import os

// MARK: - HabitBoardEntity

/// An App Intents-facing snapshot of a `HabitBoard`.
///
/// ## Value-Type Snapshot, Not a Live Model
/// This entity stores plain value-type copies of the board's identity and
/// display-relevant fields — never a live `HabitBoard` (`@Model`) reference.
/// App Intents resolves and transports parameters across actor and process
/// boundaries; a SwiftData managed object is not `Sendable` and must not
/// cross those boundaries. `LogHabitIntent` (Phase 8.2) re-fetches the live
/// `HabitBoard` from its own `ModelContext` using `id` at write time, so the
/// snapshot never needs to be mutated or persisted.
///
/// ## Identity
/// `id` is `HabitBoard.id` (a `UUID`). This is the same identifier the write
/// path filters on via the denormalized `LogEntry.boardID` (ADR-003), so an
/// entity selected in Shortcuts resolves unambiguously back to its board.
struct HabitBoardEntity: AppEntity {

    // MARK: Stored Snapshot

    /// Mirrors `HabitBoard.id`. Stable join key for re-fetching the live board.
    let id: UUID

    /// Mirrors `HabitBoard.name`. Used as the entity's display title.
    let name: String

    /// Mirrors `HabitBoard.metricType` (`0` binary, `1` quantitative).
    /// Stored as the raw `Int` to keep the entity `Sendable` and decoupled
    /// from the model layer; decoded via `metric` for display logic.
    let metricType: Int

    /// Mirrors `HabitBoard.unitLabel` (e.g. `"mi"`). `nil` for binary habits.
    let unitLabel: String?

    /// Mirrors `HabitBoard.effectiveTarget` — the non-zero daily goal used for
    /// the display subtitle. Snapshotted so display logic needs no model access.
    let effectiveTarget: Double

    // MARK: Initialisers

    /// Memberwise initialiser used by the query and by test fixtures.
    init(id: UUID, name: String, metricType: Int, unitLabel: String?, effectiveTarget: Double) {
        self.id = id
        self.name = name
        self.metricType = metricType
        self.unitLabel = unitLabel
        self.effectiveTarget = effectiveTarget
    }

    /// Snapshots a live `HabitBoard` into a transport-safe entity.
    ///
    /// Reads `@Model` stored properties, so it is `@MainActor`-isolated and is
    /// only ever called from the query's main-actor fetch helper.
    @MainActor
    init(board: HabitBoard) {
        self.id = board.id
        self.name = board.name
        self.metricType = board.metricType
        self.unitLabel = board.unitLabel
        self.effectiveTarget = board.effectiveTarget
    }

    // MARK: Derived

    /// Type-safe decode of `metricType`, falling back to `.binary` for any
    /// unrecognised raw value (defence against a record from a future schema).
    var metric: HabitBoard.MetricType {
        HabitBoard.MetricType(rawValue: metricType) ?? .binary
    }

    // MARK: AppEntity Conformance

    /// The human-readable type name shown by Shortcuts when this entity is a
    /// parameter (e.g. the "Habit" label above the picker).
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Habit")
    }

    /// The query backing parameter resolution, suggestions, and Siri name
    /// matching for this entity.
    static let defaultQuery = HabitBoardEntityQuery()

    /// Per-instance display used in the picker row and Siri confirmations.
    ///
    /// Title is the habit name. Subtitle distinguishes the metric kind and,
    /// for quantitative habits, surfaces the daily goal ("Goal: 5 mi/day") so
    /// the user can disambiguate similarly-named boards at selection time.
    var displayRepresentation: DisplayRepresentation {
        switch metric {
        case .binary:
            return DisplayRepresentation(
                title: "\(name)",
                subtitle: "Check-off"
            )
        case .quantitative:
            let target = effectiveTarget.formatted(.number.precision(.fractionLength(0...1)))
            let unitSuffix = unitLabel.flatMap { $0.isEmpty ? nil : " \($0)" } ?? ""
            return DisplayRepresentation(
                title: "\(name)",
                subtitle: "Goal: \(target)\(unitSuffix)/day"
            )
        }
    }
}

// MARK: - HabitBoardEntityQuery

/// Resolves `HabitBoardEntity` values for App Intents parameter selection.
///
/// Conforms to `EntityStringQuery` so the entity supports all three resolution
/// paths the system needs:
/// - **By identifier** (`entities(for:)`) — reconnect a previously-selected
///   habit when a Shortcut runs.
/// - **By suggestion** (`suggestedEntities()`) — populate the picker with all
///   active habits.
/// - **By string** (`entities(matching:)`) — match a spoken/typed habit name
///   for Siri and Shortcuts search.
///
/// ## Container Caching
/// All paths use `ModelContainerFactory.extensionContainer` — the process-level
/// cached static — rather than calling `makeConfiguredContainer()` each time.
/// Creating a CloudKit-backed container is expensive; the cache ensures it pays
/// that cost at most once per process, matching the pattern `LogHabitIntent` uses.
/// It honours the `LOCAL_DEVELOPMENT` switch (ADR-009) automatically because
/// `extensionContainer` itself calls `makeConfiguredContainer()`.
///
/// ## Active Boards Only
/// All paths filter through `HabitBoard.activePredicate` (`archivedAt == nil`),
/// the single canonical active-board predicate. Soft-deleted boards (ADR-001)
/// are never offered as intent targets.
struct HabitBoardEntityQuery: EntityStringQuery {

    private static let logger = Logger(
        subsystem: "com.mihirmaru.loca",
        category: "Intents"
    )

    // MARK: Fetch Helper

    /// Fetches all active boards into transport-safe value snapshots.
    ///
    /// ## Why not @MainActor
    /// The AppIntents system calls the EntityQuery methods on the cooperative
    /// thread pool. The previous @MainActor annotation caused every AppIntents
    /// indexing pass (which runs ~1–2 s after each app launch) to block the
    /// main thread with a full CloudKit ModelContainer initialization, producing
    /// the first-interaction keyboard lag (Phase A.1 defect). Removing @MainActor
    /// lets this work stay off the main thread entirely.
    ///
    /// ## Why ModelContext(container) not container.mainContext
    /// `mainContext` is MainActor-bound. A background `ModelContext(container)`
    /// can be created and used on any thread; objects fetched from it can be
    /// read on that same thread. Since we immediately map to Sendable value
    /// types (HabitBoardEntity) before returning, the context is never shared
    /// across threads.
    ///
    /// ## Why extensionContainer
    /// `makeConfiguredContainer()` initializes a full CloudKit stack on every
    /// call — O(1) is not free when CloudKit is involved. `extensionContainer`
    /// is a process-level cached static let initialized once per process lifetime,
    /// matching the pattern LogHabitIntent already uses correctly.
    private static func activeBoardEntities() throws -> [HabitBoardEntity] {
        let container: ModelContainer
        if let cached = ModelContainerFactory.extensionContainer {
            container = cached
        } else {
            container = try ModelContainerFactory.makeConfiguredContainer()
        }
        // Background context — not MainActor-bound.
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<HabitBoard>(
            predicate: HabitBoard.activePredicate,
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let boards = try context.fetch(descriptor)
        // Map to value types here, on this thread, before the context goes out of scope.
        return boards.map { board in
            HabitBoardEntity(
                id: board.id,
                name: board.name,
                metricType: board.metricType,
                unitLabel: board.unitLabel,
                effectiveTarget: board.effectiveTarget
            )
        }
    }

    // MARK: EntityQuery Conformance

    /// Resolves entities for the given identifiers — used when a saved Shortcut
    /// re-runs and must reconnect its stored habit selection.
    ///
    /// Only active boards resolve: a habit archived after a Shortcut was built
    /// returns no match, so the intent surfaces "no longer available" rather
    /// than silently logging to a soft-deleted board.
    func entities(for identifiers: [UUID]) async throws -> [HabitBoardEntity] {
        let wanted = Set(identifiers)
        return try Self.activeBoardEntities().filter { wanted.contains($0.id) }
    }

    /// Supplies the full list of active habits for the Shortcuts parameter
    /// picker, in the app's creation-date order.
    func suggestedEntities() async throws -> [HabitBoardEntity] {
        try Self.activeBoardEntities()
    }

    // MARK: EntityStringQuery Conformance

    /// Matches active habits whose name contains `string`, case- and
    /// diacritic-insensitively — the path Siri uses to turn a spoken habit
    /// name into a concrete selection. An empty query returns all active
    /// habits so the picker still populates.
    func entities(matching string: String) async throws -> [HabitBoardEntity] {
        let all = try Self.activeBoardEntities()
        let needle = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(needle) }
    }
}
