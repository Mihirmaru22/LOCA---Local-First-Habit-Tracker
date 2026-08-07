//
//  HabitTemplate.swift
//  LOCA
//
//  Phase 2.5 — Research-backed habit templates.
//
//  Pre-configured templates for common habits with scientifically-informed
//  goals, units, and reminder times. Reduces setup time while remaining
//  fully customizable.
//

import Foundation

struct HabitTemplate: Identifiable {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let metricType: HabitBoard.MetricType
    let suggestedGoal: Double?
    let suggestedUnit: UnitOption?
    let suggestedReminderTime: String?

    static let templates: [HabitTemplate] = [
        // Health & Fitness
        HabitTemplate(
            id: "running",
            name: "Morning Run",
            description: "Start your day with a run. Research suggests 20–30 min is ideal for habit formation.",
            emoji: "🏃",
            metricType: .quantitative,
            suggestedGoal: 5.0,
            suggestedUnit: .km,
            suggestedReminderTime: "06:30"
        ),
        HabitTemplate(
            id: "walking",
            name: "Daily Walk",
            description: "A gentle daily walk. 30 min or ~3 km aids cardiovascular health and mental clarity.",
            emoji: "🚶",
            metricType: .quantitative,
            suggestedGoal: 3.0,
            suggestedUnit: .km,
            suggestedReminderTime: "09:00"
        ),
        HabitTemplate(
            id: "strength",
            name: "Strength Training",
            description: "Resistance work 3x per week. Recommended: 30–45 min sessions.",
            emoji: "💪",
            metricType: .quantitative,
            suggestedGoal: 40.0,
            suggestedUnit: .minutes,
            suggestedReminderTime: "18:00"
        ),

        // Learning & Growth
        HabitTemplate(
            id: "reading",
            name: "Reading",
            description: "Expand your knowledge. 30 pages per day builds a strong reading habit.",
            emoji: "📚",
            metricType: .quantitative,
            suggestedGoal: 30.0,
            suggestedUnit: .pages,
            suggestedReminderTime: "21:00"
        ),
        HabitTemplate(
            id: "learning",
            name: "Learning",
            description: "Learn something new. 30–60 min daily of deliberate practice compounds over time.",
            emoji: "🧠",
            metricType: .quantitative,
            suggestedGoal: 45.0,
            suggestedUnit: .minutes,
            suggestedReminderTime: "10:00"
        ),

        // Mindfulness & Well-being
        HabitTemplate(
            id: "meditation",
            name: "Meditation",
            description: "Practice mindfulness. 10–20 min daily is optimal for cognitive benefits.",
            emoji: "🧘",
            metricType: .quantitative,
            suggestedGoal: 15.0,
            suggestedUnit: .minutes,
            suggestedReminderTime: "07:00"
        ),
        HabitTemplate(
            id: "journaling",
            name: "Journaling",
            description: "Reflect on your day. 10 min of writing clarifies thoughts and builds self-awareness.",
            emoji: "📝",
            metricType: .quantitative,
            suggestedGoal: 10.0,
            suggestedUnit: .minutes,
            suggestedReminderTime: "21:30"
        ),

        // Social & Connection
        HabitTemplate(
            id: "call_friend",
            name: "Call a Friend",
            description: "Maintain relationships. One meaningful call per week strengthens bonds.",
            emoji: "📞",
            metricType: .binary,
            suggestedGoal: nil,
            suggestedUnit: nil,
            suggestedReminderTime: "19:00"
        ),

        // Creative & Productivity
        HabitTemplate(
            id: "writing",
            name: "Creative Writing",
            description: "Express yourself. 500–1000 words daily builds writing skill and clarity.",
            emoji: "✍️",
            metricType: .quantitative,
            suggestedGoal: 750.0,
            suggestedUnit: .items,
            suggestedReminderTime: "09:00"
        ),
    ]

    static func byCategory() -> [String: [HabitTemplate]] {
        var categories: [String: [HabitTemplate]] = [:]
        for template in templates {
            let category: String
            switch template.id {
            case "running", "walking", "strength":
                category = "Health & Fitness"
            case "reading", "learning":
                category = "Learning & Growth"
            case "meditation", "journaling":
                category = "Mindfulness"
            case "call_friend":
                category = "Social"
            default:
                category = "Other"
            }
            categories[category, default: []].append(template)
        }
        return categories
    }
}
