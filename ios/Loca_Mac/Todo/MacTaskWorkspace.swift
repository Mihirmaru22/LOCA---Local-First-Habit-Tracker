import SwiftUI
import SwiftData
import AppKit

// MARK: - TaskWorkspaceLayout

enum TaskWorkspaceLayout: String, CaseIterable, Identifiable {
    case linearSplit = "Workspace 1 · Linear Split"
    case thingsDoc   = "Workspace 2 · Things 3 Document"
    case bentoMatrix = "Workspace 3 · Bento Matrix"

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .linearSplit: return "Linear Split"
        case .thingsDoc:   return "Things 3 Document"
        case .bentoMatrix: return "Bento Matrix"
        }
    }

    var icon: String {
        switch self {
        case .linearSplit: return "rectangle.split.2x1"
        case .thingsDoc:   return "doc.text"
        case .bentoMatrix: return "square.grid.2x2"
        }
    }
}

// MARK: - MacTaskWorkspace

struct MacTaskWorkspace: View {
    @Bindable var item: TodoItem
    let onClose: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [TodoItem]

    @AppStorage("mac_task_workspace_layout_v2") private var selectedLayout: TaskWorkspaceLayout = .linearSplit

    @State private var activeBlockID: UUID? = nil
    
    // Bottom toolbar popovers
    @State private var showCategorySelector = false
    @State private var showComments = false
    @State private var showFormatting = false
    @State private var showDeleteConfirm = false
    
    // Header popover
    @State private var showDatePicker = false
    
    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            navBar
            Divider()

            switch selectedLayout {
            case .linearSplit:
                Workspace1LinearSplitView(
                    item: item,
                    allItems: allItems,
                    onSave: save,
                    onDelete: { showDeleteConfirm = true }
                )
            case .thingsDoc:
                Workspace2ThingsDocView(
                    item: item,
                    allItems: allItems,
                    onSave: save,
                    onDelete: { showDeleteConfirm = true }
                )
            case .bentoMatrix:
                Workspace3BentoMatrixView(
                    item: item,
                    allItems: allItems,
                    onSave: save,
                    onDelete: { showDeleteConfirm = true }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.background)
        .onAppear { migrateSubtasks() }
        .confirmationDialog(
            "Delete \"\(item.title.isEmpty ? "Untitled" : item.title)\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                item.archiveCascade(in: modelContext)
                save()
                onClose()
            }
            Button("Cancel", role: .cancel) {}
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

    // MARK: - Header Controls
    
    private var headerControls: some View {
        HStack(spacing: DS.Space.sm) {
            Button {
                withAnimation(DS.Motion.settle) {
                    item.completedAt = item.isCompleted ? nil : Date()
                }
                save()
                if item.isCompleted {
                    PlutoTelemetryEngine.shared.trackTaskCompleted(task: item)
                }
                Haptics.impact(.light)
            } label: {
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
                .background(RoundedRectangle(cornerRadius: DS.Radius.control).fill(item.dueDate != nil ? Color.accentColor.opacity(0.12) : .clear))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.control).stroke(DS.Color.border.opacity(item.dueDate != nil ? 0 : 0.6), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
                CompactDueDatePicker(item: item, onClose: { showDatePicker = false })
            }
            
            Spacer()
            
            Menu {
                Button { item.priority = 0; save() } label: { Label("None", systemImage: item.priority == 0 ? "checkmark" : "flag.slash") }
                Divider()
                Button { item.priority = 1; save() } label: { Label("Low", systemImage: item.priority == 1 ? "checkmark" : "flag.fill") }
                Button { item.priority = 2; save() } label: { Label("Medium", systemImage: item.priority == 2 ? "checkmark" : "flag.fill") }
                Button { item.priority = 3; save() } label: { Label("High", systemImage: item.priority == 3 ? "checkmark" : "flag.fill") }
            } label: {
                HStack(spacing: DS.Space.xs) {
                    Image(systemName: item.priority > 0 ? "flag.fill" : "flag")
                        .font(.caption)
                    Text(item.priority > 0 ? ["None", "Low", "Medium", "High"][min(item.priority, 3)] : "Priority")
                        .font(DS.Text.body)
                }
                .foregroundStyle(item.priority > 0 ? [Color.gray, Color.green, Color.orange, Color.red][min(item.priority, 3)] : DS.Color.textSecondary)
                .padding(.horizontal, DS.Space.sm)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: DS.Radius.control).fill(item.priority > 0 ? [Color.gray, Color.green, Color.orange, Color.red][min(item.priority, 3)].opacity(0.14) : .clear))
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.control).stroke(DS.Color.border.opacity(item.priority > 0 ? 0 : 0.6), lineWidth: 1))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }

    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        HStack(spacing: DS.Space.md) {
            Button { showCategorySelector.toggle() } label: {
                HStack(spacing: 4) {
                    Image(systemName: categoryIcon(for: item.category ?? "Inbox"))
                    Text(item.category ?? "Inbox")
                }
                .font(DS.Text.caption)
                .foregroundStyle(DS.Color.textSecondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showCategorySelector, arrowEdge: .top) {
                MacCategorySelector(selectedCategory: item.category ?? "Inbox") { newCategory in
                    item.category = newCategory
                    save()
                    showCategorySelector = false
                }
            }
            
            Spacer()
            
            Button {
                showFormatting.toggle()
            } label: {
                Image(systemName: "textformat")
            }
            .buttonStyle(.plain)
            .foregroundStyle(DS.Color.textSecondary)
            .popover(isPresented: $showFormatting, arrowEdge: .top) {
                MacFormattingMenu { type in
                    if let id = activeBlockID {
                        NotificationCenter.default.post(name: NSNotification.Name("FormatBlock"), object: nil, userInfo: ["id": id, "type": type])
                    } else {
                        // Focus empty block or create one
                        NotificationCenter.default.post(name: NSNotification.Name("FocusOrCreateBlock"), object: nil, userInfo: ["type": type])
                    }
                    showFormatting = false
                }
            }
            
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showComments.toggle()
                }
            } label: {
                Image(systemName: "bubble.right")
                    .overlay(
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: -8)
                            .opacity((item.comments?.isEmpty ?? true) ? 0 : 1)
                    )
            }
            .buttonStyle(.plain)
            .foregroundStyle(DS.Color.textSecondary)
            
            Menu {
                Button { NotificationCenter.default.post(name: NSNotification.Name("FocusOrCreateBlock"), object: nil, userInfo: ["type": TodoBlockType.subtask]) } label: { Label("Add Subtask", systemImage: "plus") }
                Divider()
                Button { } label: { Label("Pin", systemImage: "pin") }
                Button { } label: { Label("Tags...", systemImage: "tag") }
                Divider()
                Button(role: .destructive) { showDeleteConfirm = true } label: { Label("Delete", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .foregroundStyle(DS.Color.textSecondary)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.surface.opacity(0.85))
        .overlay(Rectangle().frame(height: 1).foregroundStyle(DS.Color.separator), alignment: .top)
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Inbox": return "tray"
        case "Daily": return "sun.max"
        case "Welcome": return "hand.wave"
        case "Work": return "briefcase"
        case "Personal": return "house"
        case "Learning": return "book"
        case "Fitness": return "figure.run"
        default: return "folder"
        }
    }
    
    // MARK: - Migration
    
    private func migrateSubtasks() {
        let children = allItems.filter { $0.parentID == item.id && !$0.isArchived }.sorted { $0.createdAt < $1.createdAt }
        var currentBlocks = item.contentBlocks ?? []
        var changed = false
        
        for child in children {
            if !currentBlocks.contains(where: { $0.type == .subtask && $0.refID == child.id }) {
                let block = TodoContentBlock(type: .subtask, text: "", refID: child.id)
                currentBlocks.append(block)
                changed = true
            }
        }
        
        if currentBlocks.isEmpty {
            currentBlocks.append(TodoContentBlock(type: .paragraph))
            changed = true
        }
        
        if changed {
            item.contentBlocks = currentBlocks
            save()
        }
    }
    
    private func save() {
        try? modelContext.save()
    }
}

