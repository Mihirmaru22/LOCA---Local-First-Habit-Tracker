import SwiftUI
import SwiftData

// MARK: - MacBrainStormView (3-Column Pure Apple Notes Surface)

struct MacBrainStormView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrainStormNote.updatedAt, order: .reverse) private var allNotes: [BrainStormNote]

    // Navigation & Selection States
    @State private var selectedSystemFolder: SystemFolderType? = .allNotes
    @State private var selectedFolderID: UUID? = nil
    @State private var selectedTag: String? = nil
    @State private var selectedNote: BrainStormNote? = nil

    // Column Visibility Control (Foldable sidebar & list)
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 1. FOLDERS & TAGS SIDEBAR (Left Column)
            BrainStormFolderSidebar(
                selectedSystemFolder: $selectedSystemFolder,
                selectedFolderID: $selectedFolderID,
                selectedTag: $selectedTag
            )
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 280)
        } content: {
            // 2. NOTES LIST / GALLERY COLUMN (Middle Column)
            BrainStormNotesListColumn(
                selectedSystemFolder: selectedSystemFolder,
                selectedFolderID: selectedFolderID,
                selectedTag: selectedTag,
                selectedNote: $selectedNote
            )
            .navigationSplitViewColumnWidth(min: 240, ideal: 290, max: 380)
        } detail: {
            // 3. APPLE NOTES CANVAS EDITOR (Right Detail Column)
            if let note = selectedNote {
                BrainStormEditorView(note: note)
            } else {
                noNoteSelectedPlaceholder
            }
        }
        .navigationTitle("BrainStorm")
        .onAppear {
            if selectedNote == nil, let first = allNotes.first(where: { $0.isLive }) {
                selectedNote = first
            }
        }
    }

    private var noNoteSelectedPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 40))
                .foregroundStyle(Color.white.opacity(0.15))

            Text("No Note Selected")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.4))

            Text("Choose a note from the list or press ⌘N to create a new one.")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.25))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: NSColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)))
    }
}
