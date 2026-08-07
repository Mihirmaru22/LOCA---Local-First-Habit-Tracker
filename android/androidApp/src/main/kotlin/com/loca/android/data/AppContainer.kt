package com.loca.android.data

import android.content.Context
import com.loca.db.LOCADatabase
import com.loca.signal.RoomSignalStore
import com.loca.signal.SignalStoring

class AppContainer(context: Context) {
    val database: LOCADatabase = LOCADatabase.create(context)
    val signalStore: SignalStoring = RoomSignalStore(database.signalDao())
}