// MARK: - MacBlockEditor

struct MacBlockEditor: View {
    @Bindable var item: TodoItem
    @Binding var activeBlockID: UUID?
    var allItems: [TodoItem]
    let onSave: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    
    @State private var blocks: [TodoContentBlock] = []
    @State private var localChildren: [UUID: TodoItem] = [:]
    @State private var isInitializing = true
    @State private var saveTask: DispatchWorkItem?
    
    // Slash Menu State
    @State private var showSlashMenu = false
    @State private var slashQuery = ""
    @State private var slashMenuSelectedIndex = 0
    @State private var menuAnchor: NSRect = .zero
    @State private var activeSlashBlockID: UUID? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(blocks) { block in
                    MacBlockRow(
                        block: Binding(
                            get: { block },
                            set: { val in
                                if let idx = blocks.firstIndex(where: { $0.id == block.id }) {
                                    blocks[idx] = val
                                }
                            }
                        ),
                        isActive: activeBlockID == block.id,
                        listIndex: computeListIndex(for: block),
                        onFocus: { activeBlockID = block.id },
                        onEnter: { tail in handleEnter(from: block.id, splitText: tail) },
                        onBackspace: { handleBackspace(from: block.id) },
                        onTab: { handleTab(from: block.id) },
                        onBacktab: { handleBacktab(from: block.id) },
                        onUpArrow: { handleUpArrow(from: block.id) },
                        onDownArrow: { handleDownArrow(from: block.id) },
                        
                        // Slash Command hooks
                        isSlashMenuOpen: activeSlashBlockID == block.id,
                        slashQuery: slashQuery,
                        slashMenuSelectedIndex: slashMenuSelectedIndex,
                        menuAnchor: menuAnchor,
                        
                        onSlash: { rect in openSlashMenu(for: block.id, at: rect) },
                        onSlashQuery: { q in 
                            slashQuery = q 
                            let items = SlashCommandItem.all.filter { slashQuery.isEmpty || $0.name.localizedCaseInsensitiveContains(slashQuery) }
                            let maxIndex = max(0, items.count - 1)
                            if slashMenuSelectedIndex > maxIndex { slashMenuSelectedIndex = maxIndex }
                        },
                        onSlashClose: { closeSlashMenu() },
                        onSlashNavigate: { delta in navigateSlashMenu(delta) },
                        onSlashEnter: { type in executeSlashCommand(type) },
                        
                        // Subtask data
                        childItem: childTodo(for: block),
                        onSave: onSave
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { 
            initializeBlocks()
            DispatchQueue.main.async { isInitializing = false }
        }
        .onChange(of: item.id) { _, _ in
            isInitializing = true
            initializeBlocks()
            DispatchQueue.main.async { isInitializing = false }
        }
        .onChange(of: blocks) { _, newBlocks in 
            if !isInitializing {
                saveTask?.cancel()
                let task = DispatchWorkItem {
                    item.contentBlocks = newBlocks
                    onSave()
                }
                saveTask = task
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FormatBlock"))) { output in
            guard let userInfo = output.userInfo,
                  let id = userInfo["id"] as? UUID,
                  let type = userInfo["type"] as? TodoBlockType,
                  let idx = blocks.firstIndex(where: { $0.id == id }) else { return }
            
            if blocks[idx].type == .subtask && type != .subtask {
                if let ref = blocks[idx].refID, let child = localChildren[ref] ?? allItems.first(where: { $0.id == ref }) {
                    child.archivedAt = Date()
                }
                blocks[idx].refID = nil
            }
            
            blocks[idx].type = type
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusOrCreateBlock"))) { output in
            let type = (output.userInfo?["type"] as? TodoBlockType) ?? .paragraph
            if let last = blocks.last {
                if !last.text.isEmpty {
                    var newBlock = TodoContentBlock(type: type)
                    if type == .subtask {
                        let child = TodoItem(parentID: item.id)
                        modelContext.insert(child)
                        localChildren[child.id] = child
                        newBlock.refID = child.id
                    }
                    blocks.append(newBlock)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { activeBlockID = newBlock.id }
                } else {
                    if type == .subtask {
                        let child = TodoItem(parentID: item.id)
                        modelContext.insert(child)
                        localChildren[child.id] = child
                        blocks[blocks.count - 1].type = .subtask
                        blocks[blocks.count - 1].refID = child.id
                    }
                    activeBlockID = last.id
                }
            } else {
                var newBlock = TodoContentBlock(type: type)
                if type == .subtask {
                    let child = TodoItem(parentID: item.id)
                    modelContext.insert(child)
                    localChildren[child.id] = child
                    newBlock.refID = child.id
                }
                blocks = [newBlock]
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { activeBlockID = newBlock.id }
            }
        }
    }
    
    private func childTodo(for block: TodoContentBlock) -> TodoItem? {
        guard block.type == .subtask, let ref = block.refID else { return nil }
        return localChildren[ref] ?? allItems.first(where: { $0.id == ref })
    }
    
    private func computeListIndex(for block: TodoContentBlock) -> Int? {
        guard block.type == .numbered else { return nil }
        var count = 0
        for b in blocks {
            if b.type == .numbered { count += 1 }
            if b.id == block.id { return count }
        }
        return nil
    }
    
    private func initializeBlocks() {
        if let cb = item.contentBlocks, !cb.isEmpty {
            blocks = cb
        } else if let notes = item.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let lines = notes.components(separatedBy: .newlines)
            blocks = lines.map { TodoContentBlock(type: .paragraph, text: $0) }
        } else {
            blocks = [TodoContentBlock(type: .paragraph)]
        }
    }
    
    // MARK: Editing Logic
    
    private func handleEnter(from id: UUID, splitText: String = "") {
        guard let idx = blocks.firstIndex(where: { $0.id == id }) else { return }
        let currentBlock = blocks[idx]
        
        // Exit list if empty
        let isEmpty: Bool
        if currentBlock.type == .subtask {
            isEmpty = childTodo(for: currentBlock)?.title.isEmpty ?? true
        } else {
            isEmpty = currentBlock.text.isEmpty
        }
        
        if (currentBlock.type == .bullet || currentBlock.type == .numbered || currentBlock.type == .check || currentBlock.type == .subtask) && isEmpty {
            // Revert empty list item to plain paragraph
            if currentBlock.type == .subtask, let child = childTodo(for: currentBlock) {
                child.archivedAt = Date()
                try? modelContext.save()
            }
            blocks[idx].type = .paragraph
            blocks[idx].refID = nil
            blocks[idx].text = ""
            activeBlockID = blocks[idx].id
            return
        }
        
        var nextType: TodoBlockType = .paragraph
        if currentBlock.type == .bullet { nextType = .bullet }
        if currentBlock.type == .numbered { nextType = .numbered }
        if currentBlock.type == .check { nextType = .check }
        if currentBlock.type == .subtask { nextType = .subtask }
        
        var newBlock = TodoContentBlock(type: nextType)
        
        if nextType == .subtask {
            let child = TodoItem(parentID: item.id)
            child.title = splitText
            modelContext.insert(child)
            try? modelContext.save()
            localChildren[child.id] = child
            newBlock.refID = child.id
            newBlock.text = ""
        } else {
            newBlock.text = splitText
        }
        
        blocks.insert(newBlock, at: idx + 1)
        activeBlockID = newBlock.id
    }
    
    private func handleBackspace(from id: UUID) {
        guard let idx = blocks.firstIndex(where: { $0.id == id }) else { return }
        let block = blocks[idx]
        
        // For subtask blocks, check child title; for others, check block.text
        let isEmpty: Bool
        if block.type == .subtask {
            isEmpty = childTodo(for: block)?.title.isEmpty ?? true
        } else {
            isEmpty = block.text.isEmpty
        }
        
        if isEmpty {
            if block.type != .paragraph {
                // Revert to plain paragraph and strip prefix symbol
                if block.type == .subtask, let child = childTodo(for: block) {
                    child.archivedAt = Date()
                    try? modelContext.save()
                }
                blocks[idx].type = .paragraph
                blocks[idx].refID = nil
                blocks[idx].text = ""
                activeBlockID = blocks[idx].id
            } else if blocks.count > 1 {
                blocks.remove(at: idx)
                if idx > 0 { activeBlockID = blocks[idx - 1].id }
                else { activeBlockID = blocks[0].id }
            }
        }
    }
    
    private func handleTab(from id: UUID) {
        guard let idx = blocks.firstIndex(where: { $0.id == id }) else { return }
        if blocks[idx].type == .check || blocks[idx].type == .bullet || blocks[idx].type == .paragraph {
            let child = TodoItem(parentID: item.id)
            child.title = blocks[idx].text
            modelContext.insert(child)
            try? modelContext.save()
            localChildren[child.id] = child
            blocks[idx].type = .subtask
            blocks[idx].refID = child.id
            blocks[idx].text = ""
        }
    }
    
    private func handleBacktab(from id: UUID) {
        guard let idx = blocks.firstIndex(where: { $0.id == id }) else { return }
        if blocks[idx].type == .subtask {
            if let child = childTodo(for: blocks[idx]) {
                blocks[idx].text = child.title
                child.archivedAt = Date()
                try? modelContext.save()
            }
            blocks[idx].type = .paragraph
            blocks[idx].refID = nil
        }
    }
    
    private func handleUpArrow(from id: UUID) {
        guard let idx = blocks.firstIndex(where: { $0.id == id }), idx > 0 else { return }
        activeBlockID = blocks[idx - 1].id
    }
    
    private func handleDownArrow(from id: UUID) {
        guard let idx = blocks.firstIndex(where: { $0.id == id }), idx < blocks.count - 1 else { return }
        activeBlockID = blocks[idx + 1].id
    }
    
    // MARK: Slash Command Logic
    
    private func openSlashMenu(for id: UUID, at rect: NSRect) {
        activeSlashBlockID = id
        menuAnchor = rect
        slashMenuSelectedIndex = 0
        showSlashMenu = true
    }
    
    private func navigateSlashMenu(_ delta: Int) {
        let items = SlashCommandItem.all.filter { slashQuery.isEmpty || $0.name.localizedCaseInsensitiveContains(slashQuery) }
        let maxIndex = max(0, items.count - 1)
        var newIndex = slashMenuSelectedIndex + delta
        if newIndex < 0 { newIndex = maxIndex }
        if newIndex > maxIndex { newIndex = 0 }
        slashMenuSelectedIndex = newIndex
    }
    
    private func closeSlashMenu() {
        showSlashMenu = false
        activeSlashBlockID = nil
        slashQuery = ""
        slashMenuSelectedIndex = 0
    }
    
    private func executeSlashCommand(_ forcedType: TodoBlockType? = nil) {
        let items = SlashCommandItem.all.filter { slashQuery.isEmpty || $0.name.localizedCaseInsensitiveContains(slashQuery) }
        let maxIndex = max(0, items.count - 1)
        guard slashMenuSelectedIndex <= maxIndex else { return }
        
        let type = forcedType ?? items[slashMenuSelectedIndex].type
        
        guard let id = activeSlashBlockID,
              let idx = blocks.firstIndex(where: { $0.id == id }) else { return }
        
        // Strip slash + query text first, before any type conversion
        var textBeforeSlash = blocks[idx].text
        if let slashIdx = textBeforeSlash.lastIndex(of: "/") {
            textBeforeSlash = String(textBeforeSlash[..<slashIdx])
        }
        blocks[idx].text = textBeforeSlash
        blocks[idx].type = type
        
        if type == .subtask {
            let child = TodoItem(parentID: item.id)
            child.title = textBeforeSlash.trimmingCharacters(in: .whitespaces)
            modelContext.insert(child)
            localChildren[child.id] = child
            blocks[idx].refID = child.id
            blocks[idx].text = "" // clear so it binds to child.title
        } else if type == .divider {
            blocks[idx].text = ""
            let nextBlock = TodoContentBlock(type: .paragraph)
            blocks.insert(nextBlock, at: idx + 1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { activeBlockID = nextBlock.id }
        }
        
        closeSlashMenu()
        onSave()
        // Focus stays on block naturally
    }
}

// MARK: - MacBlockRow

struct MacBlockRow: View {
    @Binding var block: TodoContentBlock
    let isActive: Bool
    let listIndex: Int?
    let onFocus: () -> Void
    let onEnter: (String) -> Void
    let onBackspace: () -> Void
    let onTab: () -> Void
    let onBacktab: () -> Void
    let onUpArrow: () -> Void
    let onDownArrow: () -> Void
    
    let isSlashMenuOpen: Bool
    let slashQuery: String
    let slashMenuSelectedIndex: Int
    let menuAnchor: NSRect
    let onSlash: (NSRect) -> Void
    let onSlashQuery: (String) -> Void
    let onSlashClose: () -> Void
    let onSlashNavigate: (Int) -> Void
    let onSlashEnter: (TodoBlockType?) -> Void
    
    var childItem: TodoItem?
    let onSave: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Handle
            Image(systemName: "circle.grid.2x2.fill")
                .font(.system(size: 10))
                .foregroundStyle(DS.Color.textTertiary)
                .opacity(isHovered ? 1 : 0)
                .padding(.top, 6)
                .help("Right-click to delete")
                .frame(width: 16)
                .contextMenu {
                    Button(role: .destructive) { onBackspace() } label: { Label("Delete Block", systemImage: "trash") }
                }
            
            // Content
            if block.type == .divider {
                Rectangle()
                    .fill(DS.Color.separator)
                    .frame(height: 1)
                    .padding(.vertical, 8)
            } else {
                prefixView
                
                // Rich Text View
                MacRichTextView(
                    text: Binding(
                        get: { childItem != nil ? childItem!.title : block.text },
                        set: { val in
                            if let child = childItem {
                                child.title = val
                                onSave()
                            } else {
                                block.text = val
                            }
                        }
                    ),
                    placeholder: placeholderText,
                    font: fontForType,
                    isStrikethrough: isCompletedState,
                    textColor: isCompletedState ? NSColor.secondaryLabelColor : NSColor.labelColor,
                    isActive: isActive,
                    onFocus: onFocus,
                    onEnter: onEnter,
                    onBackspaceOnEmpty: onBackspace,
                    onTab: onTab,
                    onBacktab: onBacktab,
                    onUpArrow: onUpArrow,
                    onDownArrow: onDownArrow,
                    onSlash: onSlash,
                    onSlashQuery: onSlashQuery,
                    onSlashClose: onSlashClose,
                    onSlashNavigate: onSlashNavigate,
                    onSlashEnter: { onSlashEnter(nil) },
                    isSlashMenuOpen: isSlashMenuOpen
                )
                .frame(minHeight: 24)
                .popover(
                    isPresented: Binding(
                        get: { isSlashMenuOpen },
                        set: { if !$0 { onSlashClose() } }
                    ),
                    arrowEdge: .bottom
                ) {
                    SlashCommandMenu(
                        query: slashQuery,
                        selectedIndex: slashMenuSelectedIndex,
                        onSelect: { type in onSlashEnter(type) },
                        onClose: onSlashClose
                    )
                }
            }
        }
        .onHover { isHovered = $0 }
    }
    
