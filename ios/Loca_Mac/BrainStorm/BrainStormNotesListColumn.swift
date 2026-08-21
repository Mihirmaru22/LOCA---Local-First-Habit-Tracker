import SwiftUI
import SwiftData

// MARK: - BrainStormNotesListColumn

enum BrainStormViewMode: String, CaseIterable {
    case list = "List"
    case gallery = "Gallery"
}

enum BrainStormSortOrder: String, CaseIterable {
    case dateEdited = "Date Edited"
    case dateCreated = "Date Created"
    case title = "Title"
}

struct BrainStormNotesListColumn: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var allNotes: [BrainStormNote]
    @Query private var allFolders: [BrainStormFolder]

    var showFolders: Binding<Bool>? = nil
    var selectedSystemFolder: SystemFolderType?
    var selectedFolderID: UUID?
    var selectedTag: String?
    @Binding var selectedNote: BrainStormNote?
    var onOpenTour: (() -> Void)? = nil

    @State private var searchText: String = ""
    @AppStorage("brainstorm_view_mode") private var viewModeRaw: String = BrainStormViewMode.list.rawValue
    @AppStorage("brainstorm_sort_order") private var sortOrderRaw: String = BrainStormSortOrder.dateEdited.rawValue
    @State private var hoveredNoteID: UUID? = nil

    private var viewMode: BrainStormViewMode {
        BrainStormViewMode(rawValue: viewModeRaw) ?? .list
    }

    private var sortOrder: BrainStormSortOrder {
        BrainStormSortOrder(rawValue: sortOrderRaw) ?? .dateEdited
    }

    // Filter notes based on active sidebar selection & search query
    private var filteredNotes: [BrainStormNote] {
        let base: [BrainStormNote]
        
        if let systemFolder = selectedSystemFolder {
            switch systemFolder {
            case .allNotes:
                base = allNotes.filter { $0.isLive }
            case .quickNotes:
                base = allNotes.filter { $0.isLive && $0.folderID == nil }
            case .favorites:
                base = allNotes.filter { $0.isLive && ($0.isFavorite || $0.isPinned) }
            case .locked:
                base = allNotes.filter { $0.isLive && $0.isLocked }
            case .recentlyDeleted:
                base = allNotes.filter { $0.deletedAt != nil }
            }
        } else if let folderID = selectedFolderID {
            base = allNotes.filter { $0.isLive && $0.folderID == folderID }
        } else if let tag = selectedTag {
            base = allNotes.filter { $0.isLive && $0.tags.contains(tag.lowercased()) }
        } else {
            base = allNotes.filter { $0.isLive }
        }

        // Apply Search query
        let queryFiltered: [BrainStormNote]
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            queryFiltered = base
        } else {
            queryFiltered = base.filter {
                $0.title.lowercased().contains(query) ||
                $0.bodyText.lowercased().contains(query) ||
                $0.tags.contains(where: { $0.lowercased().contains(query) })
            }
        }

        // Apply Sorting
        return queryFiltered.sorted { a, b in
            switch sortOrder {
            case .dateEdited:
                return a.updatedAt > b.updatedAt
            case .dateCreated:
                return a.createdAt > b.createdAt
            case .title:
                return a.title.localizedStandardCompare(b.title) == .orderedAscending
            }
        }
    }

    // Split into Pinned vs Regular Notes
    private var pinnedNotes: [BrainStormNote] {
        guard selectedSystemFolder != .recentlyDeleted else { return [] }
        return filteredNotes.filter { $0.isPinned }
    }

    private var unpinnedNotes: [BrainStormNote] {
        if selectedSystemFolder == .recentlyDeleted {
            return filteredNotes
        }
        return filteredNotes.filter { !$0.isPinned }
    }

    var body: some View {
        VStack(spacing: 0) {

            // Top Header: Title, Search, View Mode Toggle, New Note Button
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    if let showFolders = showFolders {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showFolders.wrappedValue.toggle()
                            }
                            Haptics.impact(.light)
                        } label: {
                            Image(systemName: "sidebar.leading")
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundStyle(showFolders.wrappedValue ? Color.white : Color.white.opacity(0.5))
                                .frame(width: 24, height: 22)
                                .background(showFolders.wrappedValue ? Color.white.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlutoFastButtonStyle())
                        .help("Toggle Folders Sidebar")
                    }

                    // Header title based on selection
                    Text(columnTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)

                    Spacer()

                    // View Mode Switcher (List vs Gallery)
                    HStack(spacing: 2) {
                        Button {
                            viewModeRaw = BrainStormViewMode.list.rawValue
                            Haptics.impact(.light)
                        } label: {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 11, weight: viewMode == .list ? .bold : .medium))
                                .foregroundStyle(viewMode == .list ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 24, height: 22)
                                .background(viewMode == .list ? Color.white.opacity(0.14) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                        .help("List View")

                        Button {
                            viewModeRaw = BrainStormViewMode.gallery.rawValue
                            Haptics.impact(.light)
                        } label: {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 11, weight: viewMode == .gallery ? .bold : .medium))
                                .foregroundStyle(viewMode == .gallery ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 24, height: 22)
                                .background(viewMode == .gallery ? Color.white.opacity(0.14) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                        .help("Gallery View")
                    }
                    .padding(2)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))

                    // Interactive Feature Guide Button
                    if let onOpenTour = onOpenTour {
                        Button {
                            onOpenTour()
                        } label: {
                            HStack(spacing: 3.5) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Guide")
                                    .font(.system(size: 10.5, weight: .semibold))
                            }
                            .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.25))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Color(red: 0.95, green: 0.75, blue: 0.25).opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(red: 0.95, green: 0.75, blue: 0.25).opacity(0.35), lineWidth: 1))
                        }
                        .buttonStyle(PlutoFastButtonStyle())
                        .help("Interactive Feature Guide & Studio Tour")
                    }

                    // Sort Order Menu
                    Menu {
                        ForEach(BrainStormSortOrder.allCases, id: \.self) { order in
                            Button {
                                sortOrderRaw = order.rawValue
                            } label: {
                                HStack {
                                    Text(order.rawValue)
                                    if sortOrder == order {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.7))
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.06), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Sort Notes")

                    // New Note Button (⌘N)
                    Button {
                        createNewNote()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(width: 26, height: 26)
                            .background(Color.accentColor, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("New Note (⌘N)")
                    .keyboardShortcut("n", modifiers: .command)
                }

                // Instant Search Bar
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.4))

                    TextField("Search all notes...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider().opacity(0.2)

            // Content Area (List vs Gallery)
            if filteredNotes.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {

                        // 📌 Pinned Notes Section
                        if !pinnedNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 4) {
                                    Image(systemName: "pin.fill")
                                        .font(.system(size: 9))
                                    Text("PINNED")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                }
                                .foregroundStyle(Color.yellow.opacity(0.9))
                                .padding(.horizontal, 4)

                                if viewMode == .list {
                                    VStack(spacing: 4) {
                                        ForEach(pinnedNotes) { note in
                                            noteListRow(note: note)
                                        }
                                    }
                                } else {
                                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                        ForEach(pinnedNotes) { note in
                                            noteGalleryCard(note: note)
                                        }
                                    }
                                }
                            }
                        }

                        // 📝 Regular Notes Section
                        if !unpinnedNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                if !pinnedNotes.isEmpty {
                                    HStack(spacing: 4) {
                                        Text("NOTES")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundStyle(Color.white.opacity(0.4))
                                    }
                                    .padding(.horizontal, 4)
                                }

                                if viewMode == .list {
                                    VStack(spacing: 4) {
                                        ForEach(unpinnedNotes) { note in
                                            noteListRow(note: note)
                                        }
                                    }
                                } else {
                                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                        ForEach(unpinnedNotes) { note in
                                            noteGalleryCard(note: note)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(Color.clear)
        .onAppear {
            if selectedNote == nil, let first = filteredNotes.first {
                selectedNote = first
            }
        }
    }

    // MARK: - Column Title

    private var columnTitle: String {
        if let system = selectedSystemFolder {
            return system.rawValue
        } else if let folderID = selectedFolderID, let folder = allFolders.first(where: { $0.id == folderID }) {
            return folder.name
        } else if let tag = selectedTag {
            return "#\(tag)"
        }
        return "All Notes"
    }

    // MARK: - List View Row

    private func noteListRow(note: BrainStormNote) -> some View {
        let isSelected = selectedNote?.id == note.id
        let isHovered = hoveredNoteID == note.id

        return Button {
            selectedNote = note
            Haptics.impact(.light)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                // Subtle Title Header Row
                HStack(spacing: 6) {
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8.5))
                            .foregroundStyle(Color.yellow)
                    }
                    if note.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8.5))
                            .foregroundStyle(Color.indigo)
                    }

                    Text(note.title.isEmpty ? "New Note" : note.title)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.85))
                        .lineLimit(1)

                    Spacer()

                    Text(formatDate(note.updatedAt))
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.35))
                }

                // Generous Note Content Preview (Extended length)
                HStack(alignment: .top, spacing: 6) {
                    Text(note.previewSnippet)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.75) : Color.white.opacity(0.55))
                        .lineLimit(3)
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 4)

                    // Indicator Icons
                    VStack(alignment: .trailing, spacing: 3) {
                        if note.hasChecklist {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 9.5))
                                .foregroundStyle(Color.white.opacity(0.40))
                        }
                        if note.hasAttachments {
                            Image(systemName: "paperclip")
                                .font(.system(size: 9.5))
                                .foregroundStyle(Color.white.opacity(0.40))
                        }
                        if note.hasTable {
                            Image(systemName: "tablecells")
                                .font(.system(size: 9.5))
                                .foregroundStyle(Color.white.opacity(0.40))
                        }
                    }
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(
                isSelected
                    ? AnyView(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor.opacity(0.24), Color.accentColor.opacity(0.10)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    : AnyView(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isHovered ? Color.white.opacity(0.07) : Color.white.opacity(0.03))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected
                            ? LinearGradient(
                                colors: [Color.accentColor.opacity(0.65), Color.accentColor.opacity(0.20)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : (isHovered ? LinearGradient(colors: [Color.white.opacity(0.14), Color.clear], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [Color.white.opacity(0.06), Color.clear], startPoint: .top, endPoint: .bottom)),
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            noteContextMenu(note: note)
        }
        .onHover { h in
            hoveredNoteID = h ? note.id : nil
        }
    }

    // MARK: - Gallery View Card

    private func noteGalleryCard(note: BrainStormNote) -> some View {
        let isSelected = selectedNote?.id == note.id
        let isHovered = hoveredNoteID == note.id

        return Button {
            selectedNote = note
            Haptics.impact(.light)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                // Top Header
                HStack(spacing: 4) {
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8.5))
                            .foregroundStyle(Color.yellow)
                    }
                    if note.isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8.5))
                            .foregroundStyle(Color.indigo)
                    }
                    Text(note.title.isEmpty ? "New Note" : note.title)
                        .font(.system(size: 11.5, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                    Spacer()
                }

                // Paper Content Preview (Extended length)
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.bodyText.isEmpty ? "Empty note..." : note.previewSnippet)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white.opacity(0.65))
                        .lineLimit(5)
                        .lineSpacing(1.5)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Bottom Metadata Pill
                HStack {
                    Text(formatDate(note.updatedAt))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.4))
                    Spacer()

                    if note.hasChecklist {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                }
            }
            .padding(10)
            .frame(height: 130)
            .background(
                isSelected ? Color.accentColor.opacity(0.20) : (isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.04)),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor.opacity(0.7) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            noteContextMenu(note: note)
        }
        .onHover { h in
            hoveredNoteID = h ? note.id : nil
        }
    }

    // MARK: - Context Menu Actions

    @ViewBuilder
    private func noteContextMenu(note: BrainStormNote) -> some View {
        if note.deletedAt != nil {
            Button("Restore Note") {
                note.deletedAt = nil
                note.updatedAt = Date()
                try? modelContext.save()
            }
            Divider()
            Button("Delete Immediately", role: .destructive) {
                modelContext.delete(note)
                try? modelContext.save()
                if selectedNote?.id == note.id {
                    selectedNote = filteredNotes.first
                }
            }
        } else {
            Button(note.isPinned ? "Unpin Note" : "Pin Note") {
                note.isPinned.toggle()
                note.updatedAt = Date()
                try? modelContext.save()
            }

            Button(note.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                note.isFavorite.toggle()
                note.updatedAt = Date()
                try? modelContext.save()
            }

            Button(note.isLocked ? "Unlock Note" : "Lock Note") {
                note.isLocked.toggle()
                note.updatedAt = Date()
                try? modelContext.save()
            }

            Menu("Move to Folder") {
                Button("Unfiled (Quick Notes)") {
                    note.folderID = nil
                    try? modelContext.save()
                }
                ForEach(allFolders) { folder in
                    Button(folder.name) {
                        note.folderID = folder.id
                        try? modelContext.save()
                    }
                }
            }

            Divider()

            Button("Duplicate Note") {
                let dup = BrainStormNote(
                    title: "\(note.title) Copy",
                    bodyText: note.bodyText,
                    folderID: note.folderID,
                    tags: note.tags,
                    hasChecklist: note.hasChecklist,
                    hasAttachments: note.hasAttachments,
                    hasTable: note.hasTable,
                    tableDataJSON: note.tableDataJSON,
                    checklistItemsJSON: note.checklistItemsJSON,
                    attachmentsJSON: note.attachmentsJSON
                )
                modelContext.insert(dup)
                try? modelContext.save()
                selectedNote = dup
            }

            Divider()

            Button("Delete Note", role: .destructive) {
                note.deletedAt = Date()
                try? modelContext.save()
                if selectedNote?.id == note.id {
                    selectedNote = filteredNotes.first
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "note.text")
                .font(.system(size: 32))
                .foregroundStyle(Color.white.opacity(0.2))

            Text("No Notes")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.6))

            Text("Create a new note to start capturing your ideas.")
                .font(.system(size: 11.5))
                .foregroundStyle(Color.white.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button {
                createNewNote()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("New Note")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.accentColor, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            Spacer()
        }
    }

    // MARK: - Actions

    private func createNewNote() {
        let note = BrainStormNote(
            title: "New Note",
            bodyText: "",
            folderID: selectedFolderID
        )
        modelContext.insert(note)
        try? modelContext.save()
        selectedNote = note
        Haptics.impact(.medium)
    }

    private func formatDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let df = DateFormatter()
            df.dateFormat = "h:mm a"
            return df.string(from: date)
        } else if cal.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let df = DateFormatter()
            df.dateFormat = "M/d/yy"
            return df.string(from: date)
        }
    }
}
