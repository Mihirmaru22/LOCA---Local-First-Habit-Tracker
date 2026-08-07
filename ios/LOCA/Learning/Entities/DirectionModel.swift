//
//  DirectionModel.swift
//  LOCA
//
//  Phase 7 — Direction: the first-person layer.
//
//  Direction is what the old model lacked: the self's aim. Without it the
//  manifesto says we describe "a marionette, not the hand." Direction is
//  *not* a goal tracker, a checklist, or a journal. It is the felt
//  toward-what — captured once, held lightly, linked to the trajectory.
//
//  A Fork is an agency moment: a decision, an inflection, or a live
//  question where the trajectory bends. Forks do not ask the user to
//  report; they are offered as a gift at natural moments and are always
//  skippable.
//

import Foundation
import SwiftData

// MARK: - Fork Kind

enum ForkKind: String, Codable, CaseIterable {
    case decision   // "I decided to take the offer"
    case inflection // "Things shifted"
    case question   // "Should I..."

    var label: String {
        switch self {
        case .decision:   return "Decision"
        case .inflection: return "Inflection"
        case .question:   return "Open Question"
        }
    }

    var icon: String {
        switch self {
        case .decision:   return "checkmark.circle"
        case .inflection: return "arrow.triangle.turn.up.right.circle"
        case .question:   return "questionmark.circle"
        }
    }
}

// MARK: - Direction (Persistent)

/// The felt toward-what. One active Direction at a time; past Directions are
/// kept for the trajectory. Captured as a gift, never as a survey.
///
/// CloudKit safety: all optional properties nullable; arrays default to [].
@Model
final class Direction {
    var id: UUID = UUID()

    // The one-phrase toward-what, in the user's own words.
    var statement: String

    // Values: short phrases the user names. Ordered by salience.
    var values: [String]

    // Intentions: what they are actively moving toward.
    var intentions: [String]

    // How settled this direction feels (the user's own sense, 0–1).
    // 0 = "I'm figuring it out", 1 = "I know exactly where I'm going."
    var settledness: Double
    var settlednessUncertainty: Double

    // Links to temporal context.
    var chapterId: UUID?     // Chapter in which this Direction was articulated (nil = pre-chapter)
    var isActive: Bool       // Only one Direction should be active at a time.

    var capturedAt: Date
    var updatedAt: Date

    init(
        statement: String,
        values: [String] = [],
        intentions: [String] = [],
        settledness: Double = 0.5,
        chapterId: UUID? = nil
    ) {
        self.statement = statement
        self.values = values
        self.intentions = intentions
        self.settledness = max(0, min(1, settledness))
        self.settlednessUncertainty = 0.3
        self.chapterId = chapterId
        self.isActive = true
        self.capturedAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Fork (Persistent)

/// An agency moment: a decision, a shift, or a live question where the
/// trajectory bends. Forks are tagged Moments — they carry their own
/// timestamp and link to the Direction they belong to.
///
/// A Fork is *never* a prompt for the user to fill in a form. It is
/// offered at natural moments (a chapter boundary, a direction update)
/// and is always skippable.
@Model
final class Fork {
    var id: UUID = UUID()

    var timestamp: Date
    var kind: ForkKind
    var statement: String        // In the user's own words — unedited.

    // Context links.
    var directionId: UUID?       // Direction this Fork belongs to.
    var chapterId: UUID?         // Chapter in which this Fork happened.

    // Resolution: did they make the call?
    var resolved: Bool
    var resolution: String?      // What happened, if they chose to note it.

    var createdAt: Date

    init(
        statement: String,
        kind: ForkKind = .question,
        directionId: UUID? = nil,
        chapterId: UUID? = nil
    ) {
        self.timestamp = Date()
        self.kind = kind
        self.statement = statement
        self.directionId = directionId
        self.chapterId = chapterId
        self.resolved = false
        self.resolution = nil
        self.createdAt = Date()
    }
}
