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
                                    folderHierarchyView(folder: folder, depth: 0)
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
    }

    // MARK: - Root Folders & Nesting

    private var rootFolders: [BrainStormFolder] {
        customFolders.filter { $0.parentFolderID == nil }
    }

    private func subfolders(of parentID: UUID) -> [BrainStormFolder] {
        customFolders.filter { $0.parentFolderID == parentID }
    }

    @ViewBuilder
    private func folderHierarchyView(folder: BrainStormFolder, depth: Int) -> some View {
        let isSelected = selectedFolderID == folder.id && selectedSystemFolder == nil
        let isHovered = hoveredItem == folder.id.uuidString
        let children = subfolders(of: folder.id)
        let isExpanded = expandedFolders.contains(folder.id)
        let count = liveNotes.filter { $0.folderID == folder.id }.count

        VStack(spacing: 1) {
            Button {
                selectedSystemFolder = nil
                selectedFolderID = folder.id
                selectedTag = nil
                Haptics.impact(.light)
            } label: {
                HStack(spacing: 6) {
                    // Indentation spacing
                    if depth > 0 {
                        Spacer().frame(width: CGFloat(depth * 14))
                    }

                    // Expand / Collapse Chevron for nested folders
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

                    if count > 0 {
                        Text("\(count)")
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
                    deleteFolder(folder)
                }
            }
            .onHover { h in
                hoveredItem = h ? folder.id.uuidString : nil
            }

            // Render children if expanded
            if isExpanded && !children.isEmpty {
                ForEach(children) { child in
                    folderHierarchyView(folder: child, depth: depth + 1)
                }
            }
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
            if selectedTag == tag {
                selectedTag = nil
            } else {
                selectedTag = tag
                selectedSystemFolder = nil
                selectedFolderID = nil
            }
            Haptics.impact(.light)
        } label: {
            HStack(spacing: 4) {
                Text("#\(tag)")
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.white : Color.accentColor.opacity(0.9))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                isSelected ? Color.accentColor : Color.accentColor.opacity(0.12),
                in: Capsule()
            )
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : Color.accentColor.opacity(0.3), lineWidth: 0.6)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - New Folder Sheet

    private func newFolderModal(parentID: UUID?) -> some View {
        VStack(spacing: 16) {
            Text("New Folder")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white)

            TextField("Folder Name", text: $newFolderName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)

            HStack(spacing: 12) {
                Button("Cancel") {
                    isShowingNewFolderSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    let trimmed = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let name = trimmed.isEmpty ? "New Folder" : trimmed
                    let folder = BrainStormFolder(
                        name: name,
                        parentFolderID: parentID,
                        sortOrder: customFolders.count
                    )
                    modelContext.insert(folder)
                    try? modelContext.save()
                    isShowingNewFolderSheet = false
                    selectedFolderID = folder.id
                    selectedSystemFolder = nil
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 280, height: 160)
        .background(Color.black.opacity(0.85).background(.ultraThinMaterial))
    }

    private func deleteFolder(_ folder: BrainStormFolder) {
        // Move notes inside folder to unfiled
        let notesInFolder = allNotes.filter { $0.folderID == folder.id }
        for note in notesInFolder {
            note.folderID = nil
        }
        modelContext.delete(folder)
        try? modelContext.save()
        if selectedFolderID == folder.id {
            selectedFolderID = nil
            selectedSystemFolder = .allNotes
        }
    }
}

// MARK: - FlowTagLayout (Wrapping Tag Cloud Helper)

struct FlowTagLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 200
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeightInRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            maxHeightInRow = max(maxHeightInRow, size.height)
            x += size.width + spacing
        }
        height = y + maxHeightInRow
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeightInRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            maxHeightInRow = max(maxHeightInRow, size.height)
            x += size.width + spacing
        }
    }
}
