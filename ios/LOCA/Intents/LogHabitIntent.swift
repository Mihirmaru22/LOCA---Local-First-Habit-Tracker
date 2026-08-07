//
//  LogHabitIntent.swift
//  LOCA
//
//  Phase 8.2 — App Intents: Log Habit Action
//
//  The write-side App Intent. Logs a check-in for a habit selected via
//  `HabitBoardEntity` (Phase 8.1), from Siri or the Shortcuts app, without
//  opening the app. Reuses the exact Phase 6 check-in primitives — it does
//  not introduce a parallel write path.
//

import AppIntents
import SwiftData
import Foundation
import os

// MARK: - LogHabitIntent

/// Logs a `LogEntry` for a chosen `HabitBoard` from Siri and Shortcuts.
///
/// ## Reused Write Path (no parallel business logic)
/// `perform()` executes the identical sequence used by `CheckInButton`
/// (binary) and `CheckInSheet` (quantitative):
///
/// ```
/// insert(entry) → board.updateStreak(using:) → save() → scheduleReload()
/// ```
///
/// It composes the same primitives — the `LogEntry` designated initialiser
/// (with the ADR-003 `boardID`/`board` pairing), `HabitBoard.updateStreak`,
/// the `WidgetRefreshCoordinator` debounce, and the save/rollback error
/// discipline — rather than reimplementing check-in behaviour for intents.
///
/// ## Own Context, No Singleton
/// Per the App Intents rule in the Engineering Principles verification
/// checklist, `perform()` builds its **own** `ModelContext` from
/// `ModelContainerFactory.makeConfiguredContainer()` (App Group store in
/// production, local store under `LOCAL_DEVELOPMENT` — ADR-009). It never
/// reads the main app's injected container or any shared singleton. The
/// `HabitBoardEntity` parameter carries only a `UUID`; the live `HabitBoard`
/// is re-fetched here so the streak mutation and relationship write occur on
/// managed objects owned by this context.
///
/// ## Binary vs Quantitative
/// - **Binary**: `amount` is ignored; the entry logs `1.0`.
/// - **Quantitative**: a positive `amount` is required. If it is absent (or
///   non-positive), the intent requests it via `needsValueError`, so Siri and
///   Shortcuts prompt for the value and re-run — the App Intents equivalent of
///   `CheckInSheet`'s value field.
///
/// ## Side Effects
/// `openAppWhenRun = false`: logging is silent, matching the check-in
/// primitive's "never await the UI" contract. A spoken/positive confirmation
/// dialog is returned on success.
struct LogHabitIntent: AppIntent {

    // MARK: Metadata

    static let title: LocalizedStringResource = "Log Habit"

    static let description = IntentDescription(
        "Logs a check-in for one of your habits.",
        categoryName: "Tracking"
    )

    /// Silent logging — the intent completes without foregrounding the app,
    /// consistent with the local-first "UI never awaits" principle.
    static let openAppWhenRun: Bool = false

    // MARK: Parameters

    /// The habit to log against. Resolved through `HabitBoardEntityQuery`
    /// (Phase 8.1), which offers only active (non-archived) boards.
    @Parameter(title: "Habit")
    var board: HabitBoardEntity

    /// The amount to log for a quantitative habit (e.g. `3.2` miles).
    ///
    /// Optional at the parameter level so binary habits need no value and so
    /// quantitative habits can be prompted for it at run time via
    /// `needsValueError`. Ignored entirely for binary habits.
    @Parameter(title: "Amount")
    var amount: Double?

