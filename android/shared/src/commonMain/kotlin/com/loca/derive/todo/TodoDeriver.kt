package com.loca.derive.todo

import com.loca.signal.Signal
import com.loca.signal.SignalKind
import com.loca.signal.SignalPayload
import kotlinx.datetime.Instant
import kotlinx.datetime.LocalDate
import kotlinx.datetime.TimeZone
import kotlinx.datetime.toLocalDateTime
import kotlin.uuid.Uuid

/**
 * Pure derivation of todo state from a flat signal list.
 *
 * Invariants:
 *  - One TodoItem per todoID. The creation signal is the canonical identity.
 *  - CORRECTION signals mutate title, dueDate, or notes; latest correction per field wins.
 *  - DELETION_REQUESTED targeting a creation signal's id marks the todo DELETED.
 *  - DELETED beats COMPLETED if both apply to the same todo.
 *  - All outputs are deterministic: same signals + same today → same result.
 *  - No signals are written; this is a read-only computation.
 */
object TodoDeriver {

    /**
     * Derive current state for every todo.
     *
     * @param signals  All signals from the Signal store (unfiltered).
     * @param today    Reference date for overdue detection.
     * @param tz       Timezone used to convert Instant → LocalDate.
     */
    fun deriveAll(
        signals: List<Signal>,
        today: LocalDate,
        tz: TimeZone = TimeZone.currentSystemDefault()
    ): TodoSummary {
        // Creation signal per todoID — multiple signals for same todoID shouldn't happen,
        // but if they do, the latest one wins.
        val creationByTodoID: Map<Uuid, Signal> = signals
            .filter { it.kind == SignalKind.TODO_CREATION }
            .mapNotNull { signal ->
                val p = signal.payload as? SignalPayload.TodoCreation ?: return@mapNotNull null
                p.todoID to signal
            }
            .groupBy({ it.first }, { it.second })
            .mapValues { (_, sigs) -> sigs.sortedBy { it.occurredAt }.last() }

        // Most recent completion date per todoID — by when the completion
        // OCCURRED, not by signal-list order (unstable after replay).
        val completionDateByTodoID: Map<Uuid, LocalDate> = signals
            .filter { it.kind == SignalKind.TODO_COMPLETION }
            .mapNotNull { signal ->
                val p = signal.payload as? SignalPayload.TodoCompletion ?: return@mapNotNull null
                p.todoID to signal
            }
            .groupBy({ it.first }, { it.second })
            .mapValues { (_, sigs) ->
                sigs.maxBy { it.occurredAt }.occurredAt.toLocalDateTime(tz).date
            }

        // Corrections per target signal id, sorted oldest→newest so the last write wins
        val correctionsByTargetID: Map<Uuid, List<SignalPayload.Correction>> = signals
            .filter { it.kind == SignalKind.CORRECTION }
            .sortedBy { it.occurredAt }
            .mapNotNull { signal ->
                val p = signal.payload as? SignalPayload.Correction ?: return@mapNotNull null
                p.targetFactID to p
            }
            .groupBy({ it.first }, { it.second })

        // Signal IDs of creation facts that have been deleted
        val deletedFactIDs: Set<Uuid> = signals
            .filter { it.kind == SignalKind.DELETION_REQUESTED }
            .mapNotNull { (it.payload as? SignalPayload.Deletion)?.targetFactID }
            .toHashSet()

        val items: List<TodoItem> = creationByTodoID.map { (todoID, creationSignal) ->
            val creation = creationSignal.payload as SignalPayload.TodoCreation
            val corrections = correctionsByTargetID[creationSignal.id] ?: emptyList()

            var title = creation.title
            var dueDate: Instant? = creation.dueDate
            var notes: String? = creation.notes

            for (c in corrections) {
                when (c.field) {
                    "title"   -> title = c.correctedValue
                    "dueDate" -> dueDate = runCatching { Instant.parse(c.correctedValue) }.getOrNull()
                    "notes"   -> notes = c.correctedValue.ifEmpty { null }
                }
            }

            val completedDate = completionDateByTodoID[todoID]
            val status = when {
                creationSignal.id in deletedFactIDs -> TodoStatus.DELETED
                completedDate != null               -> TodoStatus.COMPLETED
                else                                -> TodoStatus.ACTIVE
            }

            val isOverdue = status == TodoStatus.ACTIVE &&
                dueDate != null &&
                dueDate.toLocalDateTime(tz).date < today

            TodoItem(
                todoID = todoID,
                factID = creationSignal.id,
                title = title,
                dueDate = dueDate,
                notes = notes,
                status = status,
                createdDate = creationSignal.occurredAt.toLocalDateTime(tz).date,
                completedDate = completedDate,
                isOverdue = isOverdue
            )
        }

        val active = items
            .filter { it.status == TodoStatus.ACTIVE }
            .sortedWith { a, b ->
                when {
                    a.dueDate == null && b.dueDate == null ->
                        a.createdDate.compareTo(b.createdDate)
                    a.dueDate == null -> 1
                    b.dueDate == null -> -1
                    else -> a.dueDate.compareTo(b.dueDate)
                        .takeIf { it != 0 } ?: a.createdDate.compareTo(b.createdDate)
                }
            }

        val completed = items
            .filter { it.status == TodoStatus.COMPLETED }
            .sortedByDescending { it.completedDate }

        val deleted = items
            .filter { it.status == TodoStatus.DELETED }
            .sortedByDescending { it.createdDate }

        val totalWithOutcome = active.size + completed.size
        val completionRate = if (totalWithOutcome == 0) 0.0
                             else completed.size.toDouble() / totalWithOutcome

        return TodoSummary(
            active = active,
            completed = completed,
            deleted = deleted,
            totalCompleted = completed.size,
            completionRate = completionRate
        )
    }
}
