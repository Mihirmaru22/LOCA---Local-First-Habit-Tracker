package com.loca.android.ui.todo

import androidx.compose.foundation.clickable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.material.icons.filled.CheckBox
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.loca.android.LOCAApplication
import com.loca.android.data.UserEntry
import com.loca.android.ui.LocalSnackbar
import com.loca.android.ui.runWrite
import com.loca.derive.todo.TodoDeriver
import com.loca.derive.todo.TodoItem
import com.loca.derive.todo.TodoSummary
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.datetime.Clock
import kotlinx.datetime.DateTimeUnit
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.atStartOfDayIn
import kotlinx.datetime.plus
import kotlinx.datetime.toLocalDateTime
import kotlinx.datetime.todayIn

private enum class DueOption(val label: String) {
    NONE("No date"),
    TODAY("Today"),
    TOMORROW("Tomorrow"),
    NEXT_WEEK("Next week"),
}

/** Resolve a due-date quick-pick to an Instant at the start of that local day. */
private fun DueOption.toInstant(): Instant? {
    if (this == DueOption.NONE) return null
    val tz = TimeZone.currentSystemDefault()
    val today = Clock.System.todayIn(tz)
    val date = when (this) {
        DueOption.NONE -> return null
        DueOption.TODAY -> today
        DueOption.TOMORROW -> today.plus(1, DateTimeUnit.DAY)
        DueOption.NEXT_WEEK -> today.plus(7, DateTimeUnit.DAY)
    }
    return date.atStartOfDayIn(tz)
}

@Composable
fun TodoScreen() {
    val context = LocalContext.current
    val container = (context.applicationContext as LOCAApplication).container
    val scope = rememberCoroutineScope()
    val snackbar = LocalSnackbar.current

    var summary by remember { mutableStateOf<TodoSummary?>(null) }
    var loading by remember { mutableStateOf(true) }
    var reloadKey by remember { mutableIntStateOf(0) }
    var showAdd by remember { mutableStateOf(false) }

    LaunchedEffect(reloadKey) {
        loading = true
        summary = withContext(Dispatchers.Default) {
            val signals = container.signals()
            val today = Clock.System.todayIn(TimeZone.currentSystemDefault())
            TodoDeriver.deriveAll(signals, today)
        }
        loading = false
    }

    Box(Modifier.fillMaxSize()) {
        val s = summary
        when {
            loading -> LoadingBox()
            s == null || (s.active.isEmpty() && s.completed.isEmpty()) ->
                EmptyTodo()
            else -> TodoContent(
                summary = s,
                onComplete = { item ->
                    scope.launch {
                        val ok = snackbar.runWrite("Couldn't complete task") {
                            container.record(UserEntry.completeTodo(item.todoID))
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
            Icon(Icons.Default.Add, contentDescription = "New task")
        }
    }

    if (showAdd) {
        NewTaskDialog(
            onDismiss = { showAdd = false },
            onCreate = { title, notes, dueDate ->
                showAdd = false
                scope.launch {
                    val ok = snackbar.runWrite("Couldn't add task") {
                        container.record(UserEntry.createTodo(title, dueDate = dueDate, notes = notes))
                    }
                    if (ok) reloadKey++
                }
            }
        )
    }
}

@Composable
private fun TodoContent(summary: TodoSummary, onComplete: (TodoItem) -> Unit) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            TodoHeader(summary)
            Spacer(Modifier.height(4.dp))
        }

        if (summary.active.isNotEmpty()) {
            item { SectionLabel("Active  ·  ${summary.active.size}") }
            items(summary.active, key = { it.todoID.toString() }) { item ->
                TodoItemCard(item, completed = false, onComplete = { onComplete(item) })
            }
        }

        if (summary.completed.isNotEmpty()) {
            item {
                Spacer(Modifier.height(4.dp))
                SectionLabel("Done  ·  ${summary.completed.size}")
            }
            items(summary.completed.take(20), key = { it.todoID.toString() }) { item ->
                TodoItemCard(item, completed = true, onComplete = {})
            }
        }

        item { Spacer(Modifier.height(88.dp)) }
    }
}

@Composable
private fun TodoHeader(summary: TodoSummary) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        color = MaterialTheme.colorScheme.tertiaryContainer
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "Todo",
                        style = MaterialTheme.typography.headlineMedium,
                        color = MaterialTheme.colorScheme.onTertiaryContainer
                    )
                    Text(
                        text = "${summary.active.size} active · ${summary.totalCompleted} done",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onTertiaryContainer.copy(alpha = 0.7f)
                    )
                }
                Text(
                    text = "${(summary.completionRate * 100).toInt()}%",
                    style = MaterialTheme.typography.displayMedium,
                    color = MaterialTheme.colorScheme.onTertiaryContainer
                )
            }
            if (summary.completionRate > 0.0) {
                Spacer(Modifier.height(10.dp))
                LinearProgressIndicator(
                    progress = { summary.completionRate.toFloat() },
                    modifier = Modifier.fillMaxWidth().height(6.dp),
                    color = MaterialTheme.colorScheme.onTertiaryContainer,
                    trackColor = MaterialTheme.colorScheme.onTertiaryContainer.copy(alpha = 0.2f)
                )
            }
        }
    }
}

