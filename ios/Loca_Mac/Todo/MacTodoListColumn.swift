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

// MARK: - MacTodoListColumn (Task Inventory with Liquid Glass Layout Menu)

/// The "List" sub-pillar styled with macOS 2027 Liquid Glassmorphism.
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

            // Top Header: Liquid Glass Task Counter & Layout Switcher
            topGlassHeader
                .padding(.horizontal, DS.Space.md)
                .padding(.vertical, 8)

            Divider()
                .opacity(0.4)

            // Quick Add Input with Glass Container
            MacTodoQuickAdd()
                .padding(.horizontal, DS.Space.md)
                .padding(.vertical, 8)

            Divider()
                .opacity(0.4)

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

    // MARK: - Top Glass Header

    @Namespace private var layoutPillNamespace

    // MARK: - Top Apple Liquid Glass Header

    private var topGlassHeader: some View {
        HStack(spacing: DS.Space.sm) {
            // Task count chip in glass capsule
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 5, height: 5)

                Text("\(openItems.count) tasks open")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(Color.white)

                if !doneItems.isEmpty {
                    Text("• \(doneItems.count) done")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.09))
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color.white.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.75
                    )
            )

            Spacer()

            // Apple Music / VisionOS Style Layout Switcher Capsule
            HStack(spacing: 2) {
                ForEach(ListDesignVariant.allCases) { variant in
                    let isSelected = selectedVariant == variant
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                            selectedVariant = variant
                        }
                    } label: {
                        Image(systemName: variant.icon)
                            .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.60))
                            .frame(width: 26, height: 22)
                            .contentShape(Capsule())
                            .background {
                                if isSelected {
                                    ZStack {
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color.white.opacity(0.28),
                                                        Color.white.opacity(0.18)
                                                    ],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )

                                        Capsule()
                                            .stroke(
                                                LinearGradient(
                                                    stops: [
                                                        .init(color: Color.white.opacity(0.55), location: 0.0),
                                                        .init(color: Color.cyan.opacity(0.15), location: 0.3),
                                                        .init(color: Color.purple.opacity(0.12), location: 0.6),
                                                        .init(color: Color.white.opacity(0.10), location: 1.0)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 0.85
                                            )
                                    }
                                    .shadow(color: Color.black.opacity(0.22), radius: 3, x: 0, y: 1)
                                    .matchedGeometryEffect(id: "activeLayoutGlassPill", in: layoutPillNamespace)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .help(variant.rawValue)
                }
            }
            .padding(2.5)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.09))
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color.white.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.75
                    )
            )
        }
    }
}

// MARK: - Design 1: List1BentoCardsView (Liquid Glass Bento Cards)

private struct List1BentoCardsView: View {

    @Environment(\.modelContext) private var modelContext
    let items: [TodoItem]
    let doneItems: [TodoItem]
    @Binding var selection: TodoItem?
    @Binding var showCompleted: Bool

