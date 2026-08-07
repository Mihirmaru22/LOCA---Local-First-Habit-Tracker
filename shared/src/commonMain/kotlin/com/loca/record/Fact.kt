@file:UseSerializers(UuidSerializer::class)

package com.loca.record

import kotlinx.datetime.Instant
import kotlinx.serialization.Serializable
import kotlinx.serialization.UseSerializers
import kotlin.uuid.Uuid

/**
 * An immutable, append-only record of a single event.
 *
 * Facts are the single source of truth in LOCA.
 * Nothing is ever edited or deleted — corrections and deletions
 * are themselves new Facts (CORRECTION_SUBMITTED, DELETION_REQUESTED).
 *
 * Invariants:
 *  G1: Immutability — a stored Fact never changes.
 *  G2: Identity — Fact.id is globally unique, set at creation, never reused.
 *  G3: Ordering — recordedAt monotonically increases within a store session.
 *  G4: Replayability — allFacts() in insertion order reproduces all derived state.
 */
@Serializable
data class Fact(
    /** Unique identity. Signal.id equals this value for the derived Signal. */
    val id: Uuid,

    /** The kind of event this Fact records. */
    val kind: FactKind,

    /** Kind-specific structured payload. */
    val payload: FactPayload,

    /** Full audit trail — who recorded this, how, and with what confidence. */
    val provenance: FactProvenance,

    /** When this Fact was written to the Record (wall clock, set by RecordEngine). */
    val recordedAt: Instant,

    /** When the underlying event occurred (supplied by the caller). */
    val occurredAt: Instant
)
