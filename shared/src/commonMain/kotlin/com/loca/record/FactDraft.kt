package com.loca.record

import kotlinx.datetime.Clock
import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable
import kotlin.uuid.Uuid

/**
 * A pending Fact that has not yet been validated or stored.
 * RecordEngine validates and converts a FactDraft into an immutable Fact.
 */
@Serializable
data class FactDraft(
    val id: Uuid = Uuid.random(),
    val kind: FactKind,
    val payload: FactPayload,
    val occurredAt: Instant = Clock.System.now(),
    val source: FactSource,
    val author: FactAuthor,
    val entryMethod: EntryMethod,
    val confidence: FactConfidence,
    val sourceIdentifier: String? = null,
    val externalTimestamp: Instant? = null
) {
    /**
     * Key used to detect semantic duplicates.
     * Two drafts with the same key refer to the same real-world event.
     */
    val deduplicationKey: String get() = id.toString()
}
