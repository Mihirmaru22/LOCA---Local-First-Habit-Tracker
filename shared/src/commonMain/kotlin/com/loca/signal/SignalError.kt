package com.loca.signal

import com.loca.record.FactKind
import kotlin.uuid.Uuid

/** Errors that can occur in the Signal layer. */
sealed class SignalError(message: String) : Exception(message) {
    /** A Fact could not be transformed by the pipeline. */
    class PipelineFailure(val cause: SignalPipelineError) :
        SignalError("Pipeline failure: ${cause.message}")

    /** The underlying signal store failed. */
    class StorageFailure(val underlying: Throwable) :
        SignalError("Storage failure: ${underlying.message}")

    /** A replay operation failed. */
    class ReplayFailure(val reason: String) :
        SignalError("Replay failure: $reason")
}

/** Specific errors from the pipeline transformation step. */
sealed class SignalPipelineError(message: String) : Exception(message) {
    /** The Fact's payload kind does not match its declared FactKind. */
    class PayloadKindMismatch(val factID: Uuid, val factKind: FactKind) :
        SignalPipelineError("Payload does not match kind $factKind for fact $factID")

    /** A required payload field is missing or structurally invalid. */
    class MalformedPayload(val factID: Uuid, val reason: String) :
        SignalPipelineError("Malformed payload for fact $factID: $reason")
}
