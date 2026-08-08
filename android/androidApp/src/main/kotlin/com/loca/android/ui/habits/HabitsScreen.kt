package com.loca.android.ui.habits

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.loca.android.LOCAApplication
import com.loca.android.data.UserEntry
import com.loca.android.ui.EmptyStateBox
import com.loca.android.ui.LoadingBox
import com.loca.android.ui.LocalSnackbar
import com.loca.android.ui.runWrite
import com.loca.derive.habits.HabitDeriver
import com.loca.derive.habits.HabitSummary
import com.loca.record.HabitFrequency
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.todayIn

@Composable
fun HabitsScreen() {
    val context = LocalContext.current
    val container = (context.applicationContext as LOCAApplication).container
    val scope = rememberCoroutineScope()
    val snackbar = LocalSnackbar.current

    var habits by remember { mutableStateOf<List<HabitSummary>>(emptyList()) }
    var loading by remember { mutableStateOf(true) }
    var reloadKey by remember { mutableIntStateOf(0) }
    var showAdd by remember { mutableStateOf(false) }

    LaunchedEffect(reloadKey) {
        loading = true
        // Read + derive off the main thread — deriveAll builds a 365-day grid
        // per habit and would jank the UI as data grows.
        habits = withContext(Dispatchers.Default) {
            val signals = container.signals()
            val today = Clock.System.todayIn(TimeZone.currentSystemDefault())
            HabitDeriver.deriveAll(signals, today)
        }
        loading = false
    }

    Box(Modifier.fillMaxSize()) {
        when {
            loading -> LoadingBox()
            habits.isEmpty() -> EmptyHabits()
            else -> HabitList(
                habits = habits,
                onLog = { habit ->
                    scope.launch {
                        val ok = snackbar.runWrite("Couldn't log habit") {
                            container.record(UserEntry.logHabit(habit.habitID))
                        }
                        if (ok) reloadKey++
                    }
                }
            )
        }
        FloatingActionButton(
            onClick = { showAdd = true },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(20.dp)
        ) {
            Icon(Icons.Default.Add, contentDescription = "New habit")
        }
    }

    if (showAdd) {
        NewHabitDialog(
            onDismiss = { showAdd = false },
            onCreate = { name, frequency ->
                showAdd = false
                scope.launch {
                    val ok = snackbar.runWrite("Couldn't create habit") {
                        container.record(UserEntry.defineHabit(name, frequency))
                    }
                    if (ok) reloadKey++
                }
            }
        )
    }
}

@Composable
private fun HabitList(habits: List<HabitSummary>, onLog: (HabitSummary) -> Unit) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        item {
            HabitsHeader(habits)
            Spacer(Modifier.height(4.dp))
        }
        items(habits, key = { it.habitID.toString() }) { habit ->
            HabitCard(habit, onLog = { onLog(habit) })
        }
        item { Spacer(Modifier.height(88.dp)) }
    }
}

@Composable
private fun HabitsHeader(habits: List<HabitSummary>) {
    val avgRate = if (habits.isEmpty()) 0.0
    else habits.sumOf { it.completionRate } / habits.size

    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        color = MaterialTheme.colorScheme.primaryContainer
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Habits",
                    style = MaterialTheme.typography.headlineMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
                Text(
                    text = "${habits.size} tracked",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "${(avgRate * 100).toInt()}%",
                    style = MaterialTheme.typography.displayMedium,
                    color = MaterialTheme.colorScheme.onPrimaryContainer
                )
                Text(
                    text = "avg 30-day",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                )
            }
        }
    }
}

@Composable
private fun HabitCard(habit: HabitSummary, onLog: () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = habit.name,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                Spacer(Modifier.width(8.dp))
                FrequencyChip(habit.frequency)
            }

            Spacer(Modifier.height(12.dp))

            LinearProgressIndicator(
                progress = { habit.completionRate.toFloat() },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp),
                color = MaterialTheme.colorScheme.primary,
                trackColor = MaterialTheme.colorScheme.surfaceVariant
            )

            Spacer(Modifier.height(10.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.LocalFireDepartment,
                        contentDescription = "Streak",
                        modifier = Modifier.size(14.dp),
                        tint = if (habit.streak.current > 0)
                            MaterialTheme.colorScheme.primary
                        else
                            MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
                    )
                    Spacer(Modifier.width(2.dp))
                    Text(
                        text = "${habit.streak.current} day streak",
                        style = MaterialTheme.typography.labelMedium,
                        color = if (habit.streak.current > 0)
                            MaterialTheme.colorScheme.primary
                        else
                            MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
                FilledTonalButton(
                    onClick = onLog,
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(
                        horizontal = 14.dp, vertical = 6.dp
                    )
                ) {
                    Icon(
                        Icons.Default.Check,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(Modifier.width(4.dp))
                    Text("Log", style = MaterialTheme.typography.labelMedium)
                }
            }
        }
    }
}

@Composable
private fun FrequencyChip(frequency: HabitFrequency) {
    Surface(
        shape = MaterialTheme.shapes.small,
        color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.6f)
    ) {
        Text(
            text = frequency.name.lowercase().replaceFirstChar { it.uppercase() },
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onPrimaryContainer,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
        )
    }
}

@Composable
private fun NewHabitDialog(
    onDismiss: () -> Unit,
    onCreate: (name: String, frequency: HabitFrequency) -> Unit,
) {
    var name by remember { mutableStateOf("") }
    var frequency by remember { mutableStateOf(HabitFrequency.DAILY) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("New habit") },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { if (it.length <= 100) name = it },
                    label = { Text("Name") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(16.dp))
                Text(
                    text = "Frequency",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(Modifier.height(8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    HabitFrequency.entries.forEach { option ->
                        FilterChip(
                            selected = frequency == option,
                            onClick = { frequency = option },
                            label = {
                                Text(option.name.lowercase().replaceFirstChar { it.uppercase() })
                            }
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = { onCreate(name.trim(), frequency) },
                enabled = name.isNotBlank()
            ) { Text("Create") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}

@Composable
private fun EmptyHabits() {
    EmptyStateBox(
        icon = Icons.Default.FitnessCenter,
        title = "No habits yet",
        subtitle = "Tap + to add one"
    )
}
