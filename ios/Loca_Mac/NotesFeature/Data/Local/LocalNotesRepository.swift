import Foundation

/// Concrete repository implementation combining SQLite LocalStore with reactive NotesEventBus.
public final class LocalNotesRepository: NotesRepository, @unchecked Sendable {
    
    private let store: LocalNotesStore
    private let eventBus: NotesEventBus
    
    public init(store: LocalNotesStore, eventBus: NotesEventBus) {
        self.store = store
        self.eventBus = eventBus
    }
    
    // MARK: - Fetch
    
    public func fetchNotes(matching query: NoteQuery) async throws -> [NoteSummary] {
        try await store.fetchNoteSummaries(matching: query)
    }
    
    public func fetchNote(id: NoteID) async throws -> Note? {
        guard let row = try await store.fetchNoteRow(id: id.raw.uuidString) else {
            return nil
        }
        return NotesMappers.note(from: row)
    }
    
    // MARK: - Observation (Live Reactive AsyncStreams)
    
    public func observeNotes(matching query: NoteQuery) -> AsyncStream<[NoteSummary]> {
        AsyncStream { continuation in
            let task = Task {
                // 1. Emit current initial state
                if let initial = try? await self.fetchNotes(matching: query) {
                    continuation.yield(initial)
                }
                
                // 2. Listen to mutation events and re-emit updated results
                for await _ in self.eventBus.events() {
                    guard !Task.isCancelled else { break }
                    if let updated = try? await self.fetchNotes(matching: query) {
                        continuation.yield(updated)
                    }
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    public func observeNote(id: NoteID) -> AsyncStream<Note?> {
        AsyncStream { continuation in
            let task = Task {
                // 1. Emit current initial state
                if let initial = try? await self.fetchNote(id: id) {
                    continuation.yield(initial)
                }
                
                // 2. Listen to mutation events and re-emit updated note
                for await event in self.eventBus.events() {
                    guard !Task.isCancelled else { break }
                    
                    switch event {
                    case .noteUpdated(let targetID),
                         .notePinned(let targetID),
                         .noteMoved(let targetID),
                         .noteRestored(let targetID),
                         .tagsChanged(let targetID):
                        if targetID == id {
                            let note = try? await self.fetchNote(id: id)
                            continuation.yield(note)
                        }
                    case .noteDeleted(let targetID):
                        if targetID == id {
                            let note = try? await self.fetchNote(id: id)
                            continuation.yield(note)
                        }
                    case .notePermanentlyDeleted(let targetID):
                        if targetID == id {
                            continuation.yield(nil)
                        }
                    case .databaseReset:
                        let note = try? await self.fetchNote(id: id)
                        continuation.yield(note)
                    default:
                        break
                    }
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    // MARK: - Mutations
    
    public func apply(_ mutation: NoteMutation) async throws {
        switch mutation {
        case .createNote(let noteID, let folderID):
            let now = Date()
            let content = NoteContent.empty
            let plainText = NoteTextExtractor.plainText(from: content)
            let preview = NotePreviewGenerator.preview(from: plainText)
            
            let note = Note(
                id: noteID,
                folderID: folderID,
                title: "",
                content: content,
                plainTextCache: plainText,
                preview: preview,
                isPinned: false,
                isLocked: false,
                isDeleted: false,
                createdAt: now,
                updatedAt: now,
                deletedAt: nil,
                sortKey: String(format: "%014.3f", now.timeIntervalSince1970),
                schemaVersion: 1,
                clientUpdatedAt: now,
                deviceID: "local-device"
            )
            let row = NotesMappers.noteRow(from: note)
            try await store.insertNoteRow(row)
            eventBus.publish(.noteCreated(noteID))
            
        case .setTitle(let noteID, let title):
            guard var note = try await fetchNote(id: noteID) else {
                throw NotesError.noteNotFound(noteID)
            }
            let now = Date()
            note.title = title
            note.updatedAt = now
            note.clientUpdatedAt = now
            
            let row = NotesMappers.noteRow(from: note)
            try await store.updateNoteRow(row)
            eventBus.publish(.noteUpdated(noteID))
            
        case .updateContent(let noteID, let content):
            guard var note = try await fetchNote(id: noteID) else {
                throw NotesError.noteNotFound(noteID)
            }
            let now = Date()
            let plainText = NoteTextExtractor.plainText(from: content)
            let preview = NotePreviewGenerator.preview(from: plainText)
            
            note.content = content
            note.plainTextCache = plainText
            note.preview = preview
            note.updatedAt = now
            note.clientUpdatedAt = now
            
            let row = NotesMappers.noteRow(from: note)
            try await store.updateNoteRow(row)
            eventBus.publish(.noteUpdated(noteID))
            
        case .move(let noteID, let folderID):
            guard var note = try await fetchNote(id: noteID) else {
                throw NotesError.noteNotFound(noteID)
            }
            let now = Date()
            note.folderID = folderID
            note.updatedAt = now
            note.clientUpdatedAt = now
            
            let row = NotesMappers.noteRow(from: note)
            try await store.updateNoteRow(row)
            eventBus.publish(.noteMoved(noteID))
            
        case .setPinned(let noteID, let isPinned):
            guard var note = try await fetchNote(id: noteID) else {
                throw NotesError.noteNotFound(noteID)
            }
            let now = Date()
            note.isPinned = isPinned
            note.updatedAt = now
            note.clientUpdatedAt = now
            
            let row = NotesMappers.noteRow(from: note)
            try await store.updateNoteRow(row)
            eventBus.publish(.notePinned(noteID))
            
        case .setLocked(let noteID, let isLocked):
            guard var note = try await fetchNote(id: noteID) else {
                throw NotesError.noteNotFound(noteID)
            }
            let now = Date()
            note.isLocked = isLocked
            note.updatedAt = now
            note.clientUpdatedAt = now
            
            let row = NotesMappers.noteRow(from: note)
            try await store.updateNoteRow(row)
            eventBus.publish(.noteUpdated(noteID))
            
        case .markDeleted(let noteID):
            guard var note = try await fetchNote(id: noteID) else {
                throw NotesError.noteNotFound(noteID)
            }
            let now = Date()
            note.isDeleted = true
            note.deletedAt = now
            note.updatedAt = now
            note.clientUpdatedAt = now
            
            let row = NotesMappers.noteRow(from: note)
            try await store.updateNoteRow(row)
            eventBus.publish(.noteDeleted(noteID))
            
        case .restore(let noteID):
            guard var note = try await fetchNote(id: noteID) else {
                throw NotesError.noteNotFound(noteID)
            }
            let now = Date()
            note.isDeleted = false
            note.deletedAt = nil
            note.updatedAt = now
            note.clientUpdatedAt = now
            
            let row = NotesMappers.noteRow(from: note)
            try await store.updateNoteRow(row)
            eventBus.publish(.noteRestored(noteID))
            
        case .permanentlyDelete(let noteID):
            try await store.deleteNoteRow(id: noteID.raw.uuidString)
            eventBus.publish(.notePermanentlyDeleted(noteID))
            
        case .toggleChecklistItem(let noteID, let blockID):
            guard var note = try await fetchNote(id: noteID) else {
                throw NotesError.noteNotFound(noteID)
            }
            
            var mutatedBlocks = note.content.blocks
            var didMutate = false
            
            for (index, block) in mutatedBlocks.enumerated() {
                if case .checklistItem(var item) = block, item.id == blockID {
                    item.isChecked.toggle()
                    mutatedBlocks[index] = .checklistItem(item)
                    didMutate = true
                    break
                }
            }
            
            if didMutate {
                let now = Date()
                let newContent = NoteContent(version: note.content.version, blocks: mutatedBlocks)
                let plainText = NoteTextExtractor.plainText(from: newContent)
                let preview = NotePreviewGenerator.preview(from: plainText)
                
                note.content = newContent
                note.plainTextCache = plainText
                note.preview = preview
                note.updatedAt = now
                note.clientUpdatedAt = now
                
                let row = NotesMappers.noteRow(from: note)
                try await store.updateNoteRow(row)
                eventBus.publish(.noteUpdated(noteID))
            }
        }
    }
    
    // MARK: - Folders
    
    public func fetchFolders() async throws -> [Folder] {
        let rows = try await store.fetchFolderRows()
        return rows.map { NotesMappers.folder(from: $0) }
    }
    
    public func createFolder(name: String, parentID: FolderID?) async throws -> FolderID {
        let id = FolderID()
        let folder = Folder(id: id, name: name, parentID: parentID)
        let row = NotesMappers.folderRow(from: folder)
        try await store.insertFolderRow(row)
        eventBus.publish(.folderCreated(id))
        return id
    }
    
    public func deleteFolder(id: FolderID) async throws {
        try await store.deleteFolderRow(id: id.raw.uuidString)
        eventBus.publish(.folderDeleted(id))
    }
    
    // MARK: - Tags
    
    public func fetchTags() async throws -> [Tag] {
        let rows = try await store.fetchTagRows()
        return rows.map { NotesMappers.tag(from: $0) }
    }
    
    public func createTag(name: String) async throws -> TagID {
        let id = TagID()
        let tag = Tag(id: id, name: name)
        let row = NotesMappers.tagRow(from: tag)
        try await store.insertTagRow(row)
        eventBus.publish(.tagCreated(id))
        return id
    }
    
    public func addTag(_ tagID: TagID, to noteID: NoteID) async throws {
        try await store.addTagToNote(tagID: tagID.raw.uuidString, noteID: noteID.raw.uuidString)
        eventBus.publish(.tagsChanged(noteID))
    }
    
    public func removeTag(_ tagID: TagID, from noteID: NoteID) async throws {
        try await store.removeTagFromNote(tagID: tagID.raw.uuidString, noteID: noteID.raw.uuidString)
        eventBus.publish(.tagsChanged(noteID))
    }
    
    public func fetchTags(for noteID: NoteID) async throws -> [Tag] {
        let rows = try await store.fetchTagsForNote(noteID: noteID.raw.uuidString)
        return rows.map { NotesMappers.tag(from: $0) }
    }
    
    // MARK: - Search
    
    public func searchNotes(term: String) async throws -> [NoteSummary] {
        let query = NoteQuery(
            folderID: nil,
            includeDeleted: false,
            searchText: term,
            tagIDs: [],
            sortOrder: .updatedAtDescending,
            limit: nil
        )
        return try await fetchNotes(matching: query)
    }
}
