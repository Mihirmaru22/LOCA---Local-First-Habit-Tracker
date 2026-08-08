package com.loca.android.ui.journal

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
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
import com.loca.android.ui.displayString
import com.loca.android.ui.runWrite
import com.loca.derive.journal.IntentionEntry
import com.loca.derive.journal.JournalDeriver
import com.loca.derive.journal.JournalSummary
import com.loca.derive.journal.MomentEntry
import com.loca.derive.journal.ReflectionEntry
import com.loca.record.IntentionPeriod
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.datetime.Clock
import kotlinx.datetime.TimeZone
import kotlinx.datetime.todayIn

private enum class EntryType(val label: String) {
    REFLECTION("Reflection"),
    MOMENT("Moment"),
    INTENTION("Intention"),
}

@Composable
fun JournalScreen() {
    val context = LocalContext.current
    val container = (context.applicationContext as LOCAApplication).container
    val scope = rememberCoroutineScope()
    val snackbar = LocalSnackbar.current

    var summary by remember { mutableStateOf<JournalSummary?>(null) }
    var loading by remember { mutableStateOf(true) }
    var reloadKey by remember { mutableIntStateOf(0) }
    var showAdd by remember { mutableStateOf(false) }

    LaunchedEffect(reloadKey) {
        loading = true
        summary = withContext(Dispatchers.Default) {
            val signals = container.signals()
            val tz = TimeZone.currentSystemDefault()
            val now = Clock.System.now()
            val today = Clock.System.todayIn(tz)
            JournalDeriver.deriveAll(signals, today, now, tz)
        }
        loading = false
    }

    Box(Modifier.fillMaxSize()) {
        val s = summary
        val isEmpty = s == null || (
            s.totalEntries == 0 &&
                s.activeIntentions.isEmpty() &&
                s.expiredIntentions.isEmpty()
            )
        when {
            loading -> LoadingBox()
            isEmpty -> EmptyJournal()
            else -> JournalContent(s!!)
        }
        FloatingActionButton(
            onClick = { showAdd = true },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(20.dp)
        ) {
            Icon(Icons.Default.Add, contentDescription = "New entry")
        }
    }

    if (showAdd) {
        NewEntryDialog(
            onDismiss = { showAdd = false },
            onCreate = { type, text, tags, period ->
                showAdd = false
                scope.launch {
                    val draft = when (type) {
                        EntryType.REFLECTION -> UserEntry.reflection(text)
                        EntryType.MOMENT -> UserEntry.moment(text, tags)
                        EntryType.INTENTION -> UserEntry.intention(text, period)
                    }
                    val ok = snackbar.runWrite("Couldn't save entry") {
                        container.record(draft)
                    }
                    if (ok) reloadKey++
                }
            }
        )
    }
}

@Composable
private fun JournalContent(summary: JournalSummary) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            JournalHeader(summary)
            Spacer(Modifier.height(4.dp))
        }

        if (summary.activeIntentions.isNotEmpty()) {
            item {
                SectionLabel("Intentions")
            }
            items(summary.activeIntentions, key = { it.id.toString() }) { intention ->
                IntentionCard(intention)
            }
        }

        if (summary.reflections.isNotEmpty()) {
            item {
                Spacer(Modifier.height(4.dp))
                SectionLabel("Reflections")
            }
            items(summary.reflections.take(10), key = { it.id.toString() }) { reflection ->
                ReflectionCard(reflection)
            }
        }

        if (summary.moments.isNotEmpty()) {
            item {
                Spacer(Modifier.height(4.dp))
                SectionLabel("Moments")
            }
            items(summary.moments.take(10), key = { it.id.toString() }) { moment ->
                MomentCard(moment)
            }
        }

        if (summary.tagCloud.isNotEmpty()) {
            item {
                Spacer(Modifier.height(4.dp))
                SectionLabel("Tags")
                Spacer(Modifier.height(4.dp))
                TagCloud(summary.tagCloud)
            }
        }

        if (summary.expiredIntentions.isNotEmpty()) {
            item {
                Spacer(Modifier.height(4.dp))
                SectionLabel("Past intentions")
            }
            items(summary.expiredIntentions.take(10), key = { it.id.toString() }) { intention ->
                IntentionCard(intention, dimmed = true)
            }
        }

        item { Spacer(Modifier.height(88.dp)) }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun TagCloud(tags: Map<String, Int>) {
    // Bigger, more-frequent tags read first.
    val ordered = tags.entries.sortedByDescending { it.value }
    FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        ordered.forEach { (tag, count) ->
            Surface(
                shape = MaterialTheme.shapes.small,
                color = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.6f)
            ) {
                Text(
                    text = if (count > 1) "#$tag · $count" else "#$tag",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSecondaryContainer,
                    modifier = Modifier.padding(horizontal = 9.dp, vertical = 5.dp)
                )
            }
        }
    }
}

