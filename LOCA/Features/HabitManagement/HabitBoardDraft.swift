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

    var colorIndex: Int

    // MARK: Initialisers

    init() {
        self.name = ""
        self.metric = .binary
        self.targetText = ""
        self.unit = .minutes
        self.colorIndex = 0
    }

    @MainActor
    init(from board: HabitBoard) {
        self.name = board.name
        self.metric = board.metric
        self.targetText = board.targetValue
            .map { $0.formatted(.number.precision(.fractionLength(0...2))) } ?? ""
        self.unit = UnitOption.from(label: board.unitLabel) ?? .minutes
        self.colorIndex = board.colorIndex
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
        HabitBoard(
            name: trimmedName,
            metricType: metric.rawValue,
            targetValue: metric == .quantitative ? parsedTarget : nil,
            unitLabel: metric == .quantitative ? unit.label : nil,
            colorIndex: colorIndex
        )
    }

    @MainActor
    func apply(to board: HabitBoard) {
        board.name = trimmedName
        board.metricType = metric.rawValue
        board.targetValue = metric == .quantitative ? parsedTarget : nil
        board.unitLabel = metric == .quantitative ? unit.label : nil
        board.colorIndex = colorIndex
    }
}
