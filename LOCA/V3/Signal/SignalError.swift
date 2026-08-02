import Foundation

/// Errors that can occur in the Signal layer.
enum SignalError: Error, Sendable {
    /// A Fact could not be transformed by the pipeline.
    case pipelineFailure(SignalPipelineError)

    /// The underlying signal store failed.
    case storageFailure(underlying: any Error)

    /// A replay operation failed.
    case replayFailure(message: String)
}

/// Specific errors from the pipeline transformation step.
enum SignalPipelineError: Error, Sendable {
    /// The Fact's payload kind does not match its declared FactKind.
    case payloadKindMismatch(factID: UUID, factKind: FactKind)

    /// A required payload field is missing or structurally invalid.
    case malformedPayload(factID: UUID, reason: String)
}
