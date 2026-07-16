//
//  HabitBoardDraft.swift
//  LOCA
//
//  Phase 7.1 — Habit Management: Form Staging Model
//
//  A pure value type that stages user input for creating or editing a
//  `HabitBoard`. Holds no SwiftData; owns validation and the create/edit
//  mutation rules so `HabitFormView` stays a thin presentation layer.
//

import Foundation

// MARK: - HabitBoardDraft

/// Editable, form-bindable staging state for a `HabitBoard`.
///
/// ## Why a Separate Value Type
/// The form must not mutate a live `HabitBoard` until the user confirms, and
/// create mode has no board to mutate at all. `HabitBoardDraft` is a plain
/// `struct` (no `@Model`, no `ModelContext`) that both modes bind to directly.
/// On save, `makeBoard()` produces a new board (create) or `apply(to:)` writes
/// the staged values onto an existing one (edit). This keeps all validation and
/// field-coercion logic in one testable place, independent of the view and the
/// persistence layer.
///
/// ## Raw Text Fields
/// `targetText` and `unitLabel` are stored as raw strings so they bind to
/// `TextField` without a parallel source of truth. `parsedTarget` converts the
/// goal text to a positive `Double` at validation and save time, mirroring
/// `CheckInSheet`'s `.decimalPad` parsing (locale decimal separators are not
/// handled — `.decimalPad` emits `.` on all iOS locales).
struct HabitBoardDraft {

    // MARK: Fields

    /// The habit's display name. Trimmed via `trimmedName` at validation/save.
    var name: String

    /// Whether the habit is a daily check-off or a measured amount.
    var metric: HabitBoard.MetricType

    /// Raw goal input for quantitative habits (e.g. `"5"`). Ignored for binary.
    var targetText: String

    /// Raw unit input for quantitative habits (e.g. `"mi"`). Ignored for binary.
    var unitLabel: String

    /// Index into `ColorPalette` for the board's accent color.
    var colorIndex: Int

    // MARK: Initialisers

    /// Empty draft for **create** mode: binary, no goal, first palette color.
    init() {
        self.name = ""
        self.metric = .binary
        self.targetText = ""
        self.unitLabel = ""
        self.colorIndex = 0
    }

    /// Pre-populated draft for **edit** mode.
    ///
    /// Reads the live board's configuration into editable fields. The goal is
    /// formatted back to a compact decimal string; a `nil` `targetValue`
    /// (binary board) yields an empty goal field. `@MainActor`-isolated because
    /// it reads `@Model` stored properties.
    @MainActor
    init(from board: HabitBoard) {
        self.name = board.name
        self.metric = board.metric
        self.targetText = board.targetValue
            .map { $0.formatted(.number.precision(.fractionLength(0...2))) } ?? ""
        self.unitLabel = board.unitLabel ?? ""
        self.colorIndex = board.colorIndex
    }

    // MARK: Derived

    /// The name with surrounding whitespace removed — the value actually persisted.
    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The parsed daily goal: a positive `Double`, or `nil` when the text is
    /// empty, non-numeric, zero, or negative.
    var parsedTarget: Double? {
        guard let value = Double(targetText.trimmingCharacters(in: .whitespaces)),
              value > 0
        else { return nil }
        return value
    }

    /// The trimmed unit label, coerced to `nil` when empty so no empty strings
    /// reach the store (consistent with `HabitBoard.unitLabel: String?`).
    private var normalizedUnit: String? {
        let trimmed = unitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Whether the current input can be saved.
    ///
    /// Requires a non-empty name always, and — for quantitative habits — a
    /// positive parsed goal. Binary habits need no goal. The unit is optional
    /// in all cases.
    var isValid: Bool {
        guard !trimmedName.isEmpty else { return false }
        switch metric {
        case .binary:
            return true
        case .quantitative:
            return parsedTarget != nil
        }
    }

    // MARK: Materialisation

    /// Builds a brand-new `HabitBoard` from the staged values (create mode).
    ///
    /// Binary habits pass `targetValue`/`unitLabel` as `nil` (the model's
    /// `effectiveTarget` substitutes `1.0`). Streak, `createdAt`, `archivedAt`,
    /// and `logs` are left at their initialiser defaults — never staged here.
    func makeBoard() -> HabitBoard {
        HabitBoard(
            name: trimmedName,
            metricType: metric.rawValue,
            targetValue: metric == .quantitative ? parsedTarget : nil,
            unitLabel: metric == .quantitative ? normalizedUnit : nil,
            colorIndex: colorIndex
        )
    }

    /// Writes the staged configuration onto an existing board (edit mode).
    ///
    /// Only user-configurable fields are touched — identity, timestamps,
    /// streak cache, archive state, and logs are untouched. Switching a board
    /// to binary clears its `targetValue`/`unitLabel`; switching to
    /// quantitative sets them from the parsed input. `@MainActor`-isolated
    /// because it mutates `@Model` stored properties.
    @MainActor
    func apply(to board: HabitBoard) {
        board.name = trimmedName
        board.metricType = metric.rawValue
        board.targetValue = metric == .quantitative ? parsedTarget : nil
        board.unitLabel = metric == .quantitative ? normalizedUnit : nil
        board.colorIndex = colorIndex
    }
}
