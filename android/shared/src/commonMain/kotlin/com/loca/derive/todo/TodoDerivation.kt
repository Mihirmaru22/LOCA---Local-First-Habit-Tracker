package com.loca.derive.todo

import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDate
import kotlin.uuid.Uuid

enum class TodoStatus { ACTIVE, COMPLETED, DELETED }

data class TodoItem(
    val todoID: Uuid,
    val title: String,
    val dueDate: Instant?,
    val notes: String?,
    val status: TodoStatus,
    val createdDate: LocalDate,
    /** Set when status is COMPLETED; null otherwise. */
    val completedDate: LocalDate?,
    /** True when ACTIVE and dueDate has passed relative to the reference date. */
    val isOverdue: Boolean
)

data class TodoSummary(
    /** Active items: overdue (dueDate past) first, then upcoming by dueDate, then no-date last. */
    val active: List<TodoItem>,
    /** Completed items, newest completedDate first. */
    val completed: List<TodoItem>,
    /** Deleted items, newest createdDate first. Kept for audit. */
    val deleted: List<TodoItem>,
    val totalCompleted: Int,
    /** completed / (active + completed). 0.0 when no todos exist. */
    val completionRate: Double
)
