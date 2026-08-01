import Foundation

// MARK: - RecordWriting protocol

/// The public write interface for the Record layer.
/// All user actions and sensor imports that produce facts enter through this gate.
protocol RecordWriting: Sendable {
    /// Validate, provenance-tag, timestamp, and append a FactDraft to the Record.
    /// Returns the written Fact on success.
    /// Throws RecordError if validation fails or the store cannot be written.
    func write(_ draft: FactDraft) async throws -> Fact
}

// MARK: - RecordWriter

/// The canonical write gate.
///
/// Pipeline (from Build1 §V, stages 2–4):
///   FactDraft (caller intent)
///     ↓  validate — reject malformed drafts with a specific reason
///     ↓  build provenance — assemble FactProvenance from draft fields
///     ↓  build Fact — attach recordedAt timestamp (wall clock at write time)
///     ↓  RecordEngine.append — single-writer serialized store write
///     → Fact (immutable, in the Record)
///
/// Nothing that enters the Record bypasses this pipeline.
/// No silent repairs: invalid drafts are rejected, not quietly fixed.
struct RecordWriter: RecordWriting {

    private let engine: RecordEngine
    private let validator: any FactValidating

    init(engine: RecordEngine, validator: any FactValidating = DefaultFactValidator()) {
        self.engine = engine
        self.validator = validator
    }

    // MARK: - Write

    func write(_ draft: FactDraft) async throws -> Fact {
        // Stage 1: Validate — reject before touching the Record
        let validatedDraft: FactDraft
        switch validator.validate(draft) {
        case .success(let d):
            validatedDraft = d
        case .failure(let error):
            throw RecordError.invalidFact(error)
        }

        // Stage 2: Build provenance — fully populated, nothing anonymous
        let provenance = FactProvenance(
            source: validatedDraft.source,
            author: validatedDraft.author,
            entryMethod: validatedDraft.entryMethod,
            confidence: validatedDraft.confidence,
            sourceIdentifier: validatedDraft.sourceIdentifier,
            externalTimestamp: validatedDraft.externalTimestamp
        )

        // Stage 3: Build the immutable Fact
        // recordedAt is set here — the moment it enters the Record — not by the caller.
        let fact = Fact(
            id: validatedDraft.id,
            kind: validatedDraft.kind,
            payload: validatedDraft.payload,
            provenance: provenance,
            recordedAt: Date(),
            occurredAt: validatedDraft.occurredAt
        )

        // Stage 4: Append via RecordEngine (serialized single-writer)
        // The deduplication key is computed from the validated draft.
        try await engine.append(fact, dedupKey: validatedDraft.deduplicationKey)

        return fact
    }
}
