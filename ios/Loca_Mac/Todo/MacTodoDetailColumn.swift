import SwiftUI
import SwiftData

// MARK: - MacTodoDetailColumn   (T3 edit / delete · T4 un-complete)

/// Right detail column showing the selected `TodoItem`.
///
/// All fields are edited inline — no separate "edit mode":
/// - Title via a `TextField` at the top.
/// - Due date via `DatePicker` (clearable).
/// - Schedule on the day-planner timeline (start time + duration).
/// - Priority via a segmented `Picker`.
/// - Notes via a resizable `TextEditor`.
///
/// Completion toggle (T4) lives in the toolbar so it's always reachable
/// without scrolling. Archive (soft-delete, T3) is a destructive toolbar button.
struct MacTodoDetailColumn: View {

    let item: TodoItem?

    var body: some View {
        if let item {
            MacTodoEditor(item: item)
                .id(item.id)
        } else {
            ContentUnavailableView(
                "No Task Selected",
                systemImage: "checkmark.circle",
                description: Text("Choose a task from the list or add one with Return.")
            )
        }
    }
}

// MARK: - MacTodoEditor

private struct MacTodoEditor: View {

    @Bindable var item: TodoItem
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\TodoItem.createdAt)]) private var allItems: [TodoItem]
    @State private var showDeleteConfirm = false
    @State private var showIconPicker    = false
    @State private var hasDueDate: Bool
    @State private var isScheduled: Bool

    private var subtasks: [TodoItem] {
        allItems.filter { $0.parentID == item.id && !$0.isArchived }
    }
    private var completedSubtaskCount: Int { subtasks.filter(\.isCompleted).count }
    private var subtaskProgress: Double {
        subtasks.isEmpty ? 0 : Double(completedSubtaskCount) / Double(subtasks.count)
    }

    init(item: TodoItem) {
        self.item = item
        self._hasDueDate  = State(initialValue: item.dueDate != nil)
        self._isScheduled = State(initialValue: item.startTime != nil)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {

                // MARK: Title (T3 — inline edit)
                TextField("Task title", text: $item.title, axis: .vertical)
                    .font(DS.Text.title)
                    .textFieldStyle(.plain)
                    .onChange(of: item.title) { _, _ in autosave() }
                    .padding(.top, DS.Space.xl)

                Divider()

                // MARK: Icon (T7 — per-task icon)
                HStack(spacing: DS.Space.sm) {
                    Label("Icon", systemImage: "square.grid.2x2")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)

                    Spacer()

                    Button { showIconPicker.toggle() } label: {
                        HStack(spacing: DS.Space.xs) {
                            Image(systemName: item.iconName ?? "checkmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .frame(width: 28, height: 28)
                                .background {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .overlay {
                                            Circle().fill(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.28), Color.clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .center
                                                )
                                            )
                                        }
                                }

                            Text(TodoIcon.label(for: item.iconName ?? "checkmark"))
                                .font(DS.Text.caption)
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showIconPicker, arrowEdge: .trailing) {
                        IconPickerPopover(
                            selected: Binding(
                                get: { item.iconName },
                                set: { item.iconName = $0; showIconPicker = false; autosave() }
                            )
                        )
                    }
                }

                Divider()

                // MARK: Due date (T3 — set / clear)
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    Toggle("Due date", isOn: $hasDueDate)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: hasDueDate) { _, on in
                            item.dueDate = on ? (item.dueDate ?? Date()) : nil
                            autosave()
                        }

                    if hasDueDate {
                        DatePicker(
                            "Due",
                            selection: Binding(
                                get:  { item.dueDate ?? Date() },
                                set:  { item.dueDate = $0; autosave() }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                    }
                }

                Divider()

                // MARK: Schedule on timeline (day-planner sub-pillar)
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    Toggle("Schedule on timeline", isOn: $isScheduled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: isScheduled) { _, on in
                            item.startTime = on ? (item.startTime ?? defaultStart()) : nil
                            autosave()
                        }

                    if isScheduled {
                        DatePicker(
                            "Start",
                            selection: Binding(
                                get: { item.startTime ?? defaultStart() },
                                set: { item.startTime = $0; autosave() }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .controlSize(.small)

                        Stepper(
                            value: Binding(
                                get: { item.durationMinutes },
                                set: { item.durationMinutes = max(0, $0); autosave() }
                            ),
                            in: 0...600,
                            step: 15
                        ) {
                            Text(item.durationMinutes == 0
                                 ? "No duration"
                                 : "\(item.durationMinutes) min")
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                        .controlSize(.small)
                    }
                }

                Divider()

                // MARK: Priority (T3)
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Label("Priority", systemImage: "flag.fill")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)

                    Picker("Priority", selection: $item.priority) {
                        Text("None").tag(0)
                        Text("Low").tag(1)
                        Text("Medium").tag(2)
                        Text("High").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .onChange(of: item.priority) { _, _ in autosave() }
                }

                Divider()

                // MARK: Subtasks (T8)
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    HStack(spacing: DS.Space.xs) {
                        Label("Subtasks", systemImage: "checklist")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)

                        if !subtasks.isEmpty {
                            TodoProgressRing(progress: subtaskProgress, diameter: 16, lineWidth: 2)
                            Text("\(completedSubtaskCount)/\(subtasks.count)")
                                .font(DS.Text.footnote)
                                .foregroundStyle(DS.Color.textTertiary)
                                .monospacedDigit()
                        }

                        Spacer()

                        Button(action: addSubtask) {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.tint)
                        }
                        .buttonStyle(.plain)
                        .help("Add subtask")
                    }

                    ForEach(subtasks) { sub in
                        SubtaskRow(sub: sub) { deleteSubtask(sub) }
                    }
                }

                Divider()

                // MARK: Notes (T3 — inline edit)
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    Label("Notes", systemImage: "note.text")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)

                    TextEditor(text: Binding(
                        get:  { item.notes ?? "" },
                        set:  { item.notes = $0.isEmpty ? nil : $0; autosave() }
                    ))
                    .font(DS.Text.body)
                    .frame(minHeight: 120)
                    .scrollContentBackground(.hidden)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
                }

                Spacer(minLength: DS.Space.xxxl)
            }
            .padding(.horizontal, DS.Space.xl)
        }
        .navigationTitle(item.title.isEmpty ? "Task" : item.title)
        .toolbar {
            // T4 — Complete / un-complete
            ToolbarItem(placement: .primaryAction) {
                Button(action: toggleComplete) {
                    Label(
                        item.isCompleted ? "Mark Not Done" : "Mark Done",
                        systemImage: item.isCompleted ? "checkmark.circle.fill" : "circle"
                    )
                }
                .help(item.isCompleted ? "Mark not done (un-complete)" : "Mark done")
                .tint(item.isCompleted ? DS.Color.textSecondary : .accentColor)
            }

            // T3 — Delete (archive)
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive, action: { showDeleteConfirm = true }) {
                    Label("Delete Task", systemImage: "trash")
                }
                .help("Archive this task")
            }
        }
        .confirmationDialog(
            "Delete \"\(item.title)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: archiveItem)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The task will be removed. This can't be undone from the app.")
        }
    }

    // MARK: - Actions

    // T8 — subtask management
    private func addSubtask() {
        let sub = TodoItem(parentID: item.id)
        modelContext.insert(sub)
        autosave()
        Haptics.impact(.light)
    }

    private func deleteSubtask(_ sub: TodoItem) {
        sub.archivedAt = Date()
        autosave()
    }

    // T4 — toggle completion
    private func toggleComplete() {
        item.completedAt = item.isCompleted ? nil : Date()
        autosave()
        Haptics.impact(.light)
    }

    // T3 — soft delete
    private func archiveItem() {
        item.archivedAt = Date()
        autosave()
    }

    private func autosave() {
        try? modelContext.save()
    }

    /// Default timeline slot when a task is first scheduled: 9:00 AM on its due
    /// day (or today if it has no due date).
    private func defaultStart() -> Date {
        let cal = Calendar.current
        let day = item.dueDate ?? Date()
        return cal.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
    }
}

// MARK: - SubtaskRow

private struct SubtaskRow: View {

    @Bindable var sub: TodoItem
    @Environment(\.modelContext) private var modelContext
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            Button {
                sub.completedAt = sub.isCompleted ? nil : Date()
                try? modelContext.save()
                Haptics.impact(.light)
            } label: {
                Image(systemName: sub.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(sub.isCompleted ? DS.Color.textTertiary : DS.Color.textSecondary)
            }
            .buttonStyle(.plain)

            TextField("Subtask", text: $sub.title)
                .font(DS.Text.body)
                .textFieldStyle(.plain)
                .strikethrough(sub.isCompleted, color: DS.Color.textTertiary)
                .foregroundStyle(sub.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                .onChange(of: sub.title) { _, _ in try? modelContext.save() }

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .buttonStyle(.plain)
            .help("Remove subtask")
        }
        .padding(.vertical, DS.Space.xs)
        .padding(.horizontal, DS.Space.sm)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.control))
    }
}
