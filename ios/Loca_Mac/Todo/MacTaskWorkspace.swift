import SwiftUI
import SwiftData

// MARK: - MacTaskWorkspace   (P1 — dedicated task page)

/// A full-window, focused editing surface for a single `TodoItem`.
///
/// Opened from the task List (single click) and presented as an overlay above
/// the three-pane split, replacing the narrow detail panel for that flow. It
/// reuses the **existing** `TodoItem` model, subtask (`parentID`) pattern,
/// priority scale (0–3), and `modelContext.save()` autosave — no parallel task
/// state is introduced.
///
/// Layout, top to bottom:
/// - **Nav bar**: a Back control to return to the list.
/// - **Header controls**: completion, Due Date, Priority — the three fields the
///   reference design surfaces at the top of a task.
/// - **Title**: large, high-contrast, directly editable.
/// - **Description**: a spacious plain-text notes editor.
/// - **Subtasks**: the existing checklist, add / toggle / remove.
///
/// The design leans on hairline dividers and generous spacing rather than
/// nested cards, matching the requested "spacious, minimal, no clutter" look.
struct MacTaskWorkspace: View {

    @Bindable var item: TodoItem
    let onClose: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: [SortDescriptor(\TodoItem.createdAt)]) private var allItems: [TodoItem]

    @FocusState private var titleFocused: Bool

    @State private var showDatePicker = false
    @State private var showDeleteConfirm = false

    // MARK: Derived

    private var subtasks: [TodoItem] {
        allItems
            .filter { $0.parentID == item.id && !$0.isArchived }
            .sorted { $0.createdAt < $1.createdAt }
    }
    private var completedSubtaskCount: Int { subtasks.filter(\.isCompleted).count }

    /// Content is centered in a readable column rather than stretched edge-to-edge.
    private let contentMaxWidth: CGFloat = 720

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            navBar
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xl) {
                    headerControls
                    Divider()
                    titleField
                    descriptionEditor
                    Divider()
                    subtasksSection
                    Spacer(minLength: DS.Space.xxxl)
                }
                .frame(maxWidth: contentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, DS.Space.xxl)
                .padding(.top, DS.Space.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.background)
        .confirmationDialog(
            "Delete \"\(item.title.isEmpty ? "Untitled" : item.title)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                item.archivedAt = Date()
                save()
                onClose()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The task will be removed. This can't be undone from the app.")
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack(spacing: DS.Space.sm) {
            Button(action: onClose) {
                Label("Back", systemImage: "chevron.backward")
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textSecondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
            .help("Back to task list")

            Spacer()

            Button(role: .destructive) { showDeleteConfirm = true } label: {
                Image(systemName: "trash")
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .buttonStyle(.plain)
            .help("Delete task")
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.sm)
    }

    // MARK: - Header controls (completion · due date · priority)

    private var headerControls: some View {
        HStack(spacing: DS.Space.sm) {
            completionButton
            dueDateControl
            Spacer()
            priorityControl
        }
    }

    private var completionButton: some View {
        Button(action: toggleComplete) {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(item.isCompleted ? Color.accentColor : DS.Color.textSecondary)
                Text(item.isCompleted ? "Completed" : "Mark complete")
                    .font(DS.Text.body)
                    .foregroundStyle(item.isCompleted ? Color.accentColor : DS.Color.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .help(item.isCompleted ? "Mark not done" : "Mark done")
    }

    private var dueDateControl: some View {
        Button { showDatePicker.toggle() } label: {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: "calendar")
                    .font(.caption)
                if let due = item.dueDate {
                    Text(due.formatted(.dateTime.month(.abbreviated).day().year(.defaultDigits)))
                        .font(DS.Text.body)
                } else {
                    Text("Due Date").font(DS.Text.body)
                }
            }
            .foregroundStyle(item.dueDate != nil ? Color.accentColor : DS.Color.textSecondary)
            .padding(.horizontal, DS.Space.sm)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.control)
                    .fill(item.dueDate != nil ? Color.accentColor.opacity(0.12) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.control)
                    .stroke(DS.Color.border.opacity(item.dueDate != nil ? 0 : 0.6), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
            VStack(spacing: 0) {
                DatePicker(
                    "Due",
                    selection: Binding(
                        get: { item.dueDate ?? Calendar.current.startOfDay(for: .now) },
                        set: { item.dueDate = $0; save() }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(DS.Space.md)

                if item.dueDate != nil {
                    Divider()
                    Button(role: .destructive) {
                        item.dueDate = nil
                        save()
                        showDatePicker = false
                    } label: {
                        Label("Remove Date", systemImage: "calendar.badge.minus")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Space.sm)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                }
            }
            .frame(width: 300)
        }
    }

    private var priorityControl: some View {
        Menu {
            Button { setPriority(0) } label: { priorityMenuLabel(0) }
            Divider()
            Button { setPriority(1) } label: { priorityMenuLabel(1) }
            Button { setPriority(2) } label: { priorityMenuLabel(2) }
            Button { setPriority(3) } label: { priorityMenuLabel(3) }
        } label: {
            HStack(spacing: DS.Space.xs) {
                Image(systemName: item.priority > 0 ? "flag.fill" : "flag")
                    .font(.caption)
                Text(item.priority > 0 ? priorityLabel(item.priority) : "Priority")
                    .font(DS.Text.body)
            }
            .foregroundStyle(item.priority > 0 ? priorityColor(item.priority) : DS.Color.textSecondary)
            .padding(.horizontal, DS.Space.sm)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.control)
                    .fill(item.priority > 0 ? priorityColor(item.priority).opacity(0.14) : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.control)
                    .stroke(DS.Color.border.opacity(item.priority > 0 ? 0 : 0.6), lineWidth: 1)
            )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Set priority")
    }

    @ViewBuilder
    private func priorityMenuLabel(_ p: Int) -> some View {
        if p == 0 {
            Label("None", systemImage: item.priority == 0 ? "checkmark" : "flag.slash")
        } else {
            Label(priorityLabel(p), systemImage: item.priority == p ? "checkmark" : "flag.fill")
        }
    }

    // MARK: - Title

    private var titleField: some View {
        TextField("What would you like to do?", text: $item.title, axis: .vertical)
            .font(.system(size: 30, weight: .bold))
            .tracking(-0.5)
            .textFieldStyle(.plain)
            .focused($titleFocused)
            .strikethrough(item.isCompleted, color: DS.Color.textTertiary)
            .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
            .onChange(of: item.title) { _, _ in save() }
    }

    // MARK: - Description

    private var descriptionEditor: some View {
        ZStack(alignment: .topLeading) {
            if (item.notes ?? "").isEmpty {
                Text("Add notes, details, or context…")
                    .font(DS.Text.body)
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(.top, 2)
                    .allowsHitTesting(false)
            }
            TextEditor(text: Binding(
                get: { item.notes ?? "" },
                set: { item.notes = $0.isEmpty ? nil : $0; save() }
            ))
            .font(DS.Text.body)
            .foregroundStyle(DS.Color.textPrimary)
            .frame(minHeight: 140)
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Subtasks

    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.sm) {
            HStack {
                Text("SUBTASKS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(DS.Color.textTertiary)
                if !subtasks.isEmpty {
                    Text("\(completedSubtaskCount)/\(subtasks.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.textTertiary)
                }
            }

            VStack(spacing: 0) {
                ForEach(subtasks, id: \.id) { sub in
                    WorkspaceSubtaskRow(sub: sub) { delete(sub) }
                    if sub.id != subtasks.last?.id {
                        Divider()
                    }
                }
            }

            Button(action: addSubtask) {
                HStack(spacing: DS.Space.sm) {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(DS.Color.textTertiary)
                    Text("Add subtask")
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .padding(.vertical, DS.Space.xs)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func toggleComplete() {
        withAnimation(reduceMotion ? .linear(duration: 0.1) : DS.Motion.settle) {
            item.completedAt = item.isCompleted ? nil : Date()
        }
        save()
        Haptics.impact(.light)
    }

    private func setPriority(_ p: Int) {
        item.priority = p
        save()
    }

    private func addSubtask() {
        let sub = TodoItem(parentID: item.id)
        modelContext.insert(sub)
        save()
        Haptics.impact(.light)
    }

    private func delete(_ sub: TodoItem) {
        sub.archivedAt = Date()
        save()
    }

    private func save() {
        try? modelContext.save()
    }

    // MARK: - Helpers

    private func priorityLabel(_ p: Int) -> String {
        switch p {
        case 1: return "Low"
        case 2: return "Medium"
        case 3: return "High"
        default: return "None"
        }
    }

    /// Matches the existing list conventions (`MacTodoRow.priorityColor`).
    private func priorityColor(_ p: Int) -> Color {
        switch p {
        case 1: return .green
        case 2: return .orange
        case 3: return .red
        default: return DS.Color.textSecondary
        }
    }
}

// MARK: - WorkspaceSubtaskRow

/// One subtask line: a completion toggle, an inline-editable title, and a
/// hover-revealed remove button. Operates directly on the shared `TodoItem`.
private struct WorkspaceSubtaskRow: View {

    @Bindable var sub: TodoItem
    let onDelete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: DS.Space.sm) {
            Button {
                sub.completedAt = sub.isCompleted ? nil : Date()
                try? modelContext.save()
                Haptics.impact(.light)
            } label: {
                Image(systemName: sub.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(sub.isCompleted ? Color.accentColor : DS.Color.textSecondary)
            }
            .buttonStyle(.plain)

            TextField("Subtask", text: $sub.title)
                .font(DS.Text.body)
                .textFieldStyle(.plain)
                .strikethrough(sub.isCompleted, color: DS.Color.textTertiary)
                .foregroundStyle(sub.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                .onChange(of: sub.title) { _, _ in try? modelContext.save() }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)
            .help("Remove subtask")
        }
        .padding(.vertical, DS.Space.sm)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.1), value: isHovered)
    }
}
