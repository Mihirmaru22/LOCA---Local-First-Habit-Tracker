import Foundation

// MARK: - Per-kind Signal payload types

/// Signal payloads carry the same fields as their source Fact payloads,
/// validated and structured for Signal layer consumers.
///
/// No inference is applied — values are passed through from the Fact.
/// Normalization is structural (typed, layer-specific), not interpretive.

struct HabitCompletionSignal: Codable, Sendable, Hashable {
    let habitID: UUID
    let value: Double
    let note: String?
}

struct ReflectionSignal: Codable, Sendable, Hashable {
    let text: String
    let promptText: String?
    let seedFactID: UUID?
}

struct StateCheckInSignal: Codable, Sendable, Hashable {
    let mood: Int?
    let energy: Int?
    let focus: Int?
    let stress: Int?
    let note: String?
}

struct CorrectionSignal: Codable, Sendable, Hashable {
    let targetFactID: UUID
    let field: String
    let correctedValue: String
    let reason: String?
}

struct DirectionSignal: Codable, Sendable, Hashable {
    let directionID: UUID
    let title: String
    let directionDescription: String?
    let isArchived: Bool
}

struct QuestionSignal: Codable, Sendable, Hashable {
    let text: String
    let contextHint: String?
}

struct PermissionSignal: Codable, Sendable, Hashable {
    let permission: String
    let granted: Bool
}

struct CalendarEventSignal: Codable, Sendable, Hashable {
    let externalID: String
    let title: String
    let startDate: Date
    let endDate: Date?
    let isAllDay: Bool
    let calendarName: String?
}

struct HealthSampleSignal: Codable, Sendable, Hashable {
    let sampleType: String
    let value: Double
    let unit: String
    let startDate: Date
    let endDate: Date
}

struct ConsentSignal: Codable, Sendable, Hashable {
    let source: String
    let granted: Bool
}

struct ConfirmationSignal: Codable, Sendable, Hashable {
    let targetFactID: UUID
    let confirmationType: String
}

struct DeletionSignal: Codable, Sendable, Hashable {
    let targetFactID: UUID
    let reason: String?
    let scope: DeletionRequestedPayload.DeletionScope
}

// MARK: - SignalPayload (discriminated union)

/// All signal payloads in a single discriminated union.
enum SignalPayload: Codable, Sendable, Hashable {
    case habitCompletion(HabitCompletionSignal)
    case reflection(ReflectionSignal)
    case stateCheckIn(StateCheckInSignal)
    case correction(CorrectionSignal)
    case direction(DirectionSignal)
    case question(QuestionSignal)
    case permission(PermissionSignal)
    case calendarEvent(CalendarEventSignal)
    case healthSample(HealthSampleSignal)
    case consent(ConsentSignal)
    case confirmation(ConfirmationSignal)
    case deletionRequested(DeletionSignal)
}