@Composable
private fun JournalHeader(summary: JournalSummary) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        color = MaterialTheme.colorScheme.secondaryContainer
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Journal",
                    style = MaterialTheme.typography.headlineMedium,
                    color = MaterialTheme.colorScheme.onSecondaryContainer
                )
                Text(
                    text = "${summary.totalEntries} entries",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSecondaryContainer.copy(alpha = 0.7f)
                )
            }
            if (summary.journalStreak > 0) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.LocalFireDepartment,
                        contentDescription = "Streak",
                        modifier = Modifier.size(20.dp),
                        tint = MaterialTheme.colorScheme.onSecondaryContainer
                    )
                    Spacer(Modifier.width(4.dp))
                    Column(horizontalAlignment = Alignment.End) {
                        Text(
                            text = "${summary.journalStreak}",
                            style = MaterialTheme.typography.displayMedium,
                            color = MaterialTheme.colorScheme.onSecondaryContainer
                        )
                        Text(
                            text = "day streak",
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSecondaryContainer.copy(alpha = 0.7f)
                        )
                    }
                }
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
private fun IntentionCard(intention: IntentionEntry, dimmed: Boolean = false) {
    val contentAlpha = if (dimmed) 0.55f else 1f
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (dimmed)
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.4f)
            else
                MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = if (dimmed) 0.dp else 1.dp)
    ) {
        Row(
            modifier = Modifier.padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Flag,
                contentDescription = null,
                modifier = Modifier.size(16.dp),
                tint = MaterialTheme.colorScheme.secondary.copy(alpha = contentAlpha)
            )
            Spacer(Modifier.width(10.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = intention.text,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = contentAlpha),
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = "${intention.date.displayString()} · ${intention.period.name.lowercase().replaceFirstChar { it.uppercase() }}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = contentAlpha)
                )
            }
        }
    }
}

@Composable
private fun ReflectionCard(reflection: ReflectionEntry) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.AutoStories,
                    contentDescription = null,
                    modifier = Modifier.size(14.dp),
                    tint = MaterialTheme.colorScheme.secondary
                )
                Spacer(Modifier.width(6.dp))
                Text(
                    text = reflection.date.displayString(),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(Modifier.height(6.dp))
            Text(
                text = reflection.text,
                style = MaterialTheme.typography.bodyMedium,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun MomentCard(moment: MomentEntry) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.Star,
                    contentDescription = null,
                    modifier = Modifier.size(14.dp),
                    tint = MaterialTheme.colorScheme.secondary
                )
                Spacer(Modifier.width(6.dp))
                Text(
                    text = moment.date.displayString(),
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            Spacer(Modifier.height(6.dp))
            Text(
                text = moment.text,
                style = MaterialTheme.typography.bodyMedium,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis
            )
            if (moment.tags.isNotEmpty()) {
                Spacer(Modifier.height(8.dp))
                FlowRow(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    moment.tags.forEach { tag ->
                        TagChip(tag)
                    }
                }
            }
        }
    }
}

@Composable
private fun TagChip(tag: String) {
    Surface(
        shape = MaterialTheme.shapes.small,
        color = MaterialTheme.colorScheme.secondaryContainer.copy(alpha = 0.6f)
    ) {
        Text(
            text = "#$tag",
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSecondaryContainer,
            modifier = Modifier.padding(horizontal = 7.dp, vertical = 3.dp)
        )
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun NewEntryDialog(
    onDismiss: () -> Unit,
    onCreate: (type: EntryType, text: String, tags: List<String>, period: IntentionPeriod) -> Unit,
) {
    var type by remember { mutableStateOf(EntryType.REFLECTION) }
    var text by remember { mutableStateOf("") }
    var tagsRaw by remember { mutableStateOf("") }
    var period by remember { mutableStateOf(IntentionPeriod.DAILY) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("New journal entry") },
        text = {
            Column {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    EntryType.entries.forEach { option ->
                        FilterChip(
                            selected = type == option,
                            onClick = { type = option },
                            label = { Text(option.label) }
                        )
                    }
                }
                Spacer(Modifier.height(12.dp))
                OutlinedTextField(
                    value = text,
                    onValueChange = { if (it.length <= 2000) text = it },
                    label = { Text("What's on your mind?") },
                    minLines = 2,
                    supportingText = { Text("${text.length}/2000") },
                    modifier = Modifier.fillMaxWidth()
                )
                if (type == EntryType.MOMENT) {
                    Spacer(Modifier.height(12.dp))
                    OutlinedTextField(
                        value = tagsRaw,
                        onValueChange = { if (it.length <= 200) tagsRaw = it },
                        label = { Text("Tags (comma-separated)") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
                if (type == EntryType.INTENTION) {
                    Spacer(Modifier.height(12.dp))
                    Text(
                        text = "Period",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Spacer(Modifier.height(8.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        IntentionPeriod.entries.forEach { option ->
                            FilterChip(
                                selected = period == option,
                                onClick = { period = option },
                                label = {
                                    Text(option.name.lowercase().replaceFirstChar { it.uppercase() })
                                }
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            TextButton(
                onClick = {
                    val tags = tagsRaw.split(",")
                        .map { it.trim() }
                        .filter { it.isNotEmpty() }
                    onCreate(type, text.trim(), tags, period)
                },
                enabled = text.isNotBlank()
            ) { Text("Save") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}

@Composable
private fun EmptyJournal() {
    EmptyStateBox(
        icon = Icons.Default.AutoStories,
        title = "No journal entries yet",
        subtitle = "Tap + to write one"
    )
}
