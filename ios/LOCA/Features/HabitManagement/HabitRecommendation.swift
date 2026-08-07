//
//  HabitRecommendation.swift
//  LOCA
//
//  Phase 3.4 — Smart habit recommendations based on user patterns.
//
//  Suggests new habits based on:
//  - Existing habit coverage (time of day, habit types)
//  - Complementary habit stacks (research-backed pairings)
//  - User's logging patterns (when they're active)
//  - Time gaps in their schedule
//

import Foundation

struct HabitRecommendation: Identifiable {
    let id: String
    let template: HabitTemplate
    let reason: String
}

struct HabitRecommender {

    /// Generates personalized habit recommendations.
    /// Returns up to 3 recommendations based on user's existing habits and patterns.
    static func generateRecommendations(
        existingBoards: [HabitBoard],
        logs: [LogSnapshot],
        maxRecommendations: Int = 3
    ) -> [HabitRecommendation] {
        guard !existingBoards.isEmpty || !logs.isEmpty else {
            // New user: recommend foundational habits
            return recommendForNewUser(maxCount: maxRecommendations)
        }

        var scores: [String: Double] = [:]

        // Score based on habit coverage gaps
        scoreByGaps(existingBoards: existingBoards, scores: &scores)

        // Score based on complementary habits
        scoreByComplements(existingBoards: existingBoards, scores: &scores)

        // Score based on time patterns
        scoreByTimePatterns(logs: logs, scores: &scores)

        // Filter templates that aren't already created
        let existingNames = Set(existingBoards.map { $0.name.lowercased() })

        // Return top recommendations
        return scores
            .sorted { $0.value > $1.value }
            .prefix(maxRecommendations)
            .compactMap { templateID, score -> HabitRecommendation? in
                guard let template = HabitTemplate.templates.first(where: { $0.id == templateID }),
                      !existingNames.contains(template.name.lowercased()) else { return nil }

                let reason = reasonForTemplate(id: templateID, score: score)
                return HabitRecommendation(id: templateID, template: template, reason: reason)
            }
    }

    // MARK: - Scoring Strategies

    private static func recommendForNewUser(maxCount: Int) -> [HabitRecommendation] {
        // Beginner recommendations: foundational habits
        let beginner = ["meditation", "reading", "walking"]
        return beginner.compactMap { id in
            guard let template = HabitTemplate.templates.first(where: { $0.id == id }) else { return nil }
            return HabitRecommendation(
                id: id,
                template: template,
                reason: "A great habit to start with"
            )
        }
        .prefix(maxCount)
        .map { $0 }
    }

    private static func scoreByGaps(
        existingBoards: [HabitBoard],
        scores: inout [String: Double]
    ) {
        // Check for coverage of major habit categories
        let existingTypes = Set(existingBoards.map { board in
            guessHabitCategory(name: board.name)
        })

        let allCategories = ["health", "learning", "mindfulness", "social", "creative"]
        for category in allCategories {
            if !existingTypes.contains(category) {
                // Recommend a habit from this category
                let categoryTemplates = HabitTemplate.templates.filter { template in
                    guessHabitCategory(name: template.name) == category
                }
                for template in categoryTemplates {
                    scores[template.id, default: 0.0] += 0.5
                }
            }
        }
    }

    private static func scoreByComplements(
        existingBoards: [HabitBoard],
        scores: inout [String: Double]
    ) {
        // Research-backed habit complements
        let complements: [String: [String]] = [
            "running": ["stretching"],  // Not in templates yet
            "strength": ["stretching"], // Not in templates yet
            "meditation": ["journaling"],
            "reading": ["learning"],
            "walking": ["meditation"],
        ]

        for board in existingBoards {
            let lowerName = board.name.lowercased()
            for (habit, complementList) in complements {
                if lowerName.contains(habit) {
                    for complement in complementList {
                        if let template = HabitTemplate.templates.first(where: { $0.name.lowercased().contains(complement) }) {
                            scores[template.id, default: 0.0] += 0.7
                        }
                    }
                }
            }
        }
    }

    private static func scoreByTimePatterns(
        logs: [LogSnapshot],
        scores: inout [String: Double]
    ) {
        guard !logs.isEmpty else { return }

        // Find most common logging hour
        var hourCounts: [Int: Int] = [:]
        for log in logs {
            let hour = Calendar.current.component(.hour, from: log.timestamp)
            hourCounts[hour, default: 0] += 1
        }

        guard let mostCommonHour = hourCounts.max(by: { $0.value < $1.value })?.key else { return }

        // Recommend habits that align with that time
        let morningTemplates = ["meditation", "running", "learning"]
        let afternoonTemplates = ["reading", "strength"]
        let eveningTemplates = ["journaling", "walking"]

        let recommendedIDs: [String]
        if mostCommonHour < 12 {
            recommendedIDs = morningTemplates
        } else if mostCommonHour < 18 {
            recommendedIDs = afternoonTemplates
        } else {
            recommendedIDs = eveningTemplates
        }

        for id in recommendedIDs {
            scores[id, default: 0.0] += 0.3
        }
    }

    // MARK: - Helpers

    private static func guessHabitCategory(name: String) -> String {
        let lowerName = name.lowercased()
        if lowerName.contains("run") || lowerName.contains("walk") || lowerName.contains("strength") {
            return "health"
        } else if lowerName.contains("read") || lowerName.contains("learn") {
            return "learning"
        } else if lowerName.contains("meditate") || lowerName.contains("journal") {
            return "mindfulness"
        } else if lowerName.contains("call") || lowerName.contains("friend") {
            return "social"
        } else if lowerName.contains("write") || lowerName.contains("create") {
            return "creative"
        }
        return "other"
    }

    private static func reasonForTemplate(id: String, score: Double) -> String {
        switch id {
        case "meditation":
            return "Complements your existing habits"
        case "reading":
            return "Based on your schedule patterns"
        case "journaling":
            return "Pairs well with reflection"
        default:
            return "Recommended for you"
        }
    }
}
