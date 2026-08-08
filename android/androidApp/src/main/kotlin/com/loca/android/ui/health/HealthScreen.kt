package com.loca.android.ui.health

import androidx.activity.compose.rememberLauncherForActivityResult
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.DirectionsWalk
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.MonitorHeart
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.health.connect.client.PermissionController
import com.loca.android.LOCAApplication
import com.loca.android.health.HealthConnectManager
import com.loca.android.ui.LoadingBox
import com.loca.android.ui.displayString
import com.loca.derive.health.DailyHealthSummary
import com.loca.derive.health.HealthDeriver
import com.loca.derive.health.HealthOverview
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

@Composable
fun HealthScreen() {
    val context = LocalContext.current
    val container = (context.applicationContext as LOCAApplication).container
    val scope = rememberCoroutineScope()

    val manager = container.healthConnectManager
    val isAvailable = remember { manager.isAvailable() }

    var loading by remember { mutableStateOf(true) }
    var hasPermission by remember { mutableStateOf(false) }
    var overview by remember { mutableStateOf<HealthOverview?>(null) }
    var reloadKey by remember { mutableIntStateOf(0) }

    val permLauncher = rememberLauncherForActivityResult(
        contract = PermissionController.createRequestPermissionResultContract()
    ) { granted ->
        if (granted.containsAll(HealthConnectManager.PERMISSIONS)) {
            scope.launch(Dispatchers.IO) {
                container.importHealth()
                reloadKey++
            }
        }
    }

    LaunchedEffect(reloadKey) {
        if (!isAvailable) { loading = false; return@LaunchedEffect }
        loading = true
        hasPermission = withContext(Dispatchers.IO) { manager.hasPermissions() }
        if (hasPermission) {
            overview = withContext(Dispatchers.Default) {
                HealthDeriver.deriveOverview(container.signals())
            }
        }
        loading = false
    }

    when {
        loading -> LoadingBox()
        !isAvailable -> NotAvailableBox()
        !hasPermission -> NeedsPermissionBox(
            onRequest = { permLauncher.launch(HealthConnectManager.PERMISSIONS) }
        )
        overview == null || overview!!.days.isEmpty() -> NoDataBox()
        else -> HealthContent(overview!!)
    }
}

@Composable
private fun HealthContent(overview: HealthOverview) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        item {
            HealthHeader(overview)
            Spacer(Modifier.height(4.dp))
        }
        item {
            Text(
                text = "Recent Days",
                style = MaterialTheme.typography.titleSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 4.dp, bottom = 2.dp)
            )
        }
        items(overview.days, key = { it.date.toString() }) { day ->
            DaySummaryCard(day)
        }
        item { Spacer(Modifier.height(88.dp)) }
    }
}

@Composable
private fun HealthHeader(overview: HealthOverview) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        color = MaterialTheme.colorScheme.primaryContainer
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Health",
                style = MaterialTheme.typography.headlineMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
            Text(
                text = "30-day averages",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
            )
            Spacer(Modifier.height(16.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                MetricCard(
                    icon = Icons.Default.DirectionsWalk,
                    label = "Steps",
                    value = overview.avgSteps?.let { "%,d".format(it.toLong()) } ?: "—",
                    modifier = Modifier.weight(1f)
                )
                MetricCard(
                    icon = Icons.Default.Favorite,
                    label = "Heart Rate",
                    value = overview.avgHeartRateBpm?.let { "${it.toInt()} bpm" } ?: "—",
                    modifier = Modifier.weight(1f)
                )
                MetricCard(
                    icon = Icons.Default.Bedtime,
                    label = "Sleep",
                    value = overview.avgSleepHours?.let { formatSleep(it) } ?: "—",
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
private fun MetricCard(
    icon: ImageVector,
    label: String,
    value: String,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier,
        shape = MaterialTheme.shapes.small,
        color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.08f)
    ) {
        Column(
            modifier = Modifier.padding(10.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(18.dp),
                tint = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = value,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onPrimaryContainer,
                textAlign = TextAlign.Center,
                maxLines = 1
            )
            Text(
                text = label,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.6f),
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun DaySummaryCard(day: DailyHealthSummary) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = day.date.displayString(),
                style = MaterialTheme.typography.labelLarge,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.weight(1.4f)
            )
            DayMetric(
                icon = Icons.Default.DirectionsWalk,
                value = day.steps?.let { "%,d".format(it.toLong()) } ?: "—",
                modifier = Modifier.weight(1f)
            )
            DayMetric(
                icon = Icons.Default.Favorite,
                value = day.avgHeartRateBpm?.let { "${it.toInt()}" } ?: "—",
                modifier = Modifier.weight(0.8f)
            )
            DayMetric(
                icon = Icons.Default.Bedtime,
                value = day.sleepHours?.let { formatSleep(it) } ?: "—",
                modifier = Modifier.weight(0.9f)
            )
        }
    }
}

@Composable
private fun DayMetric(icon: ImageVector, value: String, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(12.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
        )
        Text(
            text = " $value",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurface
        )
    }
}

@Composable
private fun NotAvailableBox() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(32.dp)
        ) {
            Icon(
                imageVector = Icons.Default.MonitorHeart,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
            )
            Spacer(Modifier.height(12.dp))
            Text(
                text = "Health Connect not available",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = "Health Connect is required to import health data. It's available on Android 14+ or via the Health Connect app.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                textAlign = TextAlign.Center
            )
        }
    }
}

@Composable
private fun NeedsPermissionBox(onRequest: () -> Unit) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(32.dp)
        ) {
            Icon(
                imageVector = Icons.Default.MonitorHeart,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.6f)
            )
            Spacer(Modifier.height(12.dp))
            Text(
                text = "Health access needed",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = "Grant access to steps, heart rate, and sleep to see your health data here.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            Spacer(Modifier.height(20.dp))
            Button(onClick = onRequest) { Text("Grant Health Access") }
        }
    }
}

@Composable
private fun NoDataBox() {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(32.dp)
        ) {
            Icon(
                imageVector = Icons.Default.MonitorHeart,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
            )
            Spacer(Modifier.height(12.dp))
            Text(
                text = "No health data yet",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(Modifier.height(4.dp))
            Text(
                text = "Health data from the last 30 days will appear here once imported.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                textAlign = TextAlign.Center
            )
        }
    }
}

private fun formatSleep(hours: Double): String {
    val h = hours.toInt()
    val m = ((hours - h) * 60).toInt()
    return if (m == 0) "${h}h" else "${h}h ${m}m"
}
