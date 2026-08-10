import SwiftUI
import SwiftData

// MARK: - MacTodoDetailColumn   (T3 edit / delete · T4 un-complete)

/// Right detail column showing the selected `TodoItem`.
///
/// All fields are edited inline — no separate "edit mode":
/// - Title via a `TextField` at the top.
/// - Due date via `DatePicker` (clearable).
/// - Notes via a resizable `TextEditor`.
///
/// Completion toggle (T4) lives in the toolbar so it's always reachable
/// without scrolling. Archive (soft-delete, T3) is a destructive toolbar button.
struct MacTodoDetailColumn: View {

    let item: TodoItem?

    var body: some View {
        if let item {
            MacTodoEditor(item: item)
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
    @State private var showDeleteConfirm = false
    @State private var hasDueDate: Bool
    @State private var isScheduled: Bool

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
