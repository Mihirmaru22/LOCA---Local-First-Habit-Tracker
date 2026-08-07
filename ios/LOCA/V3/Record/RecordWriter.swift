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

/// The public write surface for callers above the Record layer.
///
/// RecordWriter is a thin pass-through to RecordEngine. The full write
/// pipeline (validate → build provenance → build Fact → append) lives inside
/// RecordEngine.append, which enforces validation on every write regardless
/// of the call site.
///
/// Callers above the Record layer use RecordWriter (not RecordEngine directly)
/// so that the engine remains an implementation detail.
struct RecordWriter: RecordWriting {

    private let engine: RecordEngine

    init(engine: RecordEngine) {
        self.engine = engine
    }

    // MARK: - Write

    func write(_ draft: FactDraft) async throws -> Fact {
        try await engine.append(draft)
    }
}