    private var isCompletedState: Bool {
        if block.type == .subtask {
            if let child = childItem { return child.isCompleted }
            return block.isCompleted
        }
        if block.type == .check { return block.isCompleted }
        return false
    }
    
    @ViewBuilder
    private var prefixView: some View {
        switch block.type {
        case .bullet:
            Text("•")
                .font(Font(fontForType))
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: 16, alignment: .center)
                .padding(.top, 1)
        case .numbered:
            Text("\(listIndex ?? 1).")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Color.textSecondary)
                .frame(minWidth: 16, alignment: .trailing)
                .padding(.top, 2)
        case .check:
            Button {
                withAnimation(DS.Motion.settle) {
                    block.isCompleted.toggle()
                }
                onSave()
                Haptics.impact(.light)
            } label: {
                Image(systemName: block.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 14))
                    .foregroundStyle(block.isCompleted ? Color.accentColor : DS.Color.textTertiary)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        case .subtask:
            Button {
                withAnimation(DS.Motion.settle) {
                    if let child = childItem {
                        child.completedAt = child.isCompleted ? nil : Date()
                        block.isCompleted = child.isCompleted
                    } else {
                        block.isCompleted.toggle()
                    }
                }
                onSave()
                Haptics.impact(.light)
            } label: {
                Image(systemName: isCompletedState ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(isCompletedState ? Color.accentColor : DS.Color.textTertiary)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        case .quote:
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 3)
                .padding(.vertical, 2)
        case .attachment, .tag, .link:
            Image(systemName: "paperclip")
                .font(.caption)
                .foregroundStyle(DS.Color.textTertiary)
                .padding(.top, 2)
        default:
            EmptyView()
        }
    }
    
    private var fontForType: NSFont {
        switch block.type {
        case .h1: return NSFont.systemFont(ofSize: 22, weight: .bold)
        case .h2: return NSFont.systemFont(ofSize: 18, weight: .semibold)
        case .h3: return NSFont.systemFont(ofSize: 15, weight: .semibold)
        case .quote: return NSFont.systemFont(ofSize: 14)
        default: return NSFont.systemFont(ofSize: 14)
        }
    }
    
    private var placeholderText: String {
        switch block.type {
        case .h1: return "Heading 1"
        case .h2: return "Heading 2"
        case .h3: return "Heading 3"
        case .quote: return "Quote…"
        case .check: return "To-do…"
        case .subtask: return "Add subtask…"
        case .bullet, .numbered: return "List item…"
        default: return "Type / for commands"
        }
    }
}

