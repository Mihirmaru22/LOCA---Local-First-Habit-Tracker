//
//  PersonModel.swift
//  LOCA
//
//  Phase 5 — Person and Relationship entities
//  People are inferred from recurring names in calendar, notes, and signals.
//  Relationships are slow-changing; each has a salience score updated weekly.
//

import Foundation
import SwiftData

// MARK: - Relationship Type

enum RelationshipContext: String, Codable, CaseIterable {
    case work       // Appears in work-hour calendar events
    case social     // Appears in social / leisure events
    case family     // Explicitly tagged or detected from recurring personal events
    case recurring  // Appears weekly but context is ambiguous
    case unknown
}

// MARK: - Person (Persistent)

@Model
final class Person {
    var id: UUID = UUID()

    // Identity
    var name: String                    // Normalized display name
    var nameVariants: [String]          // Raw strings that resolved to this person
    var initials: String                // Derived from name for avatar

    // Salience signal (0–1): how much this person appears in the user's life
    var salience: Double                // Rolling 30-day presence score
    var salienceUncertainty: Double     // Confidence in the salience estimate

    // Context
    var primaryContext: RelationshipContext
    var detectedContexts: [String]      // All raw context strings observed

    // Temporal tracking
    var firstSeenDate: Date
    var lastSeenDate: Date
    var appearanceCount: Int            // Total appearances in signals

    // C2.4: moodCorrelation is raw observed co-occurrence evidence only — not a verdict
    // about relationship meaning ("uplifting", "stressful"). Never surfaced as a label.
    var moodCorrelation: Double?
    var moodCorrelationSampleCount: Int

    // Chapter context
    var chapterId: UUID?                // nil = appears across chapters

    // Metadata
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // C2.3: primaryContext is subject-authoritative. It is not a parameter here so callers
    // cannot accidentally populate it from sensor inference. Set it only after a user act.
    init(
        name: String,
        nameVariants: [String] = []
    ) {
        self.name = name
        self.nameVariants = nameVariants
        self.initials = Person.makeInitials(from: name)
        self.salience = 0.0
        self.salienceUncertainty = 0.8
        self.primaryContext = .unknown
        self.detectedContexts = []
        self.firstSeenDate = Date()
        self.lastSeenDate = Date()
        self.appearanceCount = 1
        self.moodCorrelation = nil
        self.moodCorrelationSampleCount = 0
    }

    static func makeInitials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map { String($0) } }
        return letters.joined().uppercased()
    }
}

// MARK: - Appearance (Persistent)
// One record per signal event that mentions a person

@Model
final class PersonAppearance {
    var id: UUID = UUID()
    var personId: UUID
    var timestamp: Date
    var source: String                  // "calendar", "note", "explicitLog"
    var context: RelationshipContext
    var rawText: String?                // Snippet of source text (calendar title, etc.)

    // State at the time of this appearance (for mood correlation)
    var moodAtTime: Double?
    var stressAtTime: Double?

    init(
        personId: UUID,
        timestamp: Date,
        source: String,
        context: RelationshipContext = .unknown,
        rawText: String? = nil
    ) {
        self.personId = personId
        self.timestamp = timestamp
        self.source = source
        self.context = context
        self.rawText = rawText
    }
}
