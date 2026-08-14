import SwiftUI
import SwiftData

// MARK: - ListDesignVariant

enum ListDesignVariant: String, CaseIterable, Identifiable {
    case list1 = "Linear Bento Cards"
    case list2 = "Compact Grouped Sections"
    case list3 = "Focus Horizon Cards"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .list1: return "square.grid.2x2"
        case .list2: return "list.bullet.indent"
        case .list3: return "rectangle.stack"
        }
    }
}

// MARK: - MacTodoListColumn (Task Inventory with Layout Menu)

/// The "List" sub-pillar with a polished Layout dropdown menu.
struct MacTodoListColumn: View {

    @Binding var selection: TodoItem?

    @Query(sort: [SortDescriptor(\TodoItem.createdAt)], animation: .default)
    private var allItems: [TodoItem]

    @AppStorage("mac_todo_list_layout_v2") private var selectedVariant: ListDesignVariant = .list1
    @State private var showCompleted = false

    private var activeItems: [TodoItem] {
        allItems.filter { !$0.isArchived && $0.parentID == nil && $0.startTime == nil }
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

            // Top Header: Task Count
            HStack(spacing: DS.Space.sm) {
                Text("\(openItems.count) tasks")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textTertiary)

                Spacer()
            }
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, DS.Space.sm)

            Divider()

            // Quick Add Input
            MacTodoQuickAdd()
                .padding(.horizontal, DS.Space.md)
                .padding(.vertical, DS.Space.sm)

            Divider()

            // Main List Content
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.md) {
                    switch selectedVariant {
                    case .list1:
                        List1BentoCardsView(
                            items: openItems,
                            doneItems: doneItems,
                            selection: $selection,
                            showCompleted: $showCompleted
                        )
                    case .list2:
                        List2GroupedSectionsView(
                            items: openItems,
                            doneItems: doneItems,
                            selection: $selection,
                            showCompleted: $showCompleted
                        )
                    case .list3:
                        List3FocusCardsView(
                            items: openItems,
                            doneItems: doneItems,
                            selection: $selection,
                            showCompleted: $showCompleted
                        )
                    }
                }
                .padding(.horizontal, DS.Space.md)
                .padding(.vertical, DS.Space.md)
            }
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
        .onChange(of: selectedVariant) { _, newVar in
            PlutoTelemetryEngine.shared.trackLayoutChanged(section: "TodoList", newLayout: newVar.rawValue)
        }
    }
}

// MARK: - Design 1: List1BentoCardsView (Modern Minimalist Cards)

private struct List1BentoCardsView: View {

    let items: [TodoItem]
    let doneItems: [TodoItem]
    @Binding var selection: TodoItem?
    @Binding var showCompleted: Bool

    var body: some View {
        VStack(spacing: 6) {
            ForEach(items, id: \.id) { item in
                List1CardRow(item: item, isSelected: selection?.id == item.id) {
                    selection = item
                }
            }

            if !doneItems.isEmpty {
                completedSection
            }
        }
    }

    private var completedSection: some View {
        VStack(spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) { showCompleted.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                    Text(showCompleted ? "Hide completed" : "\(doneItems.count) completed tasks")
                        .font(DS.Text.caption)
                    Spacer()
                }
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if showCompleted {
                ForEach(doneItems, id: \.id) { item in
                    List1CardRow(item: item, isSelected: selection?.id == item.id) {
                        selection = item
                    }
                }
            }
        }
        .padding(.top, 6)
    }
}

