package com.loca.record

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface FactDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(entity: FactEntity)

    @Query("SELECT * FROM facts ORDER BY recorded_at ASC")
    suspend fun getAll(): List<FactEntity>

    @Query("SELECT id FROM facts")
    suspend fun getAllIds(): List<String>
}
