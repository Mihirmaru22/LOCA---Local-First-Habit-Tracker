import SwiftUI
import SwiftData

// MARK: - BrainStormFolderSidebar

enum SystemFolderType: String, CaseIterable, Identifiable {
    case allNotes = "All Notes"
    case quickNotes = "Quick Notes"
    case favorites = "Favorites"
    case locked = "Locked Notes"
    case recentlyDeleted = "Recently Deleted"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .allNotes: return "note.text"
        case .quickNotes: return "bolt.fill"
        case .favorites: return "star.fill"
        case .locked: return "lock.fill"
        case .recentlyDeleted: return "trash"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .allNotes: return .accentColor
        case .quickNotes: return .yellow
        case .favorites: return .orange
        case .locked: return .indigo
        case .recentlyDeleted: return .red
        }
    }
}

struct BrainStormFolderSidebar: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrainStormFolder.sortOrder) private var customFolders: [BrainStormFolder]
    @Query private var allNotes: [BrainStormNote]

    @Binding var selectedSystemFolder: SystemFolderType?
    @Binding var selectedFolderID: UUID?
    @Binding var selectedTag: String?

    @State private var isShowingNewFolderSheet: Bool = false
    @State private var newFolderName: String = ""
    @State private var editingFolder: BrainStormFolder? = nil
    @State private var expandedFolders: Set<UUID> = []
    @State private var hoveredItem: String? = nil
    @State private var isShowingSmartFolderSheet: Bool = false
    @State private var isShowingTagBrowser: Bool = true

    // Computed Counts
    private var liveNotes: [BrainStormNote] {
        allNotes.filter { $0.isLive }
    }

    private var allNotesCount: Int { liveNotes.count }
    private var favoritesCount: Int { liveNotes.filter { $0.isFavorite || $0.isPinned }.count }
    private var lockedCount: Int { liveNotes.filter { $0.isLocked }.count }
    private var deletedCount: Int { allNotes.filter { $0.deletedAt != nil }.count }

    // Aggregate tags across all live notes
    private var availableTags: [String] {
        let tagSet = liveNotes.reduce(into: Set<String>()) { set, note in
            set.formUnion(note.tags)
        }
        return Array(tagSet).sorted()
    }

    private var rootFolders: [BrainStormFolder] {
        customFolders.filter { $0.parentFolderID == nil }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header / Title
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                    Text("BrainStorm")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                }

                Spacer()

                // New Folder Button
                Button {
                    newFolderName = ""
                    isShowingNewFolderSheet = true
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .help("New Folder (⌘⇧N)")
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().opacity(0.2)

            // Scrollable Folders & Tags List
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    // 1. SYSTEM FOLDERS SECTION
                    VStack(spacing: 3) {
                        systemFolderRow(type: .allNotes, count: allNotesCount)
                        systemFolderRow(type: .quickNotes, count: liveNotes.filter { $0.folderID == nil }.count)
                        systemFolderRow(type: .favorites, count: favoritesCount)
                        systemFolderRow(type: .locked, count: lockedCount)
                        systemFolderRow(type: .recentlyDeleted, count: deletedCount)
                    }

                    Divider().opacity(0.15)

                    // 2. USER CUSTOM FOLDERS SECTION
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("FOLDERS")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.4))
                            Spacer()
                        }
                        .padding(.horizontal, 8)

                        if rootFolders.isEmpty {
                            Text("No custom folders yet")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.white.opacity(0.3))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                        } else {
                            VStack(spacing: 2) {
                                ForEach(rootFolders) { folder in
                                    BrainStormFolderNodeView(
                                        folder: folder,
                                        depth: 0,
                                        customFolders: customFolders,
                                        liveNotes: liveNotes,
                                        selectedFolderID: $selectedFolderID,
                                        selectedSystemFolder: $selectedSystemFolder,
                                        selectedTag: $selectedTag,
                                        expandedFolders: $expandedFolders,
                                        editingFolder: $editingFolder,
                                        isShowingNewFolderSheet: $isShowingNewFolderSheet,
                                        newFolderName: $newFolderName,
                                        onDelete: { f in deleteFolder(f) }
                                    )
                                }
                            }
                        }
                    }

                    // 3. TAG BROWSER SECTION
                    if !availableTags.isEmpty {
                        Divider().opacity(0.15)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("TAGS", systemImage: "tag")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.4))
                                Spacer()
                            }
                            .padding(.horizontal, 8)

                            FlowTagLayout(spacing: 6) {
                                ForEach(availableTags, id: \.self) { tag in
                                    tagPill(tag: tag)
                                }
                            }
                            .padding(.horizontal, 6)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
        }
        .background(Color.black.opacity(0.25))
        .sheet(isPresented: $isShowingNewFolderSheet) {
            newFolderModal(parentID: nil)
        }
        .sheet(item: $editingFolder) { folder in
            renameFolderModal(folder: folder)
        }
    }

    // MARK: - System Folder Row

    private func systemFolderRow(type: SystemFolderType, count: Int) -> some View {
        let isSelected = selectedSystemFolder == type && selectedFolderID == nil && selectedTag == nil
        let isHovered = hoveredItem == type.rawValue

        return Button {
            selectedSystemFolder = type
            selectedFolderID = nil
            selectedTag = nil
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(type.iconColor)
                    .frame(width: 20)

                Text(type.rawValue)
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.white : (isHovered ? Color.white : Color.white.opacity(0.85)))

                Spacer()

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.white.opacity(0.06), in: Capsule())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isSelected ? Color.white.opacity(0.12) : (isHovered ? Color.white.opacity(0.05) : Color.clear),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in
            hoveredItem = h ? type.rawValue : nil
        }
    }

    // MARK: - Tag Pill

    private func tagPill(tag: String) -> some View {
        let isSelected = selectedTag == tag
        return Button {
            if isSelected {
                selectedTag = nil
            } else {
                selectedTag = tag
                selectedSystemFolder = nil
                selectedFolderID = nil
            }
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 3) {
                Text("#\(tag)")
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.black : Color.accentColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                isSelected ? Color.accentColor : Color.accentColor.opacity(0.15),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Modal Sheets

    private func newFolderModal(parentID: UUID?) -> some View {
        VStack(spacing: 14) {
            Text("New Folder")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white)

            TextField("Folder Name", text: $newFolderName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 240)

            HStack(spacing: 12) {
                Button("Cancel") {
                    isShowingNewFolderSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    let trimmed = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    let folder = BrainStormFolder(
                        name: trimmed,
                        parentFolderID: parentID,
                        sortOrder: customFolders.count
                    )
                    modelContext.insert(folder)
                    try? modelContext.save()
                    selectedFolderID = folder.id
                    selectedSystemFolder = nil
                    isShowingNewFolderSheet = false
                    Haptics.impact(.medium)
                }
                .buttonStyle(.borderedProminent)
                .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .frame(width: 280, height: 150)
        .background(Color.black.opacity(0.85).background(.ultraThinMaterial))
    }

    private func renameFolderModal(folder: BrainStormFolder) -> some View {
        VStack(spacing: 14) {
            Text("Rename Folder")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white)

            TextField("Folder Name", text: Binding(
                get: { folder.name },
                set: { folder.name = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 240)

            HStack(spacing: 12) {
                Button("Done") {
                    try? modelContext.save()
                    editingFolder = nil
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .frame(width: 280, height: 140)
        .background(Color.black.opacity(0.85).background(.ultraThinMaterial))
    }

    private func deleteFolder(_ folder: BrainStormFolder) {
        if selectedFolderID == folder.id {
            selectedFolderID = nil
            selectedSystemFolder = .allNotes
        }
        modelContext.delete(folder)
        try? modelContext.save()
        Haptics.impact(.medium)
    }
}

// MARK: - BrainStormFolderNodeView (Extracted Struct for Safe Recursive Tree Rendering)

struct BrainStormFolderNodeView: View {

    let folder: BrainStormFolder
    let depth: Int
    let customFolders: [BrainStormFolder]
    let liveNotes: [BrainStormNote]

    @Binding var selectedFolderID: UUID?
    @Binding var selectedSystemFolder: SystemFolderType?
    @Binding var selectedTag: String?
    @Binding var expandedFolders: Set<UUID>
    @Binding var editingFolder: BrainStormFolder?
    @Binding var isShowingNewFolderSheet: Bool
    @Binding var newFolderName: String
    let onDelete: (BrainStormFolder) -> Void

    @State private var isHovered: Bool = false

    private var children: [BrainStormFolder] {
        customFolders.filter { $0.parentFolderID == folder.id }
    }

    private var isExpanded: Bool {
        expandedFolders.contains(folder.id)
    }

    private var isSelected: Bool {
        selectedFolderID == folder.id && selectedSystemFolder == nil
    }

    private var noteCount: Int {
        liveNotes.filter { $0.folderID == folder.id }.count
    }

    var body: some View {
        VStack(spacing: 1) {
            Button {
                selectedSystemFolder = nil
                selectedFolderID = folder.id
                selectedTag = nil
                Haptics.impact(.light)
            } label: {
                HStack(spacing: 6) {
                    if depth > 0 {
                        Spacer().frame(width: CGFloat(depth * 14))
                    }

                    if !children.isEmpty {
                        Button {
                            if isExpanded {
                                expandedFolders.remove(folder.id)
                            } else {
                                expandedFolders.insert(folder.id)
                            }
                        } label: {
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.5))
                                .frame(width: 14, height: 14)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Spacer().frame(width: 14)
                    }

                    Image(systemName: folder.icon)
                        .font(.system(size: 13))
                        .foregroundStyle(isSelected ? Color.accentColor : Color.yellow.opacity(0.85))
                        .frame(width: 16)

                    Text(folder.name)
                        .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.white : (isHovered ? Color.white : Color.white.opacity(0.8)))
                        .lineLimit(1)

                    Spacer()

                    if noteCount > 0 {
                        Text("\(noteCount)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.white.opacity(0.06), in: Capsule())
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    isSelected ? Color.white.opacity(0.12) : (isHovered ? Color.white.opacity(0.05) : Color.clear),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("Rename Folder") {
                    editingFolder = folder
                }
                Button("New Subfolder") {
                    newFolderName = ""
                    isShowingNewFolderSheet = true
                }
                Divider()
                Button("Delete Folder", role: .destructive) {
                    onDelete(folder)
                }
            }
            .onHover { h in
                isHovered = h
            }

            if isExpanded && !children.isEmpty {
                ForEach(children) { child in
                    BrainStormFolderNodeView(
                        folder: child,
                        depth: depth + 1,
                        customFolders: customFolders,
                        liveNotes: liveNotes,
                        selectedFolderID: $selectedFolderID,
                        selectedSystemFolder: $selectedSystemFolder,
                        selectedTag: $selectedTag,
                        expandedFolders: $expandedFolders,
                        editingFolder: $editingFolder,
                        isShowingNewFolderSheet: $isShowingNewFolderSheet,
                        newFolderName: $newFolderName,
                        onDelete: onDelete
                    )
                }
            }
        }
    }
}

// MARK: - FlowTagLayout for Wrapping Tags

struct FlowTagLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 200
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxHeightInRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            currentX += size.width + spacing
            maxHeightInRow = max(maxHeightInRow, size.height)
        }
        height = currentY + maxHeightInRow
        return CGSize(width: width, height: max(height, 20))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var maxHeightInRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            maxHeightInRow = max(maxHeightInRow, size.height)
        }
    }
}