private struct List1CardRow: View {
    @Bindable var item: TodoItem
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\TodoItem.createdAt)]) private var allItems: [TodoItem]
    @State private var isHovered = false

    private var subtasks: [TodoItem] {
        allItems.filter { $0.parentID == item.id && !$0.isArchived }
    }
    private var completedSubtaskCount: Int { subtasks.filter(\.isCompleted).count }

    var body: some View {
        HStack(spacing: 10) {

            // Checkbox
            ZStack {
                Circle()
                    .strokeBorder(item.isCompleted ? Color.accentColor : DS.Color.border, lineWidth: 1.5)
                    .frame(width: 18, height: 18)

                if item.isCompleted {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 18, height: 18)
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .contentShape(Circle())
            .highPriorityGesture(
                TapGesture().onEnded {
                    withAnimation(DS.Motion.settle) {
                        item.completedAt = item.isCompleted ? nil : Date()
                        try? modelContext.save()
                        if item.isCompleted {
                            PlutoTelemetryEngine.shared.trackTaskCompleted(task: item)
                        }
                    }
                    Haptics.impact(.light)
                }
            )

            // Title & Metadata
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                    .strikethrough(item.isCompleted, color: DS.Color.textTertiary)
                    .lineLimit(1)

                // Metadata Pill
                if item.dueDate != nil || !subtasks.isEmpty {
                    HStack(spacing: 6) {
                        if let due = item.dueDate {
                            HStack(spacing: 3) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 8))
                                Text(due, style: .date)
                            }
                            .font(.system(size: 10))
                            .foregroundStyle(isOverdue(due) && !item.isCompleted ? Color.red : DS.Color.textTertiary)
                        }

                        if !subtasks.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 8))
                                Text("\(completedSubtaskCount)/\(subtasks.count)")
                            }
                            .font(.system(size: 10))
                            .foregroundStyle(DS.Color.textTertiary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(DS.Color.surfaceRecessed, in: Capsule())
                        }
                    }
                }
            }

            Spacer()

            // Priority Indicator Pill
            if item.priority > 0 {
                priorityPill(item.priority)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            isSelected ? Color.accentColor.opacity(0.12) : (isHovered ? DS.Color.surfaceRecessed.opacity(0.5) : DS.Color.surface),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor.opacity(0.4) : DS.Color.border.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { isHovered = $0 }
    }

    private func priorityPill(_ p: Int) -> some View {
        let (label, color) = priorityInfo(p)
        return Text(label)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.14), in: Capsule())
    }

    private func priorityInfo(_ p: Int) -> (String, Color) {
        switch p {
        case 3: return ("High", Color.red)
        case 2: return ("Med", Color.orange)
        case 1: return ("Low", Color.green)
        default: return ("", Color.clear)
        }
    }

    private func isOverdue(_ date: Date) -> Bool {
        Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: .now)
    }
}

// MARK: - Design 2: List2GroupedSectionsView (Grouped by Priority & Status)

private struct List2GroupedSectionsView: View {

    let items: [TodoItem]
    let doneItems: [TodoItem]
    @Binding var selection: TodoItem?
    @Binding var showCompleted: Bool

    private var highPriority: [TodoItem] { items.filter { $0.priority == 3 } }
    private var medPriority: [TodoItem]  { items.filter { $0.priority == 2 } }
    private var normalItems: [TodoItem]  { items.filter { $0.priority < 2 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // High Priority Group
            if !highPriority.isEmpty {
                sectionBlock(title: "HIGH PRIORITY", icon: "flame.fill", color: Color.red, items: highPriority)
            }

            // Medium Priority Group
            if !medPriority.isEmpty {
                sectionBlock(title: "MEDIUM PRIORITY", icon: "bolt.fill", color: Color.orange, items: medPriority)
            }

            // Normal / Other Group
            if !normalItems.isEmpty {
                sectionBlock(title: "TASKS & INBOX", icon: "tray.fill", color: Color.accentColor, items: normalItems)
            }

            // Completed Toggle
            if !doneItems.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { showCompleted.toggle() }
                } label: {
                    Label(
                        showCompleted ? "Hide completed" : "\(doneItems.count) completed tasks",
                        systemImage: showCompleted ? "chevron.up" : "checkmark.circle.fill"
                    )
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textTertiary)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                if showCompleted {
                    sectionBlock(title: "COMPLETED", icon: "checkmark.circle.fill", color: Color(red: 0.18, green: 0.80, blue: 0.44), items: doneItems)
                }
            }
        }
    }

    private func sectionBlock(title: String, icon: String, color: Color, items: [TodoItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.6)
                Spacer()
                Text("\(items.count)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(color.opacity(0.12), in: Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(DS.Color.surfaceRecessed)

            VStack(spacing: 0) {
                ForEach(items, id: \.id) { item in
                    List2DenseRow(item: item, isSelected: selection?.id == item.id, color: color) {
                        selection = item
                    }
                    if item.id != items.last?.id {
                        Divider().padding(.leading, 32)
                    }
                }
            }
        }
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
        )
    }
}

private struct List2DenseRow: View {
    @Bindable var item: TodoItem
    let isSelected: Bool
    let color: Color
    let onSelect: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            // Side Priority Ribbon
            Rectangle()
                .fill(color)
                .frame(width: 3)

            // Checkbox
            Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                .font(.system(size: 13))
                .foregroundStyle(item.isCompleted ? Color.accentColor : DS.Color.textSecondary)
                .contentShape(Rectangle())
                .highPriorityGesture(
                    TapGesture().onEnded {
                        withAnimation(DS.Motion.settle) {
                            item.completedAt = item.isCompleted ? nil : Date()
                            try? modelContext.save()
                            if item.isCompleted {
                                PlutoTelemetryEngine.shared.trackTaskCompleted(task: item)
                            }
                        }
                        Haptics.impact(.light)
                    }
                )

            // Title
            Text(item.title)
                .font(.system(size: 12))
                .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                .strikethrough(item.isCompleted, color: DS.Color.textTertiary)
                .lineLimit(1)

            Spacer()

