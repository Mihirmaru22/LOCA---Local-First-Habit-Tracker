package com.loca.record

import kotlin.uuid.Uuid

sealed class RecordError(message: String) : Exception(message) {
    /** A Fact with this ID was already stored — processing the same draft twice. */
    class DuplicateFact(val id: Uuid) : RecordError("Duplicate fact: $id")

    /** The underlying store failed to persist the fact. */
    class StorageFailure(val cause: Throwable) : RecordError("Storage failure: ${cause.message}")

    /** The draft failed validation before reaching the store. */
    class ValidationFailure(val reason: String) : RecordError("Validation failure: $reason")
}
