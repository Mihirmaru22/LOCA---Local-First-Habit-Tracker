package com.loca.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
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

    companion object {
        fun create(context: Context): LOCADatabase =
            Room.databaseBuilder(context, LOCADatabase::class.java, "loca.db").build()
    }
}
