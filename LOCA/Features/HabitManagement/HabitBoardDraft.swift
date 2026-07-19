//
//  HabitBoardDraft.swift
//  LOCA
//
//  Phase 10.2 — Updated: unitLabel replaced with UnitOption picker.
//

import Foundation

// MARK: - HabitBoardDraft

/// Editable, form-bindable staging state for a `HabitBoard`.
struct HabitBoardDraft {

    // MARK: Fields

    var name: String
    var metric: HabitBoard.MetricType
    var targetText: String

    /// Controlled unit selection. Replaces the free-text `unitLabel` field.
    var unit: UnitOption
    
    /// Custom unit text (overrides `unit` label if non-empty).
    var customUnitText: String = ""

    var colorIndex: Int
    
    /// If true, the habit card displays with a tinted background.
    var useColorBackground: Bool = false

    /// Optional emoji prefix shown on habit cards (e.g. "🏃", "📚").
    var emoji: String = ""

    // MARK: Initialisers

    init() {
        self.name = ""
        self.metric = .binary
        self.targetText = ""
        self.unit = .minutes
        self.customUnitText = ""
        self.colorIndex = 0
        self.useColorBackground = false
        self.emoji = ""
    }

    @MainActor
    init(from board: HabitBoard) {
        self.name = board.name
        self.metric = board.metric
        self.targetText = board.targetValue
            .map { $0.formatted(.number.precision(.fractionLength(0...2))) } ?? ""
        self.unit = UnitOption.from(label: board.unitLabel) ?? .minutes
        // If the label doesn't match a known unit, store it as custom text
        self.customUnitText = (UnitOption.from(label: board.unitLabel) == nil && board.unitLabel != nil) ? board.unitLabel! : ""
        self.colorIndex = board.colorIndex
        self.useColorBackground = board.useColorBackground
        self.emoji = board.emoji ?? ""
    }

    // MARK: Derived

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var parsedTarget: Double? {
        guard let value = Double(targetText.trimmingCharacters(in: .whitespaces)),
              value > 0
        else { return nil }
        return value
    }

    var isValid: Bool {
        guard !trimmedName.isEmpty else { return false }
        switch metric {
        case .binary:      return true
        case .quantitative: return parsedTarget != nil
        }
    }

    // MARK: Materialisation

    func makeBoard() -> HabitBoard {
        let effectiveUnit = !customUnitText.trimmingCharacters(in: .whitespaces).isEmpty 
            ? customUnitText 
            : unit.label
        let board = HabitBoard(
            name: trimmedName,
            metricType: metric.rawValue,
            targetValue: metric == .quantitative ? parsedTarget : nil,
            unitLabel: metric == .quantitative ? effectiveUnit : nil,
            colorIndex: colorIndex
        )
        board.useColorBackground = useColorBackground
        board.emoji = emoji.trimmingCharacters(in: .whitespaces).isEmpty ? nil : emoji
        return board
    }

    @MainActor
    func apply(to board: HabitBoard) {
        let effectiveUnit = !customUnitText.trimmingCharacters(in: .whitespaces).isEmpty 
            ? customUnitText 
            : unit.label
        board.name = trimmedName
        board.metricType = metric.rawValue
        board.targetValue = metric == .quantitative ? parsedTarget : nil
        board.unitLabel = metric == .quantitative ? effectiveUnit : nil
        board.colorIndex = colorIndex
        board.useColorBackground = useColorBackground
        board.emoji = emoji.trimmingCharacters(in: .whitespaces).isEmpty ? nil : emoji
    }
}
