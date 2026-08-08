package com.loca.signal

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "signals",
    indices = [
        Index(value = ["kind"]),
        Index(value = ["source_fact_id"]),
        Index(value = ["produced_at"]),
    ]
)
data class SignalEntity(
    @PrimaryKey val id: String,
    val kind: String,
    @ColumnInfo(name = "source_fact_id") val sourceFactId: String,
    @ColumnInfo(name = "occurred_at") val occurredAt: Long,
    @ColumnInfo(name = "produced_at") val producedAt: Long,
    val json: String
)
