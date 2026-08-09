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
/// Within each section, incomplete tasks appear first sorted by due date.
/// Completed tasks are hidden under a "N completed" toggle so the active list
/// stays focused — clicking the toggle expands them across all sections at once.
struct MacTodoContentColumn: View {

    @Binding var selection: TodoItem?

    @Query(sort: [SortDescriptor(\TodoItem.createdAt)], animation: .default)
    private var allItems: [TodoItem]

    @State private var showCompleted = false

    private var activeItems: [TodoItem] {
        allItems.filter { !$0.isArchived }
    }

    private func openItems(in bucket: TodoBucket) -> [TodoItem] {
        activeItems
            .filter { $0.bucket == bucket && !$0.isCompleted }
            .sorted { ($0.dueDate ?? $0.createdAt) < ($1.dueDate ?? $1.createdAt) }
    }

    private func doneItems(in bucket: TodoBucket) -> [TodoItem] {
        activeItems
            .filter { $0.bucket == bucket && $0.isCompleted }
            .sorted { ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt) }
    }

    private var totalDone: Int {
        TodoBucket.allCases.reduce(0) { $0 + doneItems(in: $1).count }
    }

    var body: some View {
        VStack(spacing: 0) {
            MacTodoQuickAdd()
                .padding(.horizontal, DS.Space.md)
                .padding(.vertical, DS.Space.sm)

            Divider()

            List(selection: $selection) {
                ForEach(TodoBucket.allCases, id: \.self) { bucket in
                    let open = openItems(in: bucket)
                    let done = doneItems(in: bucket)

                    if !open.isEmpty || !done.isEmpty {
                        Section(bucket.rawValue) {
                            ForEach(open, id: \.id) { item in
                                MacTodoRow(item: item).tag(item)
                            }

                            if !done.isEmpty && showCompleted {
                                ForEach(done, id: \.id) { item in
                                    MacTodoRow(item: item).tag(item)
                                }
                            }
                        }
                    }
                }

                // Single toggle at the bottom for all completed tasks
                if totalDone > 0 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showCompleted.toggle()
                        }
                    } label: {
                        Label(
                            showCompleted ? "Hide completed" : "\(totalDone) completed",
                            systemImage: showCompleted ? "chevron.up" : "checkmark.circle.fill"
                        )
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.vertical, DS.Space.xs)
                }
            }
            .listStyle(.inset)
            .overlay {
                if activeItems.isEmpty {
                    ContentUnavailableView {
                        Label("No Tasks", systemImage: "checkmark.circle")
                    } description: {
                        Text("Type a task in the bar above and press Return.")
                    }
                }
            }
        }
        .navigationTitle("Tasks")
    }
}

// MARK: - MacTodoRow

/// A single row in the todo list.
///
/// Leading priority dot (hidden when priority == 0) → completion circle → title/date.
/// The dot is always allocated its 6 pt width to keep title alignment consistent.
private struct MacTodoRow: View {

    @Bindable var item: TodoItem
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: DS.Space.sm) {

            // Priority dot (always same width; invisible when priority == 0)
            Circle()
                .fill(priorityColor(item.priority))
                .frame(width: 6, height: 6)
                .opacity(item.priority > 0 ? 1 : 0)

            // Completion toggle
            Button(action: toggleComplete) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textSecondary)
            }
            .buttonStyle(.plain)
            .help(item.isCompleted ? "Mark not done" : "Mark done")

            // Title + optional due date
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

    private func priorityColor(_ p: Int) -> Color {
        switch p {
        case 1: return .green
        case 2: return .orange
        case 3: return .red
        default: return .clear
        }
    }
}
