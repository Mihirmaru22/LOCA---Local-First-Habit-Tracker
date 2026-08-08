package com.loca.android.ui.habits

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.loca.derive.habits.HabitDeriver
import com.loca.derive.habits.HabitSummary
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

class HabitsViewModel(repository: SignalRepository) : ViewModel() {

    val habits: StateFlow<List<HabitSummary>?> = repository.signals
        .map { signals ->
            val today = Clock.System.todayIn(TimeZone.currentSystemDefault())
            HabitDeriver.deriveAll(signals, today)
        }
        .flowOn(Dispatchers.Default)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    companion object {
        fun factory(repository: SignalRepository): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    HabitsViewModel(repository) as T
            }
    }
}
