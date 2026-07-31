//
//  UserProfile.swift
//  LOCA
//
//  V2.0B.5 — Lightweight user body profile.
//  Stores height, weight, goal weight, birth year, sex, and activity level.
//  Derives BMI, BMR (Mifflin-St Jeor), TDEE, and goal-weight projection as
//  computed properties so nothing stale is ever persisted.
//

import SwiftData
import Foundation

// MARK: - Supporting enums

enum BiologicalSex: Int, CaseIterable, Identifiable {
    case unspecified = 0, male = 1, female = 2
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .unspecified: return "Prefer not to say"
        case .male:        return "Male"
        case .female:      return "Female"
        }
    }
}

enum ActivityLevel: Int, CaseIterable, Identifiable {
    case sedentary = 0, light = 1, moderate = 2, active = 3, veryActive = 4
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .sedentary:  return "Sedentary"
        case .light:      return "Lightly Active"
        case .moderate:   return "Moderately Active"
        case .active:     return "Very Active"
        case .veryActive: return "Extremely Active"
        }
    }
    var hint: String {
        switch self {
        case .sedentary:  return "Little or no exercise"
        case .light:      return "Light exercise 1–3 days/week"
        case .moderate:   return "Moderate exercise 3–5 days/week"
        case .active:     return "Hard exercise 6–7 days/week"
        case .veryActive: return "Physical job or twice-daily training"
        }
    }
    var multiplier: Double {
        switch self {
        case .sedentary:  return 1.2
        case .light:      return 1.375
        case .moderate:   return 1.55
        case .active:     return 1.725
        case .veryActive: return 1.9
        }
    }
}

// MARK: - BMI Category

enum BMICategory {
    case underweight, normal, overweight, obese

    init(bmi: Double) {
        if      bmi < 18.5 { self = .underweight }
        else if bmi < 25.0 { self = .normal }
        else if bmi < 30.0 { self = .overweight }
        else               { self = .obese }
    }

    var label: String {
        switch self {
        case .underweight: return "Underweight"
        case .normal:      return "Normal"
        case .overweight:  return "Overweight"
        case .obese:       return "Obese"
        }
    }

    var colorHex: String {
        switch self {
        case .underweight: return "#60A5FA"
        case .normal:      return "#10B981"
        case .overweight:  return "#F59E0B"
        case .obese:       return "#EF4444"
        }
    }
}

// MARK: - UserProfile

@Model final class UserProfile {
    var id: UUID = UUID()
    var heightCm: Double? = nil       // always stored in cm
    var weightKg: Double? = nil       // always stored in kg
    var goalWeightKg: Double? = nil
    var birthYear: Int? = nil
    var sexRaw: Int = BiologicalSex.unspecified.rawValue
    var activityLevelRaw: Int = ActivityLevel.moderate.rawValue
    var preferKg: Bool = true
    var preferCm: Bool = true
    var updatedAt: Date = Date()

    init() {}

    // MARK: - Typed accessors

    var sex: BiologicalSex {
        get { BiologicalSex(rawValue: sexRaw) ?? .unspecified }
        set { sexRaw = newValue.rawValue }
    }

    var activityLevel: ActivityLevel {
        get { ActivityLevel(rawValue: activityLevelRaw) ?? .moderate }
        set { activityLevelRaw = newValue.rawValue }
    }

    // MARK: - Age

    var age: Int? {
        guard let y = birthYear, y > 1900 else { return nil }
        return Calendar.current.component(.year, from: Date()) - y
    }

    // MARK: - BMI

    var bmi: Double? {
        guard let w = weightKg, let h = heightCm, h > 0, w > 0 else { return nil }
        let hm = h / 100.0
        return w / (hm * hm)
    }

    var bmiCategory: BMICategory? {
        bmi.map(BMICategory.init)
    }

    // MARK: - BMR  (Mifflin-St Jeor)

    var bmr: Double? {
        guard let w = weightKg, let h = heightCm, let a = age,
              w > 0, h > 0, a > 0, sex != .unspecified else { return nil }
        let base = 10.0 * w + 6.25 * h - 5.0 * Double(a)
        return sex == .male ? base + 5.0 : base - 161.0
    }

    // MARK: - TDEE

    var tdee: Double? {
        bmr.map { $0 * activityLevel.multiplier }
    }

    // MARK: - Goal projection

    /// Weeks to goal at a moderate deficit of ≈ 0.45 kg / week (500 kcal / day).
    var weeksToGoal: Int? {
        guard let w = weightKg, let g = goalWeightKg, abs(w - g) > 0.1 else { return nil }
        return max(1, Int((abs(w - g) / 0.45).rounded()))
    }

    var isLosingWeight: Bool {
        guard let w = weightKg, let g = goalWeightKg else { return false }
        return g < w
    }
}
