//
//  UnitOption.swift
//  LOCA
//
//  Phase 10.2 — Controlled unit selection for quantitative habits.
//  Metric-only, extensible by adding cases to each Category.
//

import Foundation

// MARK: - UnitOption

/// A controlled, metric-first unit for a quantitative habit's daily goal.
///
/// Adding a new unit requires only a new case in the appropriate `Category`
/// plus its `label` string — no UI redesign. The raw value (`label`) is what
/// is stored in `HabitBoard.unitLabel` for display in the detail view,
/// preserving backward compatibility with any existing stored values.
enum UnitOption: String, CaseIterable, Identifiable {

    // Distance
    case meters   = "m"
    case km       = "km"

    // Weight
    case grams    = "g"
    case kg       = "kg"

    // Volume
    case ml       = "mL"
    case liters   = "L"

    // Time
    case seconds  = "sec"
    case minutes  = "min"
    case hours    = "hr"

    // Count
    case reps     = "reps"
    case sets     = "sets"
    case pages    = "pages"
    case glasses  = "glasses"
    case sessions = "sessions"
    case items    = "items"

    // Energy
    case kcal     = "kcal"

    // Money
    case usd      = "$"
    case eur      = "€"
    case gbp      = "£"

    // Percentage
    case percent  = "%"

    var id: String { rawValue }

    /// The short label stored in `HabitBoard.unitLabel` and shown in the UI.
    var label: String { rawValue }

    /// The display name shown in the picker (longer form where helpful).
    var displayName: String {
        switch self {
        case .meters:   return "Meters (m)"
        case .km:       return "Kilometers (km)"
        case .grams:    return "Grams (g)"
        case .kg:       return "Kilograms (kg)"
        case .ml:       return "Milliliters (mL)"
        case .liters:   return "Liters (L)"
        case .seconds:  return "Seconds (sec)"
        case .minutes:  return "Minutes (min)"
        case .hours:    return "Hours (hr)"
        case .reps:     return "Reps"
        case .sets:     return "Sets"
        case .pages:    return "Pages"
        case .glasses:  return "Glasses"
        case .sessions: return "Sessions"
        case .items:    return "Items"
        case .kcal:     return "Calories (kcal)"
        case .usd:      return "US Dollars ($)"
        case .eur:      return "Euros (€)"
        case .gbp:      return "British Pounds (£)"
        case .percent:  return "Percent (%)"
        }
    }

    /// The category this unit belongs to, used to group the picker.
    var category: Category { Category.containing(self) }

    // MARK: - Category

    enum Category: String, CaseIterable {
        case distance = "Distance"
        case weight   = "Weight"
        case volume   = "Volume"
        case time     = "Time"
        case count    = "Count"
        case energy   = "Energy"
        case money    = "Money"
        case percent  = "Other"

        var units: [UnitOption] {
            switch self {
            case .distance: return [.meters, .km]
            case .weight:   return [.grams, .kg]
            case .volume:   return [.ml, .liters]
            case .time:     return [.seconds, .minutes, .hours]
            case .count:    return [.reps, .sets, .pages, .glasses, .sessions, .items]
            case .energy:   return [.kcal]
            case .money:    return [.usd, .eur, .gbp]
            case .percent:  return [.percent]
            }
        }

        static func containing(_ unit: UnitOption) -> Category {
            allCases.first { $0.units.contains(unit) } ?? .count
        }
    }

    /// Resolves a stored `unitLabel` string back to a `UnitOption`, or nil if
    /// the label doesn't match any known unit (e.g. a value set before this
    /// picker existed — the form falls back to `.minutes` in that case).
    static func from(label: String?) -> UnitOption? {
        guard let label else { return nil }
        return allCases.first { $0.label == label }
    }
}
