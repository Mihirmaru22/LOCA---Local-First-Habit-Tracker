package com.loca.android.ui

import androidx.compose.material3.SnackbarHostState
import androidx.compose.runtime.staticCompositionLocalOf

/**
 * App-wide Snackbar host, provided at the LOCAApp scaffold and read by screens
 * so any write can report failure without threading state through navigation.
 */
val LocalSnackbar = staticCompositionLocalOf<SnackbarHostState> {
    error("No SnackbarHostState provided — wrap content in LOCAApp's provider")
}

/**
 * Run a write that may throw, reporting failure to the user instead of crashing.
 *
 * UI writes go through RecordEngine/SignalEngine, which can throw on storage or
 * validation failure. An uncaught throw in a composition coroutine takes down
 * the app; this contains it and surfaces a message.
 *
 * @return true if [block] completed without throwing.
 */
suspend fun SnackbarHostState.runWrite(
    failureMessage: String,
    block: suspend () -> Unit,
): Boolean = try {
    block()
    true
} catch (e: Exception) {
    showSnackbar(failureMessage)
    false
}
