@file:UseSerializers(UuidSerializer::class)

package com.loca.signal

import com.loca.record.FactConfidence
import com.loca.record.FactKind
import com.loca.record.FactSource
import com.loca.record.UuidSerializer
import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable
import kotlinx.serialization.UseSerializers
import kotlin.uuid.Uuid

/**
 * Complete provenance chain for a Signal.
 *
 * Every Signal carries a SignalProvenance that answers:
 *  - Which Fact produced this Signal? → sourceFactID, sourceFactKind
 *  - When was the underlying Fact written? → factRecordedAt
 *  - When did the event occur? → factOccurredAt
 *  - Where did the Fact come from? → factSource
 *  - How confident are we in the Fact? → factConfidence
 *  - When did the Signal Engine process it? → transformedAt
 *  - Which pipeline version was used? → pipelineVersion
 */
@Serializable
data class SignalProvenance(
    /** The Record Fact that produced this Signal (signal.id == sourceFactID). */
    val sourceFactID: Uuid,
    /** The FactKind of the source Fact. */
    val sourceFactKind: FactKind,
    /** When the source Fact was written to the Record (Fact.recordedAt). */
    val factRecordedAt: Instant,
    /** When the underlying event occurred (Fact.occurredAt). */
    val factOccurredAt: Instant,
    /** The source declared by the Fact's FactProvenance. */
    val factSource: FactSource,
    /** The confidence declared by the Fact's FactProvenance. */
    val factConfidence: FactConfidence,
    /** When the Signal Engine transformed the Fact into this Signal. */
    val transformedAt: Instant,
    /**
     * The pipeline version used to produce this Signal.
     * Used to detect stale signals after a pipeline upgrade.
     */
    val pipelineVersion: Int
)