// MARK: - MacRichTextView

struct MacRichTextView: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var font: NSFont
    var isStrikethrough: Bool
    var textColor: NSColor
    
    var isActive: Bool
    var onFocus: () -> Void
    var onEnter: (String) -> Void
    var onBackspaceOnEmpty: () -> Void
    var onTab: () -> Void
    var onBacktab: () -> Void
    var onUpArrow: () -> Void
    var onDownArrow: () -> Void
    
    var onSlash: (NSRect) -> Void
    var onSlashQuery: (String) -> Void
    var onSlashClose: () -> Void
    var onSlashNavigate: (Int) -> Void
    var onSlashEnter: () -> Void
    var isSlashMenuOpen: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> AutoSizingTextView {
        let textView = AutoSizingTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.drawsBackground = false
        textView.font = font
        textView.textColor = textColor
        textView.textContainerInset = NSSize(width: 0, height: 2)
        textView.textContainer?.lineFragmentPadding = 0
        textView.allowsUndo = true
        return textView
    }

    func updateNSView(_ nsView: AutoSizingTextView, context: Context) {
        context.coordinator.parent = self
        
        let isFirstResponder = nsView.window?.firstResponder == nsView
        if nsView.string != text {
            if !isFirstResponder || text.count < nsView.string.count || !nsView.string.hasPrefix(text) {
                let savedSelectedRange = nsView.selectedRange()
                nsView.string = text
                let newPos = min(text.count, savedSelectedRange.location)
                nsView.setSelectedRange(NSRange(location: newPos, length: 0))
            }
        }
        
        nsView.placeholderString = placeholder
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .strikethroughStyle: isStrikethrough ? NSUnderlineStyle.single.rawValue : 0,
            .strikethroughColor: textColor
        ]
        
        if nsView.string.count > 0 {
            nsView.textStorage?.setAttributes(attributes, range: NSRange(location: 0, length: nsView.string.count))
        }
        
        if isActive && !context.coordinator.wasActive {
            DispatchQueue.main.async {
                if let window = nsView.window, window.firstResponder != nsView {
                    window.makeFirstResponder(nsView)
                    nsView.setSelectedRange(NSRange(location: nsView.string.count, length: 0))
                }
            }
        }
        context.coordinator.wasActive = isActive
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacRichTextView
        var slashQueryRange: NSRange?
        var wasActive: Bool = false

        init(_ parent: MacRichTextView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            
            let text = textView.string
            let selectedRange = textView.selectedRange()
            
            if parent.isSlashMenuOpen, let slashRange = slashQueryRange {
                if selectedRange.location >= slashRange.location {
                    let nsString = text as NSString
                    let queryLen = selectedRange.location - slashRange.location
                    if queryLen >= 0 && (slashRange.location + queryLen) <= nsString.length {
                        let query = nsString.substring(with: NSRange(location: slashRange.location, length: queryLen))
                        if !query.contains(" ") && !query.contains("\n") {
                            parent.onSlashQuery(query)
                            return
                        }
                    }
                }
                parent.onSlashClose()
                slashQueryRange = nil
            }
        }

        func textViewDidBeginEditing(_ notification: Notification) {
            parent.onFocus()
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if parent.isSlashMenuOpen {
                if commandSelector == #selector(NSResponder.moveUp(_:)) { parent.onSlashNavigate(-1); return true }
                if commandSelector == #selector(NSResponder.moveDown(_:)) { parent.onSlashNavigate(1); return true }
                if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                    var str = textView.string
                    if let slashIdx = str.lastIndex(of: "/") {
                        str = String(str[..<slashIdx])
                    }
                    textView.string = str
                    parent.text = str
                    parent.onSlashEnter()
                    slashQueryRange = nil
                    return true
                }
                if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                    parent.onSlashClose()
                    slashQueryRange = nil
                    return true
                }
            }
            
            if commandSelector == #selector(NSResponder.insertNewline(_:)) { 
                let range = textView.selectedRange()
                let nsString = textView.string as NSString
                let head = nsString.substring(to: range.location)
                let tail = nsString.substring(from: range.location)
                textView.string = head
                parent.text = head
                parent.onEnter(tail)
                return true 
            }
            if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
                if textView.string.isEmpty { parent.onBackspaceOnEmpty(); return true }
            }
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                parent.onTab()
                return true
            }
            if commandSelector == #selector(NSResponder.insertBacktab(_:)) {
                parent.onBacktab()
                return true
            }
            if commandSelector == #selector(NSResponder.moveUp(_:)) {
                let range = textView.selectedRange()
                let nsString = textView.string as NSString
                if nsString.lineRange(for: NSRange(location: range.location, length: 0)).location == 0 {
                    parent.onUpArrow()
                    return true
                }
            }
            if commandSelector == #selector(NSResponder.moveDown(_:)) {
                let range = textView.selectedRange()
                let nsString = textView.string as NSString
                if nsString.lineRange(for: NSRange(location: range.location, length: 0)).upperBound == nsString.length {
                    parent.onDownArrow()
                    return true
                }
            }
            return false
        }
        
        func textView(_ view: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            if replacementString == "/" {
                let nsString = view.string as NSString
                let isStart = affectedCharRange.location == 0
                let isAfterSpace = isStart ? false : CharacterSet.whitespacesAndNewlines.contains(UnicodeScalar(nsString.character(at: affectedCharRange.location - 1)) ?? UnicodeScalar(32))
                
                if isStart || isAfterSpace {
                    if let layoutManager = view.layoutManager, let textContainer = view.textContainer {
                        let rect = layoutManager.boundingRect(forGlyphRange: affectedCharRange, in: textContainer)
                        let viewRect = NSRect(x: rect.minX, y: rect.maxY, width: 0, height: 0)
                        slashQueryRange = NSRange(location: affectedCharRange.location + 1, length: 0)
                        parent.onSlash(viewRect)
                    }
                }
            }
            return true
        }
    }
}