    var body: some View {
        VStack(spacing: 7) {
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
            HStack(spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { showCompleted.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                        Text(showCompleted ? "Hide completed" : "\(doneItems.count) completed tasks")
                            .font(DS.Text.caption)
                    }
                    .foregroundStyle(DS.Color.textTertiary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    for item in doneItems {
                        item.archivedAt = Date()
                    }
                    try? modelContext.save()
                    PlutoSoundEngine.shared.play(.deleteTrash)
                    Haptics.impact(.medium)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 9))
                        Text("Clear Completed")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(Color.red.opacity(0.85))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .help("Delete all completed tasks")
            }
            .padding(.vertical, 4)

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

// MARK: - List1CardRow (Liquid Glass Card)

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
    private var catColor: Color { item.categoryColor }

    var body: some View {
        HStack(spacing: 10) {

            // Checkbox with glass styling
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
                            PlutoSoundEngine.shared.play(.completePop)
                            PlutoTelemetryEngine.shared.trackTaskCompleted(task: item)
                        }
                    }
                    Haptics.impact(.light)
                }
            )

            // Category Icon Bubble
            Image(systemName: item.iconName ?? "checklist")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : catColor)
                .frame(width: 22, height: 22)
                .background(catColor.opacity(0.12), in: Circle())

            // Title & Metadata
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                    .strikethrough(item.isCompleted, color: DS.Color.textTertiary)
                    .lineLimit(1)

                // Metadata Pill Row
                if item.dueDate != nil || !subtasks.isEmpty || item.startTime != nil {
                    HStack(spacing: 6) {
                        if let due = item.dueDate {
                            HStack(spacing: 3) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 8))
                                Text(due, style: .date)
                            }
                            .font(.system(size: 9.5))
                            .foregroundStyle(isOverdue(due) && !item.isCompleted ? Color.red : DS.Color.textTertiary)
                        }

                        if !subtasks.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 8))
                                Text("\(completedSubtaskCount)/\(subtasks.count)")
                            }
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(catColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(catColor.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }

            Spacer()

            // Delete Trash Button on Hover
            if item.isCompleted || isHovered {
                Button {
                    item.archivedAt = Date()
                    try? modelContext.save()
                    PlutoSoundEngine.shared.play(.deleteTrash)
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(item.isCompleted ? Color.red.opacity(0.8) : DS.Color.textTertiary)
                }
                .buttonStyle(.plain)
                .help("Delete task")
                .transition(.scale.combined(with: .opacity))
            }

            // Priority Indicator Pill
            if item.priority > 0 {
                priorityPill(item.priority)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color.accentColor.opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(
                                    LinearGradient(
                                        colors: [isHovered ? catColor.opacity(0.35) : .white.opacity(0.18), .white.opacity(0.04)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 0.8
                                )
                        )
                }
            }
        )
        .offset(y: isHovered ? -1.5 : 0)
        .shadow(color: isHovered ? Color.black.opacity(0.16) : Color.black.opacity(0.04), radius: isHovered ? 6 : 2, x: 0, y: isHovered ? 3 : 1)
        .animation(.spring(response: 0.22, dampingFraction: 0.8), value: isHovered)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private func priorityPill(_ p: Int) -> some View {
        let (label, color) = priorityInfo(p)
        return Text(label)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 0.6))
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

// MARK: - Design 2: List2GroupedSectionsView (Liquid Glass Grouped Sections)

private struct List2GroupedSectionsView: View {

    let items: [TodoItem]
    let doneItems: [TodoItem]
    @Binding var selection: TodoItem?
    @Binding var showCompleted: Bool

    private var highPriority: [TodoItem] { items.filter { $0.priority == 3 } }
    private var medPriority:  [TodoItem] { items.filter { $0.priority == 2 } }
    private var lowPriority:  [TodoItem] { items.filter { $0.priority <= 1 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            if !highPriority.isEmpty {
                glassPriorityGroup(title: "HIGH PRIORITY", icon: "flame.fill", color: .red, tasks: highPriority)
            }

            if !medPriority.isEmpty {
                glassPriorityGroup(title: "MEDIUM PRIORITY", icon: "bolt.fill", color: .orange, tasks: medPriority)
            }

            if !lowPriority.isEmpty {
                glassPriorityGroup(title: "STANDARD & INBOX", icon: "tray.full.fill", color: Color.accentColor, tasks: lowPriority)
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
                    }
                    .foregroundStyle(DS.Color.textTertiary)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                if showCompleted {
                    VStack(spacing: 6) {
                        ForEach(doneItems, id: \.id) { item in
                            List1CardRow(item: item, isSelected: selection?.id == item.id) {
                                selection = item
                            }
                        }
                    }
                }
            }
        }
    }

    private func glassPriorityGroup(title: String, icon: String, color: Color, tasks: [TodoItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)

                Spacer()

                Text("\(tasks.count)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(color.opacity(0.12), in: Capsule())
            }
            .padding(.horizontal, 2)

            VStack(spacing: 6) {
                ForEach(tasks, id: \.id) { item in
                    List1CardRow(item: item, isSelected: selection?.id == item.id) {
                        selection = item
                    }
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 13))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(LinearGradient(colors: [color.opacity(0.25), .white.opacity(0.04)], startPoint: .top, endPoint: .bottom), lineWidth: 0.8)
        )
    }
}

// MARK: - Design 3: List3FocusCardsView (Liquid Glass Focus Horizon Cards)

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
                                    PlutoSoundEngine.shared.play(.completePop)
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
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color.accentColor.opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(LinearGradient(colors: [.white.opacity(0.18), .white.opacity(0.04)], startPoint: .top, endPoint: .bottom), lineWidth: 0.8)
                        )
                }
            }
        )
        .offset(y: isHovered ? -1.5 : 0)
        .shadow(color: isHovered ? Color.black.opacity(0.16) : Color.black.opacity(0.04), radius: isHovered ? 6 : 2, x: 0, y: isHovered ? 3 : 1)
        .animation(.spring(response: 0.22, dampingFraction: 0.8), value: isHovered)
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
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
