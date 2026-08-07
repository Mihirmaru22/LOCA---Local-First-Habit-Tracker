package com.loca.android.ui.todo

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
import androidx.compose.material.icons.filled.CheckBox
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.loca.android.LOCAApplication
import com.loca.derive.todo.TodoDeriver
import com.loca.derive.todo.TodoItem
import com.loca.derive.todo.TodoSummary
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.datetime.Clock
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime

@Composable
fun TodoScreen() {
    val context = LocalContext.current
    val container = (context.applicationContext as LOCAApplication).container

    var summary by remember { mutableStateOf<TodoSummary?>(null) }
    var loading by remember { mutableStateOf(true) }

    LaunchedEffect(Unit) {
        val signals = withContext(Dispatchers.IO) { container.signalStore.allSignals() }
        val today = Clock.System.todayIn(TimeZone.currentSystemDefault())
        summary = TodoDeriver.deriveAll(signals, today)
        loading = false
    }

    when {
        loading -> LoadingBox()
        summary == null || (summary!!.active.isEmpty() && summary!!.completed.isEmpty()) ->
            EmptyTodo()
        else -> TodoContent(summary!!)
    }
}

@Composable
private fun TodoContent(summary: TodoSummary) {
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
                TodoItemCard(item, completed = false)
            }
        }

        if (summary.completed.isNotEmpty()) {
            item {
                Spacer(Modifier.height(4.dp))
                SectionLabel("Done  ·  ${summary.completed.size}")
            }
            items(summary.completed.take(20), key = { it.todoID.toString() }) { item ->
                TodoItemCard(item, completed = true)
            }
        }

        item { Spacer(Modifier.height(16.dp)) }
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
private fun TodoItemCard(item: TodoItem, completed: Boolean) {
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
            Icon(
                imageVector = when {
                    completed -> Icons.Default.CheckCircle
                    item.isOverdue -> Icons.Default.Warning
                    else -> Icons.Default.RadioButtonUnchecked
                },
                contentDescription = null,
                modifier = Modifier.size(20.dp),
                tint = when {
                    completed -> MaterialTheme.colorScheme.tertiary.copy(alpha = 0.6f)
                    item.isOverdue -> MaterialTheme.colorScheme.error
                    else -> MaterialTheme.colorScheme.tertiary
                }
            )
            Spacer(Modifier.width(12.dp))
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
    return when {
        completed && item.completedDate != null ->
            "Done ${item.completedDate.display()}"
        item.isOverdue && item.dueDate != null ->
            "Overdue · due ${item.dueDate.toLocalDateTime(tz).date.display()}"
        item.dueDate != null ->
            "Due ${item.dueDate.toLocalDateTime(tz).date.display()}"
        else -> ""
    }
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