class AutoSizingTextView: NSTextView {
    var placeholderString: String = "" { didSet { needsDisplay = true } }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let coordinator = delegate as? MacRichTextView.Coordinator, coordinator.parent.isActive {
            DispatchQueue.main.async {
                self.window?.makeFirstResponder(self)
                self.setSelectedRange(NSRange(location: self.string.count, length: 0))
            }
        }
    }
    
    override var intrinsicContentSize: NSSize {
        guard let layoutManager = layoutManager, let textContainer = textContainer else { return super.intrinsicContentSize }
        layoutManager.ensureLayout(for: textContainer)
        let rect = layoutManager.usedRect(for: textContainer)
        return NSSize(width: NSView.noIntrinsicMetric, height: max(22, rect.height + 4))
    }
    
    override func didChangeText() {
        super.didChangeText()
        invalidateIntrinsicContentSize()
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if string.isEmpty && !placeholderString.isEmpty {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font ?? NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.placeholderTextColor.withAlphaComponent(0.4)
            ]
            placeholderString.draw(at: NSPoint(x: textContainerInset.width, y: textContainerInset.height), withAttributes: attrs)
        }
    }
}

// MARK: - SlashCommandMenu

struct SlashCommandItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let type: TodoBlockType
    
    static let all: [SlashCommandItem] = [
        SlashCommandItem(name: "Heading 1", icon: "textformat.size.larger", type: .h1),
        SlashCommandItem(name: "Heading 2", icon: "textformat.size", type: .h2),
        SlashCommandItem(name: "Heading 3", icon: "textformat.size.smaller", type: .h3),
        SlashCommandItem(name: "Bulleted List", icon: "list.bullet", type: .bullet),
        SlashCommandItem(name: "Numbered List", icon: "list.number", type: .numbered),
        SlashCommandItem(name: "Check Item", icon: "checklist", type: .check),
        SlashCommandItem(name: "Quote", icon: "text.quote", type: .quote),
        SlashCommandItem(name: "Horizontal Line", icon: "line.horizontal.3", type: .divider),
        SlashCommandItem(name: "Subtask", icon: "text.badge.plus", type: .subtask),
        SlashCommandItem(name: "Attachment", icon: "paperclip", type: .attachment),
        SlashCommandItem(name: "Tag", icon: "tag", type: .tag),
        SlashCommandItem(name: "Link", icon: "link", type: .link)
    ]
}

struct SlashCommandMenu: View {
    var query: String
    var selectedIndex: Int
    var onSelect: (TodoBlockType) -> Void
    var onClose: () -> Void
    
    var filtered: [SlashCommandItem] {
        if query.isEmpty { return SlashCommandItem.all }
        return SlashCommandItem.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if filtered.isEmpty {
                Text("No commands").font(DS.Text.caption).padding()
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { index, cmd in
                            HStack {
                                Image(systemName: cmd.icon).frame(width: 20).foregroundStyle(DS.Color.textSecondary)
                                Text(cmd.name).font(DS.Text.body)
                                Spacer()
                            }
                            .padding(6)
                            .background(index == selectedIndex ? Color.accentColor.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                            .onTapGesture { onSelect(cmd.type) }
                        }
                    }
                    .padding(6)
                }
            }
        }
        .frame(width: 220, height: min(CGFloat(max(1, filtered.count) * 32 + 12), 240))
        .background(DS.Color.surface)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.Color.border, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

// MARK: - MacFormattingMenu

struct MacFormattingMenu: View {
    let onSelect: (TodoBlockType) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(SlashCommandItem.all.prefix(8)) { cmd in
                Button { onSelect(cmd.type) } label: {
                    HStack {
                        Image(systemName: cmd.icon).frame(width: 20)
                        Text(cmd.name)
                        Spacer()
                    }
                    .frame(width: 160)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
            }
        }
        .padding(8)
    }
}

// MARK: - MacCategorySelector

struct MacCategorySelector: View {
    var selectedCategory: String
    var onSelect: (String) -> Void
    @State private var query = ""
    
    let categories = ["Inbox", "Daily", "Welcome", "Work", "Personal", "Learning", "Fitness"]
    
    var filtered: [String] {
        if query.isEmpty { return categories }
        return categories.filter { $0.localizedCaseInsensitiveContains(query) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("Search", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(8)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(filtered, id: \.self) { cat in
                        Button { onSelect(cat) } label: {
                            HStack {
                                Text(cat)
                                Spacer()
                                if cat == selectedCategory {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(cat == selectedCategory ? Color.accentColor.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 200, height: 260)
    }
}

// MARK: - CompactDueDatePicker

struct CompactDueDatePicker: View {
    @Bindable var item: TodoItem
    let onClose: () -> Void
    @Environment(\.modelContext) private var modelContext
    
    private func saveAndClose() {
        try? modelContext.save()
        onClose()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Today") { item.dueDate = Calendar.current.startOfDay(for: .now); saveAndClose() }
                Button("Tomorrow") { item.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: .now); saveAndClose() }
                Button("+7 Days") { item.dueDate = Calendar.current.date(byAdding: .day, value: 7, to: .now); saveAndClose() }
            }
            .buttonStyle(.borderless)
            .padding(12)
            
            Divider()
            
            CustomMonthCalendar(selectedDate: Binding(
                get: { item.dueDate },
                set: { item.dueDate = $0; try? modelContext.save() }
            ))
            .padding(12)
            
            Divider()
            
            HStack {
                Button("Clear", role: .destructive) { item.dueDate = nil; saveAndClose() }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                Spacer()
                Button("OK") { saveAndClose() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(12)
        }
        .frame(width: 280)
    }
}

// MARK: - CustomMonthCalendar

struct CustomMonthCalendar: View {
    @Binding var selectedDate: Date?
    @State private var displayMonth: Date
    
    init(selectedDate: Binding<Date?>) {
        self._selectedDate = selectedDate
        self._displayMonth = State(initialValue: selectedDate.wrappedValue ?? .now)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(displayMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Color.textPrimary)
                Spacer()
                HStack(spacing: DS.Space.sm) {
                    Button { moveMonth(by: -1) } label: { Image(systemName: "chevron.left").font(.caption.bold()) }
                        .buttonStyle(.plain)
                        .foregroundStyle(DS.Color.textSecondary)
                    
                    Button { displayMonth = .now } label: { Image(systemName: "circle.fill").font(.caption2) }
                        .buttonStyle(.plain)
                        .foregroundStyle(DS.Color.textTertiary)
                    
                    Button { moveMonth(by: 1) } label: { Image(systemName: "chevron.right").font(.caption.bold()) }
                        .buttonStyle(.plain)
                        .foregroundStyle(DS.Color.textSecondary)
                }
            }
            .padding(.horizontal, 4)
            
            // Weekdays
            let weekdays = Calendar.current.veryShortWeekdaySymbols
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days Grid
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(days, id: \.date) { day in
                    CalendarDayCell(
                        day: day,
                        isSelected: selectedDate != nil && Calendar.current.isDate(day.date, inSameDayAs: selectedDate!),
                        isToday: Calendar.current.isDateInToday(day.date)
                    ) {
                        selectedDate = day.date
                    }
                }
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            if let d = newDate, !Calendar.current.isDate(d, equalTo: displayMonth, toGranularity: .month) {
                displayMonth = d
            }
        }
    }
    
    private func moveMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: displayMonth) {
            displayMonth = newDate
        }
    }
    
    struct DayItem {
        let date: Date
        let isPlaceholder: Bool
    }
    
    private func daysInMonth() -> [DayItem] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }
        
