package com.loca.db

import androidx.room.Database
import androidx.room.RoomDatabase
import com.loca.record.FactDao
import com.loca.record.FactEntity
import com.loca.signal.SignalDao
import com.loca.signal.SignalEntity

@Database(
    entities = [FactEntity::class, SignalEntity::class],
    version = 1,
    exportSchema = true
)
abstract class LOCADatabase : RoomDatabase() {
    abstract fun factDao(): FactDao
    abstract fun signalDao(): SignalDao
}