@Composable
private fun SectionLabel(title: String) {
    Text(
        text = title.uppercase(),
        style = MaterialTheme.typography.labelSmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(vertical = 4.dp)
    )
}

@Composable
private fun TodoItemCard(item: TodoItem, completed: Boolean, onComplete: () -> Unit) {
    val tz = TimeZone.currentSystemDefault()

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = when {
                item.isOverdue -> MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.3f)
                completed -> MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                else -> MaterialTheme.colorScheme.surface
            }
        ),
        elevation = CardDefaults.cardElevation(
            defaultElevation = if (completed) 0.dp else 1.dp
        )
    ) {
        Row(
            modifier = Modifier.padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // 48dp touch target (a11y minimum) with the icon drawn at 20dp.
            // Clickable only for active items; completed items are static.
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .then(
                        if (!completed)
                            Modifier
                                .clip(CircleShape)
                                .clickable(
                                    onClick = onComplete,
                                    role = Role.Button
                                )
                        else Modifier
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = when {
                        completed -> Icons.Default.CheckCircle
                        item.isOverdue -> Icons.Default.Warning
                        else -> Icons.Default.RadioButtonUnchecked
                    },
                    contentDescription = if (completed) null else "Mark \"${item.title}\" done",
                    modifier = Modifier.size(20.dp),
                    tint = when {
                        completed -> MaterialTheme.colorScheme.tertiary.copy(alpha = 0.6f)
                        item.isOverdue -> MaterialTheme.colorScheme.error
                        else -> MaterialTheme.colorScheme.tertiary
                    }
                )
            }
            Spacer(Modifier.width(4.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = item.title,
                    style = MaterialTheme.typography.bodyMedium,
                    textDecoration = if (completed) TextDecoration.LineThrough else TextDecoration.None,
                    color = if (completed)
                        MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    else
                        MaterialTheme.colorScheme.onSurface,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                val notes = item.notes
                if (!notes.isNullOrBlank() && !completed) {
                    Spacer(Modifier.height(3.dp))
                    Text(
                        text = notes,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                }
                val meta = buildMeta(item, completed, tz)
                if (meta.isNotEmpty()) {
                    Spacer(Modifier.height(2.dp))
                    Text(
                        text = meta,
                        style = MaterialTheme.typography.labelSmall,
                        color = if (item.isOverdue)
                            MaterialTheme.colorScheme.error
                        else
                            MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

private fun buildMeta(item: TodoItem, completed: Boolean, tz: TimeZone): String {
    val completedDate = item.completedDate
    val dueDate = item.dueDate
    return when {
        completed && completedDate != null ->
            "Done ${completedDate.display()}"
        item.isOverdue && dueDate != null ->
            "Overdue · due ${dueDate.toLocalDateTime(tz).date.display()}"
        dueDate != null ->
            "Due ${dueDate.toLocalDateTime(tz).date.display()}"
        else -> ""
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun NewTaskDialog(
    onDismiss: () -> Unit,
    onCreate: (title: String, notes: String?, dueDate: Instant?) -> Unit,
) {
    var title by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }
    var due by remember { mutableStateOf(DueOption.NONE) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("New task") },
        text = {
            Column {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Title") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(12.dp))
                OutlinedTextField(
                    value = notes,
                    onValueChange = { notes = it },
                    label = { Text("Notes (optional)") },
                    minLines = 2,
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(12.dp))
                Text(
                    text = "Due",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(Modifier.height(6.dp))
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    DueOption.entries.forEach { option ->
                        FilterChip(
                            selected = due == option,
                            onClick = { due = option },
                            label = { Text(option.label) }
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    onCreate(title.trim(), notes.trim().ifBlank { null }, due.toInstant())
                },
                enabled = title.isNotBlank()
            ) { Text("Add") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}

@Composable
private fun EmptyTodo() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Icon(
                imageVector = Icons.Default.CheckBox,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
            )
            Spacer(Modifier.height(12.dp))
            Text(
                text = "No tasks yet",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = "Tap + to add one",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
            )
        }
    }
}

@Composable
private fun LoadingBox() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        CircularProgressIndicator(color = MaterialTheme.colorScheme.tertiary)
    }
}

private fun LocalDate.display(): String =
    "${month.name.take(3).lowercase().replaceFirstChar { it.uppercase() }} $dayOfMonth"