        var days: [DayItem] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate < monthInterval.start {
            days.append(DayItem(date: currentDate, isPlaceholder: true))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        while currentDate < monthInterval.end {
            days.append(DayItem(date: currentDate, isPlaceholder: false))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        // Add trailing placeholders to complete the grid (usually 6 rows total max = 42 days, but we just fill the last week)
        guard let lastDay = days.last?.date,
              let lastWeekInterval = calendar.dateInterval(of: .weekOfMonth, for: lastDay) else {
            return days
        }
        
        while currentDate < lastWeekInterval.end {
             days.append(DayItem(date: currentDate, isPlaceholder: true))
             currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
}

struct CalendarDayCell: View {
    let day: CustomMonthCalendar.DayItem
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            if !day.isPlaceholder { action() }
        }) {
            Text("\(Calendar.current.component(.day, from: day.date))")
                .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                .frame(maxWidth: .infinity, minHeight: 28)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.control)
                        .fill(isSelected ? Color.accentColor : (isHovered ? Color.primary.opacity(0.08) : Color.clear))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.control)
                        .stroke(isToday && !isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                )
                .foregroundStyle(
                    isSelected ? Color.white : 
                    (day.isPlaceholder ? DS.Color.textTertiary.opacity(0.6) : 
                    (isToday ? Color.accentColor : DS.Color.textPrimary))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - MacCommentsPanel

struct MacCommentsPanel: View {
    @Bindable var item: TodoItem
    let onClose: () -> Void
    
    @State private var newComment = ""
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack {
            HStack {
                Text("Comments").font(.headline)
                Spacer()
                Button(action: onClose) { Image(systemName: "xmark") }.buttonStyle(.plain)
            }
            .padding(16)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let comments = item.comments, !comments.isEmpty {
                        ForEach(comments) { comment in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(comment.createdAt.formatted(.dateTime.month().day().hour().minute()))
                                    .font(DS.Text.caption)
                                    .foregroundStyle(DS.Color.textTertiary)
                                Text(comment.text)
                                    .font(DS.Text.body)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 8))
                            .contextMenu {
                                Button(role: .destructive) {
                                    var currentComments = item.comments ?? []
                                    if let idx = currentComments.firstIndex(where: { $0.id == comment.id }) {
                                        currentComments.remove(at: idx)
                                        item.comments = currentComments
                                        try? modelContext.save()
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    } else {
                        Text("No comments yet.")
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textTertiary)
                            .padding()
                    }
                }
                .padding(16)
            }
            
            Divider()
            
            HStack {
                TextField("Add a comment...", text: $newComment, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                
                Button("Post") {
                    guard !newComment.isEmpty else { return }
                    var currentComments = item.comments ?? []
                    currentComments.append(TaskComment(text: newComment))
                    item.comments = currentComments
                    newComment = ""
                    try? modelContext.save()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .disabled(newComment.isEmpty)
            .padding(16)
        }
    }
}

// MARK: =====================================================================
// MARK: 💼 WORKSPACE 1: EXECUTIVE LINEAR SPLIT (CANVAS + INSPECTOR)
// MARK: =====================================================================

struct Workspace1LinearSplitView: View {
    @Bindable var item: TodoItem
    var allItems: [TodoItem]
    let onSave: () -> Void
    let onDelete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var newSubtaskTitle = ""
    @State private var showDatePicker = false
    @State private var timerSeconds = 25 * 60
    @State private var isTimerRunning = false

    private var subtasks: [TodoItem] {
        allItems.filter { $0.parentID == item.id && !$0.isArchived }.sorted { $0.createdAt < $1.createdAt }
    }

    private var completedSubtasksCount: Int {
        subtasks.filter { $0.isCompleted }.count
    }

    private var subtaskProgress: Double {
        guard !subtasks.isEmpty else { return 0 }
        return Double(completedSubtasksCount) / Double(subtasks.count)
    }

    var body: some View {
        HStack(spacing: 0) {

            // Left Main Canvas (70% Width)
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.lg) {

                    // Status & Priority Header Badges
                    HStack(spacing: 8) {
                        Button {
                            item.completedAt = item.isCompleted ? nil : Date()
                            onSave()
                            Haptics.impact(.rigid)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(item.isCompleted ? DS.Color.success : DS.Color.textSecondary)
                                Text(item.isCompleted ? "DONE" : "IN PROGRESS")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(item.isCompleted ? DS.Color.success : DS.Color.textPrimary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                item.isCompleted ? DS.Color.success.opacity(0.12) : DS.Color.surfaceRecessed,
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)

                        if let cat = item.category {
                            Text(cat.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DS.Color.surfaceRecessed, in: Capsule())
                        }

                        Spacer()
                    }

                    // Large Task Title
                    TextField("Task Title…", text: $item.title, axis: .vertical)
                        .font(.system(size: 26, weight: .bold))
                        .textFieldStyle(.plain)
                        .strikethrough(item.isCompleted, color: DS.Color.textTertiary)
                        .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                        .onChange(of: item.title) { _, _ in onSave() }

                    Divider()

                    // Subtask Checklist Studio
                    VStack(alignment: .leading, spacing: DS.Space.sm) {
                        HStack {
                            Text("SUBTASKS & ACTION STEPS")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)
                                .tracking(0.6)

                            Spacer()

                            if !subtasks.isEmpty {
                                Text("\(completedSubtasksCount) of \(subtasks.count) complete (\(Int(subtaskProgress * 100))%)")
                                    .font(.system(size: 10, weight: .medium))
                                    .monospacedDigit()
                                    .foregroundStyle(DS.Color.textTertiary)
                            }
                        }

                        if !subtasks.isEmpty {
                            GeometryReader { p in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(DS.Color.surfaceRecessed)
                                        .frame(height: 4)
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(DS.Color.success)
                                        .frame(width: max(0, p.size.width * CGFloat(subtaskProgress)), height: 4)
                                }
                            }
                            .frame(height: 4)
                        }

                        VStack(spacing: 0) {
                            ForEach(subtasks) { sub in
                                HStack(spacing: 8) {
                                    Button {
                                        sub.completedAt = sub.isCompleted ? nil : Date()
                                        onSave()
                                        Haptics.impact(.light)
                                    } label: {
                                        Image(systemName: sub.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 13))
                                            .foregroundStyle(sub.isCompleted ? DS.Color.success : DS.Color.textTertiary)
                                    }
                                    .buttonStyle(.plain)

                                    TextField("Subtask…", text: Binding(
                                        get: { sub.title },
                                        set: { sub.title = $0; onSave() }
                                    ))
                                    .font(DS.Text.body)
                                    .textFieldStyle(.plain)
                                    .strikethrough(sub.isCompleted, color: DS.Color.textTertiary)
                                    .foregroundStyle(sub.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)

                                    Spacer()

                                    Button {
                                        sub.archivedAt = Date()
                                        onSave()
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundStyle(DS.Color.textTertiary.opacity(0.5))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)

                                if sub.id != subtasks.last?.id {
                                    Divider().padding(.leading, 32)
                                }
                            }

                            if !subtasks.isEmpty {
                                Divider()
                            }

                            // Quick Add Subtask Line
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(DS.Color.textTertiary)

                                TextField("Add subtask… (Press Enter)", text: $newSubtaskTitle)
                                    .font(DS.Text.body)
                                    .textFieldStyle(.plain)
                                    .onSubmit {
                                        addSubtask()
                                    }

                                if !newSubtaskTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                                    Button("Add") {
                                        addSubtask()
                                    }
                                    .font(.system(size: 10, weight: .bold))
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                        }
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
                        )
                    }

                    // Execution Notes & Strategy
                    VStack(alignment: .leading, spacing: 6) {
                        Text("EXECUTION NOTES & SCRATCHPAD")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .tracking(0.6)

                        TextEditor(text: Binding(
                            get: { item.notes ?? "" },
                            set: { item.notes = $0.isEmpty ? nil : $0; onSave() }
                        ))
                        .font(DS.Text.body)
                        .frame(minHeight: 100)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(DS.Color.border.opacity(0.4), lineWidth: 1)
                        )
                    }
                }
                .padding(DS.Space.xl)
            }

