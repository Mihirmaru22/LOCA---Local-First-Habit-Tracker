import Foundation

// MARK: - SignalKind

/// The kind of a Signal. Mirrors FactKind: one SignalKind for every FactKind.
/// The Signal Engine produces exactly one SignalKind for each FactKind.
enum SignalKind: String, Codable, Sendable, Hashable, CaseIterable {
    case habitCompletion      // ← habitLogged
    case reflection           // ← reflectionWritten
    case stateCheckIn         // ← stateCheckedIn
    case correction           // ← correctionSubmitted
    case direction            // ← directionChanged
    case question             // ← questionAsked
    case permission           // ← permissionChanged
    case calendarEvent        // ← calendarEventImported
    case healthSample         // ← healthSampleImported
    case consent              // ← consentChanged
    case confirmation         // ← confirmationSubmitted
    case deletionRequested    // ← deletionRequested
}

extension FactKind {
    /// The SignalKind produced from this FactKind.
    /// Every FactKind maps to exactly one SignalKind.
    var signalKind: SignalKind {
        switch self {
        case .habitLogged:            return .habitCompletion
        case .reflectionWritten:      return .reflection
        case .stateCheckedIn:         return .stateCheckIn
        case .correctionSubmitted:    return .correction
        case .directionChanged:       return .direction
        case .questionAsked:          return .question
        case .permissionChanged:      return .permission
        case .calendarEventImported:  return .calendarEvent
        case .healthSampleImported:   return .healthSample
        case .consentChanged:         return .consent
        case .confirmationSubmitted:  return .confirmation
        case .deletionRequested:      return .deletionRequested
        }
    }
}

// MARK: - Signal

/// A normalized, provenance-bearing signal produced from an immutable Fact.
///
/// Design invariants:
///  S1: One Signal per Fact. `signal.id == sourceFactID` makes this auditable.
///  S2: Determinism. Same Fact → same id, kind, payload, occurredAt.
///  S3: Replay. Clearing all signals and reprocessing the same Facts reproduces
///      the same set. Possible because Signal.id equals Fact.id.
///  S4: Provenance completeness. Every Signal carries a SignalProvenance.
///  S5: Read-only from Record. The Signal Engine never writes to the Record.
struct Signal: Sendable, Hashable, Identifiable, Codable {

    /// Equal to the source Fact's id.
    /// Makes the 1:1 relationship explicit and enables deterministic replay.
    let id: UUID

    /// The kind of this signal, derived from the source Fact's kind.
    let kind: SignalKind

    /// Kind-specific normalized payload.
    let payload: SignalPayload

    /// Full provenance chain: which Fact, when, which source, which pipeline.
    let provenance: SignalProvenance

    /// When the underlying event occurred (copied from Fact.occurredAt).
    let occurredAt: Date

    /// When this Signal was produced by the Signal Engine.
    let producedAt: Date
}
