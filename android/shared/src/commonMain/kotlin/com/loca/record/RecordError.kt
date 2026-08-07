package com.loca.record

import kotlin.uuid.Uuid

sealed class RecordError(message: String, cause: Throwable? = null) : Exception(message, cause) {
    /** A Fact with this ID was already stored — processing the same draft twice. */
    class DuplicateFact(val id: Uuid) : RecordError("Duplicate fact: $id")

    /** The underlying store failed to persist the fact (see [cause]). */
    class StorageFailure(cause: Throwable) : RecordError("Storage failure: ${cause.message}", cause)

    /** The draft failed validation before reaching the store. */
    class ValidationFailure(val reason: String) : RecordError("Validation failure: $reason")
}
