package com.loca.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.health.connect.client.PermissionController
import androidx.lifecycle.lifecycleScope
import com.loca.android.health.HealthConnectManager
import com.loca.android.ui.LOCAApp
import com.loca.android.ui.theme.LOCATheme
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : ComponentActivity() {

    private val requestPermissions = registerForActivityResult(
        PermissionController.createRequestPermissionResultContract()
    ) { granted ->
        if (granted.containsAll(HealthConnectManager.PERMISSIONS)) {
            lifecycleScope.launch(Dispatchers.IO) {
                (applicationContext as LOCAApplication).container.importHealth()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            LOCATheme {
                LOCAApp()
            }
        }
        triggerHealthImport()
    }

    private fun triggerHealthImport() {
        val container = (applicationContext as LOCAApplication).container
        val manager = container.healthConnectManager
        if (!manager.isAvailable()) return

        lifecycleScope.launch(Dispatchers.IO) {
            if (manager.hasPermissions()) {
                container.importHealth()
            } else {
                withContext(Dispatchers.Main) {
                    requestPermissions.launch(HealthConnectManager.PERMISSIONS)
                }
            }
        }
    }
}
