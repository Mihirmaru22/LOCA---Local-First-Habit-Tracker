//
//  ReflectionUnit.swift
//  LOCA
//
//  Phase 4.1 — The single reflection unit.
//
//  One honest sentence tied to progress — never a destination.
//  Delivered as push, no review screen. Seasonal, grounded, rare.
//

import Foundation

/// A single reflection: one sentence, grounded in real progress data.
/// Delivered as a push notification. No UI; no review screen.
struct ReflectionUnit: Identifiable, Codable {
    let id: UUID
    /// The reflection text: one sentence, seasonal, tied to progress.
    let text: String
    /// When this reflection was generated.
    let generatedAt: Date
    /// The type of reflection (morning, evening, milestone, streak, etc.)
    let contextType: ContextType
    /// Whether the user has seen/acted on this reflection (4.4: measurement).
    var wasEngaged: Bool = false

    enum ContextType: String, Codable {
        case morning      // Morning check-in context
        case evening      // Evening reflection context
        case streak       // Milestone: current streak reached X days
        case consistency  // Weekly consistency observation
        case recovery     // Returning after a lapse
        case pattern      // Data-backed correlation insight
    }

    init(
        text: String,
        contextType: ContextType,
        generatedAt: Date = Date()
    ) {
        self.id = UUID()
        self.text = text
        self.contextType = contextType
        self.generatedAt = generatedAt
    }
}
