package com.loca.signal

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface SignalDao {
    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(entity: SignalEntity)

    @Query("SELECT * FROM signals ORDER BY produced_at ASC")
    suspend fun getAll(): List<SignalEntity>

    @Query("SELECT * FROM signals WHERE source_fact_id = :factId LIMIT 1")
    suspend fun getByFactId(factId: String): SignalEntity?

    @Query("SELECT source_fact_id FROM signals")
    suspend fun getAllFactIds(): List<String>

    @Query("DELETE FROM signals")
    suspend fun deleteAll()

    @Query("SELECT COUNT(*) FROM signals")
    suspend fun count(): Int
}