            if let due = item.dueDate {
                Text(due, style: .date)
                    .font(.system(size: 10))
                    .foregroundStyle(DS.Color.textTertiary)
            }
        }
        .padding(.vertical, 6)
        .padding(.trailing, 8)
        .background(isSelected ? Color.accentColor.opacity(0.12) : (isHovered ? DS.Color.surfaceRecessed.opacity(0.4) : Color.clear))
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { isHovered = $0 }
    }
}

// MARK: - Design 3: List3FocusCardsView (Interactive with Subtask Expander)

private struct List3FocusCardsView: View {

    let items: [TodoItem]
    let doneItems: [TodoItem]
    @Binding var selection: TodoItem?
    @Binding var showCompleted: Bool

    var body: some View {
        VStack(spacing: 8) {
            ForEach(items, id: \.id) { item in
                List3FocusCard(item: item, isSelected: selection?.id == item.id) {
                    selection = item
                }
            }

            if !doneItems.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { showCompleted.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                        Text(showCompleted ? "Hide completed" : "\(doneItems.count) completed tasks")
                            .font(DS.Text.caption)
                        Spacer()
                    }
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                if showCompleted {
                    ForEach(doneItems, id: \.id) { item in
                        List3FocusCard(item: item, isSelected: selection?.id == item.id) {
                            selection = item
                        }
                    }
                }
            }
        }
    }
}

private struct List3FocusCard: View {
    @Bindable var item: TodoItem
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\TodoItem.createdAt)]) private var allItems: [TodoItem]
    @State private var isExpanded = false
    @State private var isHovered = false

    private var subtasks: [TodoItem] {
        allItems.filter { $0.parentID == item.id && !$0.isArchived }
    }
    private var completedSubtaskCount: Int { subtasks.filter(\.isCompleted).count }
    private var progress: Double {
        subtasks.isEmpty ? 0 : Double(completedSubtaskCount) / Double(subtasks.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {

                // Priority Indicator Dot
                Circle()
                    .fill(priorityColor(item.priority))
                    .frame(width: 8, height: 8)

                // Checkbox
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundStyle(item.isCompleted ? Color(red: 0.18, green: 0.80, blue: 0.44) : DS.Color.textSecondary)
                    .contentShape(Circle())
                    .highPriorityGesture(
                        TapGesture().onEnded {
                            withAnimation(DS.Motion.settle) {
                                item.completedAt = item.isCompleted ? nil : Date()
                                try? modelContext.save()
                                if item.isCompleted {
                                    PlutoTelemetryEngine.shared.trackTaskCompleted(task: item)
                                }
                            }
                            Haptics.impact(.light)
                        }
                    )

                // Title & Details
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                        .strikethrough(item.isCompleted, color: DS.Color.textTertiary)
                        .lineLimit(1)

                    if let due = item.dueDate {
                        Text(due, style: .date)
                            .font(.system(size: 10))
                            .foregroundStyle(isOverdue(due) && !item.isCompleted ? Color.red : DS.Color.textTertiary)
                    }
                }

                Spacer()

                // Subtask Progress Ring & Expander
                if !subtasks.isEmpty {
                    Button {
                        withAnimation(DS.Motion.settle) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            TodoProgressRing(progress: progress, diameter: 14, lineWidth: 2)
                            Text("\(completedSubtaskCount)/\(subtasks.count)")
                                .font(.system(size: 10, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(DS.Color.textTertiary)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(DS.Color.surfaceRecessed, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)

            // Inline Expanded Subtasks List
            if isExpanded && !subtasks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Divider().padding(.horizontal, 8)
                    ForEach(subtasks, id: \.id) { sub in
                        HStack(spacing: 8) {
                            Image(systemName: sub.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 10))
                                .foregroundStyle(sub.isCompleted ? Color(red: 0.18, green: 0.80, blue: 0.44) : DS.Color.textTertiary)
                                .contentShape(Circle())
                                .highPriorityGesture(
                                    TapGesture().onEnded {
                                        withAnimation(DS.Motion.settle) {
                                            sub.completedAt = sub.isCompleted ? nil : Date()
                                            try? modelContext.save()
                                        }
                                        Haptics.impact(.light)
                                    }
                                )

                            Text(sub.title)
                                .font(.system(size: 11))
                                .foregroundStyle(sub.isCompleted ? DS.Color.textTertiary : DS.Color.textSecondary)
                                .strikethrough(sub.isCompleted, color: DS.Color.textTertiary)
                        }
                        .padding(.leading, 32)
                        .padding(.vertical, 2)
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .background(
            isSelected ? Color.accentColor.opacity(0.12) : (isHovered ? DS.Color.surfaceRecessed.opacity(0.4) : DS.Color.surface),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor.opacity(0.5) : DS.Color.border.opacity(0.4), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { isHovered = $0 }
    }

    private func priorityColor(_ p: Int) -> Color {
        switch p {
        case 3: return Color.red
        case 2: return Color.orange
        case 1: return Color.green
        default: return Color.clear
        }
    }

    private func isOverdue(_ date: Date) -> Bool {
        Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: .now)
    }
}

