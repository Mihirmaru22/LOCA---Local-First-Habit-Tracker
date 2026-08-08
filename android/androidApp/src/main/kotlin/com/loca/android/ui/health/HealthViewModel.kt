package com.loca.android.ui.health

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.loca.android.health.HealthConnectManager
import com.loca.derive.health.HealthDeriver
import com.loca.derive.health.HealthOverview
import com.loca.signal.SignalRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

sealed class HealthUiState {
    object Loading : HealthUiState()
    object NotAvailable : HealthUiState()
    object NeedsPermission : HealthUiState()
    object NoData : HealthUiState()
    data class Ready(val overview: HealthOverview) : HealthUiState()
}

class HealthViewModel(
    private val signalRepository: SignalRepository,
    private val healthConnectManager: HealthConnectManager,
) : ViewModel() {

    private val _uiState = MutableStateFlow<HealthUiState>(HealthUiState.Loading)
    val uiState: StateFlow<HealthUiState> = _uiState.asStateFlow()

    private var collectionJob: Job? = null

    init {
        if (!healthConnectManager.isAvailable()) {
            _uiState.value = HealthUiState.NotAvailable
        } else {
            viewModelScope.launch {
                val hasPerms = withContext(Dispatchers.IO) {
                    healthConnectManager.hasPermissions()
                }
                if (hasPerms) startCollecting()
                else _uiState.value = HealthUiState.NeedsPermission
            }
        }
    }

    fun onPermissionGranted() {
        startCollecting()
    }

    private fun startCollecting() {
        collectionJob?.cancel()
        collectionJob = viewModelScope.launch {
            signalRepository.signals
                .map { signals ->
                    val overview = HealthDeriver.deriveOverview(signals)
                    if (overview.days.isEmpty()) HealthUiState.NoData
                    else HealthUiState.Ready(overview)
                }
                .flowOn(Dispatchers.Default)
                .collect { _uiState.value = it }
        }
    }

    companion object {
        fun factory(
            repository: SignalRepository,
            healthConnectManager: HealthConnectManager,
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T =
                HealthViewModel(repository, healthConnectManager) as T
        }
    }
}
