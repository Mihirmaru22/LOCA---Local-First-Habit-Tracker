package com.loca.record

import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlin.uuid.Uuid

/**
 * Serializes [Uuid] as its canonical string form.
 *
 * Kotlin 2.0.21's serialization plugin does not yet ship a built-in serializer
 * for `kotlin.uuid.Uuid`, so every `@Serializable` type carrying a Uuid must
 * route through this serializer (applied file-wide via `@file:UseSerializers`).
 */
object UuidSerializer : KSerializer<Uuid> {
    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("com.loca.Uuid", PrimitiveKind.STRING)

    override fun serialize(encoder: Encoder, value: Uuid) =
        encoder.encodeString(value.toString())

    override fun deserialize(decoder: Decoder): Uuid =
        Uuid.parse(decoder.decodeString())
}
