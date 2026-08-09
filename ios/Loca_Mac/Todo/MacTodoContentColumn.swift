import SwiftUI
import SwiftData

// MARK: - MacTodoContentColumn   (T2 — Today / Upcoming / Anytime)

/// Middle column of the Mac three-pane layout for the Today (Todo) section.
///
/// Three named sections mirror the GTD-style buckets computed by `TodoItem.bucket`:
/// - **Today** — tasks due today or overdue.
/// - **Upcoming** — tasks with a future due date.
/// - **Anytime** — tasks with no due date.
///
/// Completed tasks are de-emphasised in-list but not hidden; they move to the
/// bottom of their section so the user can still see and un-complete them (T4).
struct MacTodoContentColumn: View {

    @Binding var selection: TodoItem?

    @Query(sort: [SortDescriptor(\TodoItem.createdAt)], animation: .default)
    private var allItems: [TodoItem]

    private var activeItems: [TodoItem] {
        allItems.filter { !$0.isArchived }
    }

    private var todayItems:    [TodoItem] { activeItems.filter { $0.bucket == .today    } }
    private var upcomingItems: [TodoItem] { activeItems.filter { $0.bucket == .upcoming } }
    private var anytimeItems:  [TodoItem] { activeItems.filter { $0.bucket == .anytime  } }

    var body: some View {
        VStack(spacing: 0) {
            // Quick-add bar pinned at top (T1)
            MacTodoQuickAdd()
                .padding(.horizontal, DS.Space.md)
                .padding(.vertical, DS.Space.sm)

            Divider()

            // Sectioned list with selection
            List(selection: $selection) {
                if !todayItems.isEmpty {
                    Section("Today") {
                        ForEach(sortedSection(todayItems), id: \.id) { item in
                            MacTodoRow(item: item)
                                .tag(item)
                        }
                    }
                }

                if !upcomingItems.isEmpty {
                    Section("Upcoming") {
                        ForEach(sortedSection(upcomingItems), id: \.id) { item in
                            MacTodoRow(item: item)
                                .tag(item)
                        }
                    }
                }

                if !anytimeItems.isEmpty {
                    Section("Anytime") {
                        ForEach(sortedSection(anytimeItems), id: \.id) { item in
                            MacTodoRow(item: item)
                                .tag(item)
                        }
                    }
                }

                if activeItems.isEmpty {
                    emptyState
                }
            }
            .listStyle(.inset)
        }
        .navigationTitle("Tasks")
    }

    // Completed items sink to the bottom of their section
    private func sortedSection(_ items: [TodoItem]) -> [TodoItem] {
        items.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            return ($0.dueDate ?? $0.createdAt) < ($1.dueDate ?? $1.createdAt)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Tasks", systemImage: "checkmark.circle")
        } description: {
            Text("Type a task in the bar above and press Return.")
        }
    }
}

// MARK: - MacTodoRow

/// A single row in the todo list.
///
/// - Leading circle toggles completion in-list (T4).
/// - Title is struck-through when completed.
/// - Due-date chip shown when set.
private struct MacTodoRow: View {

    @Bindable var item: TodoItem
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: DS.Space.md) {
            // Completion circle (T4 — toggle)
            Button(action: toggleComplete) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textSecondary)
            }
            .buttonStyle(.plain)
            .help(item.isCompleted ? "Mark not done" : "Mark done")

            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough(item.isCompleted, color: DS.Color.textTertiary)
                    .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                    .lineLimit(1)

                if let due = item.dueDate {
                    Text(due, style: .date)
                        .font(DS.Text.footnote)
                        .foregroundStyle(isOverdue(due) && !item.isCompleted
                                         ? .red : DS.Color.textTertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, DS.Space.xs)
        .contentShape(Rectangle())
    }

    private func toggleComplete() {
        item.completedAt = item.isCompleted ? nil : Date()
        try? modelContext.save()
        Haptics.impact(.light)
    }

    private func isOverdue(_ date: Date) -> Bool {
        Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: .now)
    }
}
