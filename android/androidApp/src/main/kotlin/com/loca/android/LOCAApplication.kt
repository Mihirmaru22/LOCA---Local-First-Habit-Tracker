package com.loca.android

import android.app.Application
import com.loca.android.data.AppContainer

class LOCAApplication : Application() {
    lateinit var container: AppContainer

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
    }
}