            Divider()

            // Right Inspector Panel (30% Width / 240pt)
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                Text("TASK ATTRIBUTES")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DS.Color.textTertiary)
                    .tracking(0.8)

                // Due Date Card
                VStack(alignment: .leading, spacing: 4) {
                    Text("Due Date")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DS.Color.textTertiary)

                    Button { showDatePicker.toggle() } label: {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                            if let due = item.dueDate {
                                Text(due.formatted(.dateTime.month(.abbreviated).day().year()))
                                    .font(DS.Text.body)
                            } else {
                                Text("No Due Date").font(DS.Text.body)
                            }
                            Spacer()
                        }
                        .foregroundStyle(item.dueDate != nil ? DS.Color.textPrimary : DS.Color.textSecondary)
                        .padding(8)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showDatePicker) {
                        CompactDueDatePicker(item: item, onClose: { showDatePicker = false })
                    }
                }

                // Priority Selector Card
                VStack(alignment: .leading, spacing: 4) {
                    Text("Priority")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DS.Color.textTertiary)

                    Menu {
                        Button("None") { item.priority = 0; onSave() }
                        Button("Low") { item.priority = 1; onSave() }
                        Button("Medium") { item.priority = 2; onSave() }
                        Button("High") { item.priority = 3; onSave() }
                    } label: {
                        HStack {
                            let priorityColor = [DS.Color.priorityNone, DS.Color.priorityLow, DS.Color.priorityMedium, DS.Color.priorityHigh][min(item.priority, 3)]
                            Image(systemName: item.priority > 0 ? "flag.fill" : "flag")
                                .foregroundStyle(priorityColor)
                            Text(["None", "Low", "Medium", "High"][min(item.priority, 3)])
                                .font(DS.Text.body)
                                .foregroundStyle(DS.Color.textPrimary)
                            Spacer()
                        }
                        .padding(8)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .menuStyle(.borderlessButton)
                }

                // Deep Focus Sprint Module
                VStack(alignment: .leading, spacing: 6) {
                    Text("Focus Sprint")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(DS.Color.textTertiary)

                    HStack {
                        Image(systemName: "timer")
                            .font(.system(size: 12))
                        Text(String(format: "%02d:%02d", timerSeconds / 60, timerSeconds % 60))
                            .font(.system(size: 13, weight: .bold))
                            .monospacedDigit()
                        Spacer()
                        Button(isTimerRunning ? "Pause" : "Start") {
                            isTimerRunning.toggle()
                            Haptics.impact(.light)
                        }
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(isTimerRunning ? Color.orange.opacity(0.15) : Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
                    }
                    .padding(8)
                    .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                }

                Spacer()

                // Creation Timestamp
                Text("Created \(item.createdAt.formatted(.dateTime.month().day().hour().minute()))")
                    .font(.system(size: 9))
                    .foregroundStyle(DS.Color.textTertiary)
            }
            .padding(DS.Space.lg)
            .frame(width: 220)
            .background(DS.Color.surface)
        }
    }

    private func addSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let child = TodoItem()
        child.title = trimmed
        child.parentID = item.id
        child.createdAt = Date()
        modelContext.insert(child)
        onSave()
        newSubtaskTitle = ""
        Haptics.impact(.light)
    }
}

// MARK: =====================================================================
// MARK: 📋 WORKSPACE 2: THINGS 3 CENTERED DOCUMENT INSPECTOR
// MARK: =====================================================================

struct Workspace2ThingsDocView: View {
    @Bindable var item: TodoItem
    var allItems: [TodoItem]
    let onSave: () -> Void
    let onDelete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var newSubtaskTitle = ""
    @State private var showDatePicker = false

