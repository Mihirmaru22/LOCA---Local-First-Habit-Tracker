import Foundation

/// Complete provenance chain for a Signal.
///
/// Every Signal carries a SignalProvenance that answers:
///  - Which Fact produced this Signal? → sourceFactID, sourceFactKind
///  - When was the underlying Fact written? → factRecordedAt
///  - When did the event occur? → factOccurredAt
///  - Where did the Fact come from? → factSource
///  - How confident are we in the Fact? → factConfidence
///  - When did the Signal Engine process it? → transformedAt
///  - Which pipeline version was used? → pipelineVersion
struct SignalProvenance: Codable, Sendable, Hashable {

    /// The Record Fact that produced this Signal (signal.id == sourceFactID).
    let sourceFactID: UUID

    /// The FactKind of the source Fact.
    let sourceFactKind: FactKind

    /// When the source Fact was written to the Record (Fact.recordedAt).
    let factRecordedAt: Date

    /// When the underlying event occurred (Fact.occurredAt).
    let factOccurredAt: Date

    /// The source declared by the Fact's FactProvenance.
    let factSource: FactSource

    /// The confidence declared by the Fact's FactProvenance.
    let factConfidence: FactConfidence

    /// When the Signal Engine transformed the Fact into this Signal.
    let transformedAt: Date

    /// The pipeline version used to produce this Signal.
    /// Used to detect stale signals after a pipeline upgrade.
    let pipelineVersion: Int
}
