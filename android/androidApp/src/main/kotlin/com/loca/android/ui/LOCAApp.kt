package com.loca.android.ui

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AutoStories
import androidx.compose.material.icons.filled.CheckBox
import androidx.compose.material.icons.filled.FitnessCenter
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.loca.android.ui.habits.HabitsScreen
import com.loca.android.ui.journal.JournalScreen
import com.loca.android.ui.todo.TodoScreen

sealed class LOCADestination(val route: String, val label: String) {
    data object Habits  : LOCADestination("habits",  "Habits")
    data object Journal : LOCADestination("journal", "Journal")
    data object Todo    : LOCADestination("todo",    "Todo")
}

private val topLevelDestinations = listOf(
    LOCADestination.Habits,
    LOCADestination.Journal,
    LOCADestination.Todo,
)

@Composable
fun LOCAApp() {
    val navController = rememberNavController()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route
    val snackbarHostState = remember { SnackbarHostState() }

    CompositionLocalProvider(LocalSnackbar provides snackbarHostState) {
    Scaffold(
        modifier = Modifier.fillMaxSize(),
        snackbarHost = { SnackbarHost(snackbarHostState) },
        bottomBar = {
            NavigationBar {
                topLevelDestinations.forEach { destination ->
                    NavigationBarItem(
                        selected = currentRoute == destination.route,
                        onClick  = {
                            navController.navigate(destination.route) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon  = {
                            Icon(
                                imageVector = when (destination) {
                                    LOCADestination.Habits  -> Icons.Default.FitnessCenter
                                    LOCADestination.Journal -> Icons.Default.AutoStories
                                    LOCADestination.Todo    -> Icons.Default.CheckBox
                                },
                                contentDescription = destination.label
                            )
                        },
                        label = { Text(destination.label) }
                    )
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController    = navController,
            startDestination = LOCADestination.Habits.route,
            modifier         = Modifier.padding(innerPadding)
        ) {
            composable(LOCADestination.Habits.route)  { HabitsScreen()  }
            composable(LOCADestination.Journal.route) { JournalScreen() }
            composable(LOCADestination.Todo.route)    { TodoScreen()    }
        }
    }
    }
}
