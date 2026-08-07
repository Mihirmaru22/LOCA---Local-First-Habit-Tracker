import Foundation

// MARK: - Per-kind payload value types
// Each payload type carries exactly the fields that kind requires.
// All types are Codable, Sendable, and Hashable.

// MARK: HabitLogPayload

struct HabitLogPayload: Codable, Sendable, Hashable {
    /// The stable ID of the habit definition being logged.
    let habitID: UUID
    /// Amount logged. 1.0 for binary habits; measured quantity otherwise.
    let value: Double
    /// Optional journal note attached to this check-in.
    let note: String?
}

// MARK: ReflectionPayload

struct ReflectionPayload: Codable, Sendable, Hashable {
    /// The person's written reflection text.
    let text: String
    /// The seed prompt shown to the person, if any.
    let promptText: String?
    /// The Record fact ID that seeded the prompt, if any.
    let seedFactID: UUID?
}

// MARK: StateCheckInPayload

/// A voluntary self-report of inner state. All dimensions are optional —
/// the person reports what feels relevant. At least one value must be present.
struct StateCheckInPayload: Codable, Sendable, Hashable {
    let mood: Int?     // 1–5 or nil
    let energy: Int?   // 1–5 or nil
    let focus: Int?    // 1–5 or nil
    let stress: Int?   // 1–5 or nil
    let note: String?
}

// MARK: CorrectionPayload

/// A correction of a prior fact. Corrections enter the Record as new facts
/// (highest authority). The prior fact is never mutated or removed.
struct CorrectionPayload: Codable, Sendable, Hashable {
    /// The ID of the Fact being corrected.
    let targetFactID: UUID
    /// The name of the field being corrected (e.g. "value", "mood", "text").
    let field: String
    /// The corrected value, JSON-encoded for type-safety across kinds.
    let correctedValue: String
    /// Why the correction was made (optional; helps future audit).
    let reason: String?
}

// MARK: DirectionPayload

/// A person's authored aim or intention. Directions are created and updated
/// as new facts; old versions remain in the Record.
struct DirectionPayload: Codable, Sendable, Hashable {
    /// Stable identity for this direction across updates.
    let directionID: UUID
    let title: String
    let description: String?
    let isArchived: Bool
}

// MARK: QuestionAskedPayload

/// Records that the person asked a question via the Ask surface.
struct QuestionAskedPayload: Codable, Sendable, Hashable {
    let text: String
    /// Optional hint about which surface the question originated from.
    let contextHint: String?
}

// MARK: PermissionChangedPayload

/// Records a change to an OS-level permission.
struct PermissionChangedPayload: Codable, Sendable, Hashable {
    /// Namespaced permission string (e.g. "healthKit.steps", "calendar").
    let permission: String
    let granted: Bool
}

// MARK: CalendarEventPayload

/// An event imported from the person's Calendar (consented).
struct CalendarEventPayload: Codable, Sendable, Hashable {
    /// Stable event identifier from the Calendar framework (used for dedup).
    let externalID: String
    let title: String
    let startDate: Date
    let endDate: Date?
    let isAllDay: Bool
    let calendarName: String?
}

// MARK: HealthSamplePayload

/// A health or fitness sample imported from Apple Health (consented).
struct HealthSamplePayload: Codable, Sendable, Hashable {
    /// HKQuantityType identifier string (e.g. "HKQuantityTypeIdentifierStepCount").
    let sampleType: String
    let value: Double
    let unit: String
    let startDate: Date
    let endDate: Date
}

// MARK: ConsentChangedPayload

/// Records that the person granted or revoked consent for a signal source.
struct ConsentChangedPayload: Codable, Sendable, Hashable {
    /// The FactSource.rawValue this consent applies to.
    let source: String
    let granted: Bool
}

// MARK: ConfirmationPayload

/// Records that the person confirmed a system-generated candidate
/// (e.g. confirmed a landmark or chapter suggestion).
struct ConfirmationPayload: Codable, Sendable, Hashable {
    /// The candidate fact being confirmed.
    let targetFactID: UUID
    /// What kind of thing was confirmed (e.g. "landmark", "chapter", "relationship").
    let confirmationType: String
}

// MARK: DeletionRequestedPayload

/// Records a deletion request from the person. The Record itself honors
/// the deletion request fact; the actual deletion policy follows Build1.
struct DeletionRequestedPayload: Codable, Sendable, Hashable {
    let targetFactID: UUID
    let reason: String?
    let scope: DeletionScope

    enum DeletionScope: String, Codable, Sendable {
        /// Remove only this specific fact.
        case singleFact
        /// Remove all facts of a given kind (e.g. all health imports).
        case allFactsOfKind
        /// Sovereignty export + complete history deletion.
        case fullHistory
    }
}

// MARK: - FactPayload (discriminated union)

/// All fact payloads in a single discriminated union.
/// The associated value carries the kind-specific data.
enum FactPayload: Codable, Sendable, Hashable {
    case habitLogged(HabitLogPayload)
    case reflectionWritten(ReflectionPayload)
    case stateCheckedIn(StateCheckInPayload)
    case correctionSubmitted(CorrectionPayload)
    case directionChanged(DirectionPayload)
    case questionAsked(QuestionAskedPayload)
    case permissionChanged(PermissionChangedPayload)
    case calendarEventImported(CalendarEventPayload)
    case healthSampleImported(HealthSamplePayload)
    case consentChanged(ConsentChangedPayload)
    case confirmationSubmitted(ConfirmationPayload)
    case deletionRequested(DeletionRequestedPayload)
}
