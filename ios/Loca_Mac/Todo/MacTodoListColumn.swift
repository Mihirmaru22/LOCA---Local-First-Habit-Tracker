import SwiftUI
import SwiftData

// MARK: - MacTodoListColumn   (task inventory)

/// The "List" sub-pillar — a flat task inventory.
///
/// No date-based grouping. All non-archived top-level tasks appear in a single
/// continuous collection ordered by creation date. Completed tasks hide under a
/// toggle at the bottom. Date/time metadata is shown per-row but never drives grouping.
struct MacTodoListColumn: View {

    @Binding var selection: TodoItem?

    @Query(sort: [SortDescriptor(\TodoItem.createdAt)], animation: .default)
    private var allItems: [TodoItem]

    @State private var showCompleted = false

    private var activeItems: [TodoItem] {
        allItems.filter { !$0.isArchived && $0.parentID == nil }
    }

    private var openItems: [TodoItem] {
        activeItems.filter { !$0.isCompleted }
    }

    private var doneItems: [TodoItem] {
        activeItems
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        VStack(spacing: 0) {
            MacTodoQuickAdd()
                .padding(.horizontal, DS.Space.md)
                .padding(.vertical, DS.Space.sm)

            Divider()

            List(selection: $selection) {
                ForEach(openItems, id: \.id) { item in
                    MacTodoRow(item: item).tag(item)
                }

                if !doneItems.isEmpty {
                    if showCompleted {
                        ForEach(doneItems, id: \.id) { item in
                            MacTodoRow(item: item).tag(item)
                        }
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) { showCompleted.toggle() }
                    } label: {
                        Label(
                            showCompleted ? "Hide completed" : "\(doneItems.count) completed",
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
        // Selecting a task in the List opens the dedicated Task Workspace.
        // Scoped to the List so Plan-mode block selection is unaffected.
        .onChange(of: selection) { _, newValue in
            if let task = newValue {
                NotificationCenter.default.post(name: .locaOpenTask, object: task)
            }
        }
    }
}

// MARK: - MacTodoRow

/// A single row in the todo list.
///
/// Leading priority dot (hidden when priority == 0) → completion circle → title/date.
/// The dot is always allocated its 6 pt width to keep title alignment consistent.
struct MacTodoRow: View {

    @Bindable var item: TodoItem
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\TodoItem.createdAt)]) private var allItems: [TodoItem]
    @State private var circleScale: CGFloat = 1.0

    private var subtasks: [TodoItem] {
        allItems.filter { $0.parentID == item.id && !$0.isArchived }
    }
    private var completedSubtaskCount: Int { subtasks.filter(\.isCompleted).count }
    private var subtaskProgress: Double {
        subtasks.isEmpty ? 0 : Double(completedSubtaskCount) / Double(subtasks.count)
    }

    var body: some View {
        HStack(spacing: DS.Space.sm) {

            // Priority dot (always same width; invisible when priority == 0)
            Circle()
                .fill(priorityColor(item.priority))
                .frame(width: 6, height: 6)
                .opacity(item.priority > 0 ? 1 : 0)

            // Completion toggle with spring bounce
            Button(action: toggleComplete) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? Color.accentColor : DS.Color.textSecondary)
                    .scaleEffect(circleScale)
            }
            .buttonStyle(.plain)
            .help(item.isCompleted ? "Mark not done" : "Mark done")

            // Title + optional due date
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough(item.isCompleted, color: DS.Color.textTertiary)
                    .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                    .lineLimit(1)
                    .animation(DS.Motion.settle, value: item.isCompleted)

                // Metadata line: date · time (or date · subtask count)
                if item.dueDate != nil || item.startTime != nil || !subtasks.isEmpty {
                    HStack(spacing: 4) {
                        if let due = item.dueDate {
                            Text(due, style: .date)
                                .foregroundStyle(isOverdue(due) && !item.isCompleted
                                                 ? .red : DS.Color.textTertiary)
                        }

                        if let start = item.startTime {
                            if item.dueDate != nil { Text("·").foregroundStyle(DS.Color.textTertiary) }
                            Text(start, format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute())
                                .foregroundStyle(DS.Color.textTertiary)
                        }

                        if !subtasks.isEmpty {
                            if item.dueDate != nil || item.startTime != nil {
                                Text("·").foregroundStyle(DS.Color.textTertiary)
                            }
                            TodoProgressRing(progress: subtaskProgress, diameter: 12, lineWidth: 1.5)
                            Text("\(completedSubtaskCount)/\(subtasks.count)")
                                .foregroundStyle(DS.Color.textTertiary)
                                .monospacedDigit()
                        }
                    }
                    .font(DS.Text.footnote)
                }
            }

            Spacer()
        }
        .padding(.vertical, DS.Space.xs)
        .contentShape(Rectangle())
    }

    private func toggleComplete() {
        // Bounce the circle on every tap
        withAnimation(.spring(response: 0.18, dampingFraction: 0.4)) { circleScale = 1.25 }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7).delay(0.12)) { circleScale = 1.0 }
        withAnimation(DS.Motion.settle) {
            item.completedAt = item.isCompleted ? nil : Date()
        }
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
