//
//  UnitInference.swift
//  LOCA
//
//  Phase 2.1 — Unit inference from habit name.
//
//  Given a habit name, intelligently guess the most likely unit for
//  tracking. Used during quantitative habit creation to reduce user
//  decision friction while remaining easy to override.
//

import Foundation

struct UnitInference {

    /// Infer the most likely unit for a habit based on its name.
    /// Returns nil if no strong match; caller should use a default.
    static func inferUnit(from habitName: String) -> UnitOption? {
        let lowercased = habitName.lowercased()

        // Distance activities
        if matches(lowercased, patterns: ["run", "jog", "walk", "bike", "cycle", "hike", "climb", "drive"]) {
            return .km
        }

        // Reading/learning
        if matches(lowercased, patterns: ["read", "book", "writing", "write", "article"]) {
            return .pages
        }

        // Time-based activities
        if matches(lowercased, patterns: ["meditate", "meditation", "stretch", "yoga", "breathe", "focus", "study", "practice", "code", "draw", "paint", "piano", "guitar", "learn", "listen"]) {
            return .minutes
        }

        // Strength/reps
        if matches(lowercased, patterns: ["push", "pull", "squat", "lift", "bench", "curl", "plank"]) {
            return .reps
        }

        // Calories/energy
        if matches(lowercased, patterns: ["burn", "calorie", "exercise", "cardio"]) {
            return .kcal
        }

        // Water intake
        if matches(lowercased, patterns: ["water", "hydrate", "drink"]) {
            return .glasses
        }

        // Weight tracking
        if matches(lowercased, patterns: ["weight", "lose", "gain", "diet"]) {
            return .kg
        }

        // Sessions/frequency
        if matches(lowercased, patterns: ["gym", "swim", "sport", "game", "match", "sleep"]) {
            return .sessions
        }

        // Default: none, let user choose
        return nil
    }

    private static func matches(_ text: String, patterns: [String]) -> Bool {
        patterns.contains { pattern in
            text.contains(pattern)
        }
    }
}

// MARK: - DimensionInference (Version 2.0 · P0)

/// Infers which life dimension a habit most plausibly moves, so a habit check-in
/// tags its bridged `.explicitLog` signal with a dimension and the life model can
/// look for habit ↔ state correlations (the V2.0 "T2" layer).
///
/// Returns one of the four dimensions the inference engine understands
/// (`"energy"`, `"mood"`, `"stress"`, `"focus"`) or `nil` when no confident mapping
/// exists. `nil` is safe: the habit still produces an `.explicitLog` signal and an
/// `InferredState`; it simply isn't attributed to a specific dimension.
struct DimensionInference {

    static func infer(from habitName: String) -> String? {
        let name = habitName.lowercased()

        // Calming / stress-reducing practices
        if matches(name, ["meditat", "breath", "yoga", "relax", "calm", "mindful", "stretch", "unwind", "pray"]) {
            return "stress"
        }
        // Mood / reflection / connection
        if matches(name, ["journal", "gratitude", "reflect", "mood", "therapy", "connect", "call", "friend", "social"]) {
            return "mood"
        }
        // Focus / cognitive work
        if matches(name, ["read", "study", "work", "code", "focus", "learn", "practice", "write", "deep", "review", "plan"]) {
            return "focus"
        }
        // Energy / physical / fuel
        if matches(name, ["run", "jog", "walk", "bike", "cycl", "gym", "workout", "exercise", "lift", "swim", "cardio", "step", "sleep", "nap", "rest", "hydrat", "water", "eat", "diet", "vitamin"]) {
            return "energy"
        }
        return nil
    }

    private static func matches(_ text: String, _ patterns: [String]) -> Bool {
        patterns.contains { text.contains($0) }
    }
}
