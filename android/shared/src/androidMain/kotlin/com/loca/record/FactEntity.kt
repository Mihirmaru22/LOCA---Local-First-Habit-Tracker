package com.loca.record

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "facts")
data class FactEntity(
    @PrimaryKey val id: String,
    val kind: String,
    val source: String,
    val recordedAt: Long,
    val occurredAt: Long,
    val json: String
)