    /// An optional journal note, mirroring `CheckInSheet`'s note field.
    /// Whitespace-only input is coerced to `nil` before persistence.
    @Parameter(title: "Note")
    var note: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$board)") {
            \.$amount
            \.$note
        }
    }

    // MARK: Dependencies

    private var logger: Logger {
        Logger(subsystem: "com.mihirmaru.loca", category: "Intents")
    }

    // MARK: Perform

    /// Resolves the live board, logs the entry, updates the streak, saves, and
    /// schedules a widget reload — then returns a confirmation dialog.
    ///
    /// `@MainActor`-isolated: `ModelContext.mainContext`, the `@Model`
    /// mutations (`updateStreak`, relationship write), and
    /// `WidgetRefreshCoordinator.shared` are all main-actor bound.
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = try makeContext()
        let liveBoard = try fetchActiveBoard(id: board.id, in: context)
        let loggedValue = try resolveValue(for: liveBoard)

        do {
            try CheckInWriter.insert(
                value: loggedValue,
                note:  normalizedNote(),
                board: liveBoard,
                context: context
            )
        } catch {
            logger.error(
                "App Intent check-in save failed for board '\(liveBoard.name, privacy: .public)': \(error.localizedDescription, privacy: .public)"
            )
            throw LogHabitError.saveFailed
        }

        logger.debug(
            "App Intent check-in saved: \(loggedValue, privacy: .public) for board '\(liveBoard.name, privacy: .public)'."
        )

        return .result(dialog: confirmationDialog(for: liveBoard, value: loggedValue))
    }

    // MARK: Steps

    /// Returns the process-cached container's main context, falling back to a
    /// freshly constructed container if the cache is unavailable.
    @MainActor
    private func makeContext() throws -> ModelContext {
        if let cached = ModelContainerFactory.extensionContainer {
            return cached.mainContext
        }
        do {
            return try ModelContainerFactory.makeConfiguredContainer().mainContext
        } catch {
            logger.error(
                "App Intent container init failed: \(error.localizedDescription, privacy: .public)"
            )
            throw LogHabitError.storeUnavailable
        }
    }

    /// Re-fetches the live, non-archived `HabitBoard` for the selected entity.
    ///
    /// Filters by the board's own `id` (a direct stored property — unaffected
    /// by the relationship-keypath limitation ADR-003 addresses). A board
    /// archived after a Shortcut was built resolves to `nil` and surfaces
    /// `boardUnavailable` rather than logging to a soft-deleted board.
    @MainActor
    private func fetchActiveBoard(id: UUID, in context: ModelContext) throws -> HabitBoard {
        var descriptor = FetchDescriptor<HabitBoard>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard
            let liveBoard = try context.fetch(descriptor).first,
            liveBoard.archivedAt == nil
        else {
            throw LogHabitError.boardUnavailable
        }
        return liveBoard
    }

    /// Determines the value to log. Binary → `1.0`; quantitative → a positive
    /// `amount`, requesting it via `needsValueError` when absent.
    @MainActor
    private func resolveValue(for board: HabitBoard) throws -> Double {
        switch board.metric {
        case .binary:
            return 1.0
        case .quantitative:
            guard let entered = amount, entered > 0 else {
                throw $amount.needsValueError(
                    "How much did you complete for \(board.name)?"
                )
            }
            return entered
        }
    }

    /// Trims the note and coerces empty/whitespace-only input to `nil`, so no
    /// empty strings reach the store (parity with `CheckInSheet`).
    private func normalizedNote() -> String? {
        guard let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty
        else { return nil }
        return trimmed
    }

    /// Builds a natural, first-party-feeling spoken confirmation. Binary logs
    /// surface an active streak; quantitative logs echo the amount and unit.
    @MainActor
    private func confirmationDialog(for board: HabitBoard, value: Double) -> IntentDialog {
        switch board.metric {
        case .binary:
            if board.currentStreak > 1 {
                return IntentDialog("Logged \(board.name). \(board.currentStreak)-day streak!")
            }
            return IntentDialog("Logged \(board.name).")
        case .quantitative:
            let amountStr = value.formatted(.number.precision(.fractionLength(0...2)))
            let unitSuffix = board.unitLabel.flatMap { $0.isEmpty ? nil : " \($0)" } ?? ""
            return IntentDialog("Logged \(amountStr)\(unitSuffix) for \(board.name).")
        }
    }
}

// MARK: - LogHabitError

/// User-facing failures surfaced by `LogHabitIntent`.
///
/// Conforms to `CustomLocalizedStringResourceConvertible` so Siri and Shortcuts
/// present the message directly rather than a generic failure.
enum LogHabitError: Error, CustomLocalizedStringResourceConvertible {
    /// The intent-owned data store could not be initialised.
    case storeUnavailable
    /// The selected habit no longer exists or has been archived.
    case boardUnavailable
    /// The check-in could not be persisted; the insert was rolled back.
    case saveFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .storeUnavailable:
            return "LOCA couldn't open its data store."
        case .boardUnavailable:
            return "That habit is no longer available."
        case .saveFailed:
            return "The check-in couldn't be saved. Please try again."
        }
    }
}
