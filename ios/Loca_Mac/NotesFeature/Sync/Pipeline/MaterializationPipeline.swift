import Foundation

/// Pipeline that takes a CRDTDoc (Source of Truth), materializes it into domain structures, and syncs the Phase 1 SQLite read-view.
public final class MaterializationPipeline: Sendable {
    
    private let store: LocalNotesStore
    private let eventBus: NotesEventBus
    
    public init(store: LocalNotesStore, eventBus: NotesEventBus) {
        self.store = store
        self.eventBus = eventBus
    }
    
    @discardableResult
    public func materialize(doc: CRDTDoc) async throws -> Note {
        let content = CRDTTranslator.materializeContent(from: doc)
        let plainText = NoteTextExtractor.plainText(from: content)
        let preview = NotePreviewGenerator.preview(from: plainText)
        let now = Date()
        
        // Fetch existing note to preserve creation date if present
        let existing = try await store.fetchNoteRow(id: doc.id.raw.uuidString)
        let createdAt = existing.map { Date(timeIntervalSince1970: $0.createdAt) } ?? now
        let sortKey = existing?.sortKey ?? String(format: "%014.3f", now.timeIntervalSince1970)
        let schemaVer = existing?.schemaVersion ?? 1
        
        let note = Note(
            id: doc.id,
            folderID: doc.folderID,
            title: doc.title,
            content: content,
            plainTextCache: plainText,
            preview: preview,
            isPinned: doc.isPinned,
            isLocked: false,
            isDeleted: doc.isDeleted,
            createdAt: createdAt,
            updatedAt: now,
            deletedAt: doc.isDeleted ? now : nil,
            sortKey: sortKey,
            schemaVersion: schemaVer,
            clientUpdatedAt: now,
            deviceID: doc.deviceID
        )
        
        let row = NotesMappers.noteRow(from: note)
        if existing != nil {
            try await store.updateNoteRow(row)
            eventBus.publish(.noteUpdated(doc.id))
        } else {
            try await store.insertNoteRow(row)
            eventBus.publish(.noteCreated(doc.id))
        }
        
        return note
    }
}
