package com.loca.android.ui.journal

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.loca.derive.journal.JournalDeriver
import com.loca.derive.journal.JournalSummary
import com.loca.signal.SignalRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.todayIn

class JournalViewModel(repository: SignalRepository) : ViewModel() {

    val journal: StateFlow<JournalSummary?> = repository.signals
        .map { signals ->
            val tz = TimeZone.currentSystemDefault()
            val today = Clock.System.todayIn(tz)
            val now = Clock.System.now()
            JournalDeriver.deriveAll(signals, today, now, tz)
        }
        .flowOn(Dispatchers.Default)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    companion object {
        fun factory(repository: SignalRepository): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    JournalViewModel(repository) as T
            }
    }
}
