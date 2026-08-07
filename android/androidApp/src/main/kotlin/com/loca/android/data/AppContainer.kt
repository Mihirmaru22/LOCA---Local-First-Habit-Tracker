package com.loca.android.data

import android.content.Context
import com.loca.android.health.HealthConnectManager
import com.loca.android.health.HealthImporter
import com.loca.db.LOCADatabase
import com.loca.record.Fact
import com.loca.record.FactDraft
import com.loca.record.RecordEngine
import com.loca.record.RoomRecordStore
import com.loca.signal.RoomSignalStore
import com.loca.signal.Signal
import com.loca.signal.SignalEngine
import com.loca.signal.SignalStoring
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class AppContainer(context: Context) {

    val database: LOCADatabase = LOCADatabase.create(context)

    private val recordStore = RoomRecordStore(database.factDao())
    val recordEngine = RecordEngine(recordStore)

    private val signalStoreRoom = RoomSignalStore(database.signalDao())
    val signalStore: SignalStoring = signalStoreRoom
    val signalEngine = SignalEngine(signalStoreRoom)

    val healthConnectManager = HealthConnectManager(context)
    val healthImporter = HealthImporter(healthConnectManager, recordEngine, signalEngine)

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val initJob: Job = scope.launch {
        recordEngine.initialize()
        signalEngine.initialize()
    }

    suspend fun awaitInit() = initJob.join()

    suspend fun importHealth() {
        awaitInit()
        healthImporter.importRecentData()
    }

    /**
     * Record a user-authored Fact and immediately derive its Signal.
     * The single write entry point for the UI — append to the Record,
     * then process into the Signal layer so derivers see it on next load.
     */
    suspend fun record(draft: FactDraft): Fact = withContext(Dispatchers.IO) {
        awaitInit()
        val fact = recordEngine.append(draft)
        signalEngine.process(fact)
        fact
    }

    /** Convenience read used by screens to reload after a write. */
    suspend fun signals(): List<Signal> = withContext(Dispatchers.IO) {
        awaitInit()
        signalStore.allSignals()
    }
}
