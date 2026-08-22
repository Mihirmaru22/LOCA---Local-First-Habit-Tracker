import SwiftUI

/// Main native macOS 2-Column user interface combining the Navigator (Left) and TextKit 2 Editor Canvas (Right).
public struct NotesCanvasView: View {
    
    @ObservedObject public var engine: NotesEngine
    private let autosave = AutosaveCoordinator()
    
    // Navigator state
    @State private var searchText: String = ""
    @State private var selectedFolderID: FolderID? = nil
    @State private var showingDeleted: Bool = false
    @State private var selectedNoteID: NoteID? = nil
    
    @State private var notes: [NoteSummary] = []
    @State private var folders: [Folder] = []
    
    // Active Editor state
    @State private var activeNoteTitle: String = ""
    @State private var activeNoteIsPinned: Bool = false
    @State private var activeNoteFolderID: FolderID? = nil
    @State private var editorState: EditorBridgeState? = nil
    
    public init(engine: NotesEngine = NotesEngine.shared) {
        self.engine = engine
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // Column 1: Navigator (Left)
            NotesNavigatorView(
                searchText: $searchText,
                selectedFolderID: $selectedFolderID,
                showingDeleted: $showingDeleted,
                selectedNoteID: $selectedNoteID,
                notes: notes,
                folders: folders,
                onCreateNote: createNewNote,
                onDeleteNote: deleteNote,
                onCreateFolder: createFolder,
                onDeleteFolder: deleteFolder
            )
            .frame(minWidth: 240, idealWidth: 280, maxWidth: 360)
            
            // 1px Machined Boundary Divider
            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.3))
                .frame(width: 1)
                .allowsHitTesting(false)
            
            // Column 2: Editor Canvas (Right)
            editorColumn
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            await reloadFolders()
        }
        .task(id: queryKey) {
            await observeNotesList()
        }
        .task(id: selectedNoteID) {
            await loadSelectedNote()
        }
    }
    
    private var queryKey: String {
        "\(showingDeleted)-\(selectedFolderID?.raw.uuidString ?? "all")-\(searchText)"
    }
    
    // MARK: - Column 2: Editor Canvas
    
    @ViewBuilder
    private var editorColumn: some View {
        if let state = editorState, selectedNoteID != nil {
            VStack(spacing: 0) {
                // Header
                NoteCanvasHeaderView(
                    title: $activeNoteTitle,
                    folderName: folderName(for: activeNoteFolderID),
                    isPinned: activeNoteIsPinned,
                    onTogglePin: togglePinCurrentNote,
                    onTitleChanged: handleTitleChanged
                )
                
                Divider()
                    .allowsHitTesting(false)
                
                // Formatting Toolbar Strip
                HStack {
                    Spacer()
                    NotesFormattingToolbar(
                        onApplyInlineMark: { type in
                            state.bridge.applyInlineMark(type: type, in: state.currentSelection)
                            handleLocalKeystroke(state.bridge.doc)
                            state.requestFormatRefresh()
                        },
                        onSetBlockType: { type, attrs in
                            state.bridge.setBlockType(type, at: state.currentSelection.location, attributes: attrs)
                            handleLocalKeystroke(state.bridge.doc)
                            state.requestFormatRefresh()
                        },
                        onToggleChecklist: {
                            state.bridge.toggleChecklist(at: state.currentSelection.location)
                            handleLocalKeystroke(state.bridge.doc)
                            state.requestFormatRefresh()
                        }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.35))
                
                Divider()
                    .allowsHitTesting(false)
                
                // Editor Body
                TextKit2EditorRepresentable(
                    state: state,
                    onKeystroke: handleLocalKeystroke,
                    onSelectionChanged: { _ in }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(nsColor: .textBackgroundColor))
        } else {
            emptyCanvasPlaceholder
        }
    }
    
    private var emptyCanvasPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No Note Selected")
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            Button("Create New Note", action: createNewNote)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Keystroke & Mutation Handlers
    
    private func handleLocalKeystroke(_ doc: CRDTDoc) {
        guard let noteID = selectedNoteID else { return }
        
        let content = CRDTTranslator.materializeContent(from: doc)
        let plainText = NoteTextExtractor.plainText(from: content)
        let preview = NotePreviewGenerator.preview(from: plainText)
        
        // Debounced materialization to SQLite (500ms)
        Task {
            await autosave.scheduleMaterialization(for: noteID) { [engine] in
                try? await engine.apply(
                    .materializeFromSync(
                        noteID: noteID,
                        title: doc.title,
                        content: content,
                        plainTextCache: plainText,
                        preview: preview
                    )
                )
            }
        }
    }
    
    private func handleTitleChanged(_ newTitle: String) {
        guard let state = editorState, let noteID = selectedNoteID else { return }
        state.bridge.doc.title = newTitle
        
        Task {
            await autosave.scheduleMaterialization(for: noteID) { [engine] in
                try? await engine.setTitle(newTitle, for: noteID)
            }
        }
    }
    
    private func togglePinCurrentNote() {
        guard let noteID = selectedNoteID else { return }
        let newPinned = !activeNoteIsPinned
        activeNoteIsPinned = newPinned
        editorState?.bridge.doc.isPinned = newPinned
        
        Task {
            try? await engine.setPinned(newPinned, noteID: noteID)
        }
    }
    
    // MARK: - Note & Folder Actions
    
    private func createNewNote() {
        Task {
            if let newID = try? await engine.createNote(in: selectedFolderID) {
                selectedNoteID = newID
            }
        }
    }
    
    private func deleteNote(_ id: NoteID) {
        Task {
            try? await engine.delete(noteID: id)
            if selectedNoteID == id {
                selectedNoteID = nil
            }
        }
    }
    
    private func createFolder(_ name: String) {
        Task {
            _ = try? await engine.createFolder(name: name, parentID: nil)
            await reloadFolders()
        }
    }
    
    private func deleteFolder(_ id: FolderID) {
        Task {
            try? await engine.deleteFolder(id: id)
            if selectedFolderID == id {
                selectedFolderID = nil
            }
            await reloadFolders()
        }
    }
    
    // MARK: - Reactive Data Observation
    
    private func observeNotesList() async {
        let query = NoteQuery(
            folderID: selectedFolderID,
            includeDeleted: showingDeleted,
            searchText: searchText.isEmpty ? nil : searchText,
            tagIDs: [],
            sortOrder: .updatedAtDescending,
            limit: nil
        )
        
        // Initial fetch
        if let initialList = try? await engine.fetchNotes(matching: query) {
            self.notes = initialList
            if selectedNoteID == nil, let first = initialList.first {
                self.selectedNoteID = first.id
            }
        }
        
        for await list in engine.observeNotes(matching: query) {
            self.notes = list
            if selectedNoteID == nil, let first = list.first {
                self.selectedNoteID = first.id
            }
        }
    }
    
    private func loadSelectedNote() async {
        guard let noteID = selectedNoteID else {
            editorState = nil
            return
        }
        
        // Immediate synchronous fetch for instant transition
        if let initialNote = try? await engine.fetchNote(id: noteID) {
            self.activeNoteTitle = initialNote.title
            self.activeNoteIsPinned = initialNote.isPinned
            self.activeNoteFolderID = initialNote.folderID
            
            let doc = CRDTTranslator.crdtDoc(from: initialNote)
            let bridge = TextKitCRDTBridge(doc: doc)
            self.editorState = EditorBridgeState(bridge: bridge)
        }
        
        for await note in engine.observeNote(id: noteID) {
            guard let note = note else { continue }
            self.activeNoteTitle = note.title
            self.activeNoteIsPinned = note.isPinned
            self.activeNoteFolderID = note.folderID
            
            let doc = CRDTTranslator.crdtDoc(from: note)
            if let existingState = self.editorState, existingState.bridge.doc.id == doc.id {
                // DO NOT overwrite or refresh if the content in the active editor is identical
                let currentCRDTContent = CRDTTranslator.materializeContent(from: existingState.bridge.doc)
                if currentCRDTContent != note.content {
                    existingState.updateDocFromRemote(doc)
                }
            } else {
                let bridge = TextKitCRDTBridge(doc: doc)
                self.editorState = EditorBridgeState(bridge: bridge)
            }
        }
    }
    
    private func reloadFolders() async {
        folders = (try? await engine.fetchFolders()) ?? []
    }
    
    private func folderName(for id: FolderID?) -> String? {
        guard let id = id else { return nil }
        return folders.first(where: { $0.id == id })?.name
    }
}
