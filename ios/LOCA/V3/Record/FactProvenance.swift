import Foundation

// MARK: - FactSource

/// Where the fact originated. Every fact must name its source.
/// Nothing anonymous enters the Record.
enum FactSource: String, Codable, Sendable, Hashable, CaseIterable {
    case userEntry       // Person typed or tapped explicitly.
    case healthKit       // Apple Health (requires explicit consent).
    case calendar        // Calendar import (requires explicit consent).
    case motion          // CoreMotion (requires explicit consent).
    case location        // CoreLocation (requires explicit consent).
    case deviceActivity  // Screen Time / DeviceActivity (requires explicit consent).
    case systemClock     // Time boundary events (day/week rollover) — no consent needed.
    case correction      // A correction of a prior user-authored fact (highest authority).
}

// MARK: - FactAuthor

/// Who or what created the fact.
enum FactAuthor: String, Codable, Sendable {
    case person  // The human user acting deliberately.
    case system  // The app acting on a time/lifecycle event.
    case sensor  // A hardware sensor or OS framework (consented).
}

// MARK: - EntryMethod

/// How the fact entered the system.
enum EntryMethod: String, Codable, Sendable {
    case explicit   // User deliberately created this entry (typed, tapped).
    case imported   // Pulled from an external consented source.
    case automatic  // System-generated (clock boundary, auto-scheduled import).
}

// MARK: - FactConfidence

/// Confidence in the fact's value. This describes source reliability,
/// not inferred probability. Derivation may further adjust confidence,
/// but the Record stores source confidence only.
enum FactConfidence: String, Codable, Sendable, Comparable {
    case known   // User-entered: the person said so. Highest authority.
    case high    // Reliable sensor or well-validated import.
    case medium  // Sensor with some measurement uncertainty.
    case low     // Unreliable sensor or low-quality import.

    private var rank: Int {
        switch self {
        case .known:  return 3
        case .high:   return 2
        case .medium: return 1
        case .low:    return 0
        }
    }

    static func < (lhs: FactConfidence, rhs: FactConfidence) -> Bool {
        lhs.rank < rhs.rank
    }
}

// MARK: - FactProvenance

/// Complete source attribution for a Fact. Every Fact in the Record
/// carries a FactProvenance; no Fact is anonymous.
///
/// Answers Build3's six provenance questions:
///  - where did this come from? → source
///  - when (externally)? → externalTimestamp
///  - who created it? → author
///  - how confident are we? → confidence
///  - how did it enter? → entryMethod
///  - which specific source? → sourceIdentifier
struct FactProvenance: Codable, Sendable, Hashable {

    /// The originating system.
    let source: FactSource

    /// Who (or what) authored this fact.
    let author: FactAuthor

    /// How this fact entered the system.
    let entryMethod: EntryMethod

    /// Confidence in this fact's accuracy.
    let confidence: FactConfidence

    /// For sensor/import sources: the specific source identifier
    /// (e.g. an HKQuantityType identifier, a calendar bundle ID).
    /// Nil for user-entered and system-clock facts.
    let sourceIdentifier: String?

    /// For imported/sensor facts: when the source system records the event.
    /// May predate the Record's `recordedAt` timestamp (e.g. a health sample
    /// from hours ago imported in a background refresh).
    let externalTimestamp: Date?
}
