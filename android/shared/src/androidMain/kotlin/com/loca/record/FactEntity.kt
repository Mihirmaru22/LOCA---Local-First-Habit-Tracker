package com.loca.record

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "facts",
    indices = [Index(value = ["kind"])]
)
data class FactEntity(
    @PrimaryKey val id: String,
    val kind: String,
    val source: String,
    @ColumnInfo(name = "recorded_at") val recordedAt: Long,
    @ColumnInfo(name = "occurred_at") val occurredAt: Long,
    val json: String
)