    private var subtasks: [TodoItem] {
        allItems.filter { $0.parentID == item.id && !$0.isArchived }.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.xl) {

                // Floating Action Header Bar
                HStack(spacing: 12) {
                    Button {
                        item.completedAt = item.isCompleted ? nil : Date()
                        onSave()
                        Haptics.impact(.rigid)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16))
                                .foregroundStyle(item.isCompleted ? DS.Color.success : DS.Color.textSecondary)
                            Text(item.isCompleted ? "Completed" : "Active Task")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)
                        }
                    }
                    .buttonStyle(.plain)

                    Divider().frame(height: 16)

                    // Due Date Button
                    Button { showDatePicker.toggle() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text(item.dueDate?.formatted(.dateTime.month(.abbreviated).day()) ?? "Schedule Date")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(item.dueDate != nil ? DS.Color.textPrimary : DS.Color.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showDatePicker) {
                        CompactDueDatePicker(item: item, onClose: { showDatePicker = false })
                    }

                    Divider().frame(height: 16)

                    // Priority Tag
                    Menu {
                        Button("None") { item.priority = 0; onSave() }
                        Button("Low") { item.priority = 1; onSave() }
                        Button("Medium") { item.priority = 2; onSave() }
                        Button("High") { item.priority = 3; onSave() }
                    } label: {
                        HStack(spacing: 4) {
                            let priorityColor = [DS.Color.priorityNone, DS.Color.priorityLow, DS.Color.priorityMedium, DS.Color.priorityHigh][min(item.priority, 3)]
                            Image(systemName: item.priority > 0 ? "flag.fill" : "flag")
                                .font(.system(size: 10))
                                .foregroundStyle(priorityColor)
                            Text(["No Priority", "Low", "Medium", "High"][min(item.priority, 3)])
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                    }
                    .menuStyle(.borderlessButton)

                    Spacer()
                }
                .padding(.horizontal, DS.Space.lg)
                .padding(.vertical, 8)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))

                // Hero Title
                TextField("Task Title…", text: $item.title, axis: .vertical)
                    .font(.system(size: 28, weight: .bold))
                    .textFieldStyle(.plain)
                    .strikethrough(item.isCompleted, color: DS.Color.textTertiary)
                    .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                    .onChange(of: item.title) { _, _ in onSave() }

                // Notes / Thoughts Area
                VStack(alignment: .leading, spacing: 4) {
                    Text("NOTES")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .tracking(0.6)

                    TextEditor(text: Binding(
                        get: { item.notes ?? "" },
                        set: { item.notes = $0.isEmpty ? nil : $0; onSave() }
                    ))
                    .font(DS.Text.body)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 8))
                }

                // Subtasks Checklist
                VStack(alignment: .leading, spacing: 8) {
                    Text("CHECKLIST")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .tracking(0.6)

                    VStack(spacing: 0) {
                        ForEach(subtasks) { sub in
                            HStack(spacing: 8) {
                                Button {
                                    sub.completedAt = sub.isCompleted ? nil : Date()
                                    onSave()
                                    Haptics.impact(.light)
                                } label: {
                                    Image(systemName: sub.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 13))
                                        .foregroundStyle(sub.isCompleted ? DS.Color.success : DS.Color.textTertiary)
                                }
                                .buttonStyle(.plain)

                                TextField("Subtask…", text: Binding(
                                    get: { sub.title },
                                    set: { sub.title = $0; onSave() }
                                ))
                                .font(DS.Text.body)
                                .textFieldStyle(.plain)
                                .strikethrough(sub.isCompleted, color: DS.Color.textTertiary)
                                .foregroundStyle(sub.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)

                                Spacer()

                                Button {
                                    sub.archivedAt = Date()
                                    onSave()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(DS.Color.textTertiary.opacity(0.5))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)

                            if sub.id != subtasks.last?.id {
                                Divider().padding(.leading, 32)
                            }
                        }

                        if !subtasks.isEmpty {
                            Divider()
                        }

                        // Add Subtask Row
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)

                            TextField("Add item… (Press Enter)", text: $newSubtaskTitle)
                                .font(DS.Text.body)
                                .textFieldStyle(.plain)
                                .onSubmit {
                                    addSubtask()
                                }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                    }
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .frame(maxWidth: 620)
            .padding(DS.Space.xxl)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func addSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let child = TodoItem()
        child.title = trimmed
        child.parentID = item.id
        child.createdAt = Date()
        modelContext.insert(child)
        onSave()
        newSubtaskTitle = ""
        Haptics.impact(.light)
    }
}

// MARK: =====================================================================
// MARK: 🗂️ WORKSPACE 3: STRUCTURED BENTO MATRIX (MODULAR)
// MARK: =====================================================================

struct Workspace3BentoMatrixView: View {
    @Bindable var item: TodoItem
    var allItems: [TodoItem]
    let onSave: () -> Void
    let onDelete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var newSubtaskTitle = ""
    @State private var showDatePicker = false

    private var subtasks: [TodoItem] {
        allItems.filter { $0.parentID == item.id && !$0.isArchived }.sorted { $0.createdAt < $1.createdAt }
    }

    private var completedCount: Int {
        subtasks.filter { $0.isCompleted }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.lg) {

                // Top Hero Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Button {
                            item.completedAt = item.isCompleted ? nil : Date()
                            onSave()
                            Haptics.impact(.rigid)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 15))
                                    .foregroundStyle(item.isCompleted ? DS.Color.success : DS.Color.textSecondary)
                                Text(item.isCompleted ? "Completed ✓" : "Mark Done")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(DS.Color.textPrimary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(DS.Color.surfaceRecessed, in: Capsule())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        if let cat = item.category {
                            Text(cat)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DS.Color.surfaceRecessed, in: Capsule())
                        }
                    }

                    TextField("Task Title…", text: $item.title, axis: .vertical)
                        .font(.system(size: 24, weight: .bold))
                        .textFieldStyle(.plain)
                        .strikethrough(item.isCompleted, color: DS.Color.textTertiary)
                        .foregroundStyle(item.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                        .onChange(of: item.title) { _, _ in onSave() }
                }
                .padding(DS.Space.xl)
                .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))

                // Bento 2-Column Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Space.md) {

                    // Box 1: Subtasks Checklist
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("SUBTASKS (\(completedCount)/\(subtasks.count))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)
                                .tracking(0.6)
                            Spacer()
                        }

                        VStack(spacing: 4) {
                            ForEach(subtasks) { sub in
                                HStack(spacing: 6) {
                                    Button {
                                        sub.completedAt = sub.isCompleted ? nil : Date()
                                        onSave()
                                    } label: {
                                        Image(systemName: sub.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 11))
                                            .foregroundStyle(sub.isCompleted ? DS.Color.success : DS.Color.textTertiary)
                                    }
                                    .buttonStyle(.plain)

                                    Text(sub.title)
                                        .font(.system(size: 11))
                                        .foregroundStyle(sub.isCompleted ? DS.Color.textTertiary : DS.Color.textPrimary)
                                        .strikethrough(sub.isCompleted)
                                        .lineLimit(1)

                                    Spacer()
                                }
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(DS.Color.textTertiary)

                                TextField("Add subtask…", text: $newSubtaskTitle)
                                    .font(.system(size: 11))
                                    .textFieldStyle(.plain)
                                    .onSubmit {
                                        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                                        guard !trimmed.isEmpty else { return }
                                        let child = TodoItem()
                                        child.title = trimmed
                                        child.parentID = item.id
                                        child.createdAt = Date()
                                        modelContext.insert(child)
                                        onSave()
                                        newSubtaskTitle = ""
                                    }
                            }
                        }
                    }
                    .padding(DS.Space.lg)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))

                    // Box 2: Execution Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES & STRATEGY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .tracking(0.6)

                        TextEditor(text: Binding(
                            get: { item.notes ?? "" },
                            set: { item.notes = $0.isEmpty ? nil : $0; onSave() }
                        ))
                        .font(.system(size: 12))
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                    }
                    .padding(DS.Space.lg)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))

                    // Box 3: Schedule & Priority
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SCHEDULE & PRIORITY")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .tracking(0.6)

                        Button { showDatePicker.toggle() } label: {
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                Text(item.dueDate?.formatted(.dateTime.month(.abbreviated).day()) ?? "Set Due Date")
                                    .font(.system(size: 11))
                                Spacer()
                            }
                            .padding(6)
                            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showDatePicker) {
                            CompactDueDatePicker(item: item, onClose: { showDatePicker = false })
                        }
                    }
                    .padding(DS.Space.lg)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))

                    // Box 4: Focus & Deep Work
                    VStack(alignment: .leading, spacing: 8) {
                        Text("FOCUS ALLOCATION")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .tracking(0.6)

                        HStack {
                            Image(systemName: "timer")
                                .font(.system(size: 11))
                            Text("25m Sprint")
                                .font(.system(size: 11, weight: .bold))
                            Spacer()
                            Text("Ready")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DS.Color.success)
                        }
                        .padding(6)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(DS.Space.lg)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                }
            }
            .padding(DS.Space.xl)
        }
    }
}
