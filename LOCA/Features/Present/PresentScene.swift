//
//  PresentScene.swift
//  LOCA
//
//  Phase 8, Session 8.1 — Value types for a composed Present scene.
//
//  A PresentScene is what the composer produces: not data, not a chart,
//  but a shaped observation the user reads and concludes from. It carries
//  exactly enough for one moment of looking — and one optional thread to
//  pull if something catches them.
//

import Foundation

// MARK: - Time of Day

enum TimeOfDay: CaseIterable {
    case morning    // 05:00–12:00  leans forward
    case afternoon  // 12:00–17:00  neutral
    case evening    // 17:00–21:00  leans back
    case night      // 21:00–05:00  gentle, low-demand

    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default:      return .night
        }
    }

    var label: String {
        switch self {
        case .morning:   return "morning"
        case .afternoon: return "afternoon"
        case .evening:   return "evening"
        case .night:     return "night"
        }
    }
}

// MARK: - Soft Thread

/// One thread worth pulling, if the user wants to. The current view is the
/// only menu — a soft thread is an invitation, never a feed item, and there
/// is never more than one at a time.
struct SoftThread: Equatable {
    let label: String         // The observation that invites a pull.
    let prefilledQuestion: String  // The question it seeds in Ask.
}

// MARK: - State Signal

/// A single dimension's relationship to baseline — the raw material the
/// composer turns into natural language.
struct StateSignal {
    enum Dimension: String {
        case energy, stress, focus, mood
        var label: String { rawValue.capitalized }
    }

    let dimension: Dimension
    let delta: Double       // current − baseline (positive = above, negative = below)
    let confidence: Double  // how much data supports this
    let trending: Bool      // is the delta growing in recent days?
}

// MARK: - Reach Slice

/// Content shown at a given depth in the Reach gesture.
struct ReachSlice {
    enum Depth {
        case present            // 0.0–0.25  moments, grainy
        case recentDays         // 0.25–0.55 week texture
        case chapter            // 0.55–0.80 chapter shape
        case fullLife           // 0.80–1.00 all chapters, landmarks
    }

    let depth: Depth
    let headline: String
    let body: String?
    let landmarks: [LifeLandmark]
}

struct LifeLandmark: Identifiable {
    let id: UUID
    let label: String       // e.g. "The Internship"
    let position: Double    // 0–1 (0 = now, 1 = oldest)
    let isEvent: Bool       // true = LifeEvent, false = Chapter boundary
}

// MARK: - Present Scene

/// The composed scene the user arrives at. Produced fresh on each load;
/// never stored. If the life model has no data, `isEmpty` is true and the
/// view renders the honest empty state.
struct PresentScene {
    let timeContext: String       // e.g. "Tuesday evening"
    let chapterName: String?      // e.g. "The Internship"
    let directionStatement: String? // e.g. "Growing into the internship"
    let headline: String          // The primary observation in plain English.
    let support: String?          // A second observation (or nil if one is enough).
    let softThread: SoftThread?   // At most one thread. Often nil.
    let signals: [StateSignal]    // Raw signals (for the Reach to use).
    let generatedAt: Date
    let timeOfDay: TimeOfDay

    var isEmpty: Bool { headline.isEmpty }

    static let empty = PresentScene(
        timeContext: "",
        chapterName: nil,
        directionStatement: nil,
        headline: "",
        support: nil,
        softThread: nil,
        signals: [],
        generatedAt: Date(),
        timeOfDay: .current
    )
}
