import Foundation
import Testing

@Suite("Notes Feature - SQLite Local Repository Tests")
struct RepositoryTests {
    
    private func makeTemporaryRepository() throws -> (LocalNotesRepository, URL) {
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let dbURL = tempDir.appendingPathComponent("test_notes.sqlite")
        
        let db = try NotesDatabase(fileURL: dbURL)
        let store = LocalNotesStore(database: db)
        let eventBus = NotesEventBus()
        let repo = LocalNotesRepository(store: store, eventBus: eventBus)
        return (repo, tempDir)
    }
    
    @Test func testCreateAndFetchNote() async throws {
        let (repo, tempDir) = try makeTemporaryRepository()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let noteID = NoteID()
        try await repo.apply(.createNote(noteID: noteID, folderID: nil))
        
        let fetched = try await repo.fetchNote(id: noteID)
        #expect(fetched != nil)
        #expect(fetched?.id == noteID)
        #expect(fetched?.title == "")
        #expect(fetched?.isDeleted == false)
        #expect(fetched?.isPinned == false)
        
        let summaries = try await repo.fetchNotes(matching: .all)
        #expect(summaries.count == 1)
        #expect(summaries.first?.id == noteID)
    }
    
    @Test func testUpdateTitleAndContent() async throws {
        let (repo, tempDir) = try makeTemporaryRepository()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let noteID = NoteID()
        try await repo.apply(.createNote(noteID: noteID, folderID: nil))
        
        try await repo.apply(.setTitle(noteID: noteID, title: "Executive Plan"))
        
        let blockID = UUID()
        let blocks: [NoteBlock] = [
            .heading(HeadingBlock(text: "Goals", level: 1)),
            .checklistItem(ChecklistItemBlock(id: blockID, text: "Ship Phase 1 Engine", isChecked: false))
        ]
        let content = NoteContent(version: 1, blocks: blocks)
        try await repo.apply(.updateContent(noteID: noteID, content: content))
        
        let updated = try await repo.fetchNote(id: noteID)
        #expect(updated?.title == "Executive Plan")
        #expect(updated?.content.blocks.count == 2)
        #expect(updated?.plainTextCache.contains("Ship Phase 1 Engine") == true)
        
        // Toggle checklist item
        try await repo.apply(.toggleChecklistItem(noteID: noteID, blockID: blockID))
        let toggled = try await repo.fetchNote(id: noteID)
        if case .checklistItem(let item) = toggled?.content.blocks.last {
            #expect(item.isChecked == true)
        } else {
            Issue.record("Expected checklist item block")
        }
    }
    
    @Test func testPinningAndSorting() async throws {
        let (repo, tempDir) = try makeTemporaryRepository()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let note1 = NoteID()
        let note2 = NoteID()
        
        try await repo.apply(.createNote(noteID: note1, folderID: nil))
        try await repo.apply(.setTitle(noteID: note1, title: "Note One"))
        
        try await repo.apply(.createNote(noteID: note2, folderID: nil))
        try await repo.apply(.setTitle(noteID: note2, title: "Note Two"))
        
        // Pin Note 1
        try await repo.apply(.setPinned(noteID: note1, isPinned: true))
        
        let list = try await repo.fetchNotes(matching: .all)
        #expect(list.count == 2)
        #expect(list.first?.id == note1)
        #expect(list.first?.isPinned == true)
    }
    
    @Test func testFoldersAndMoves() async throws {
        let (repo, tempDir) = try makeTemporaryRepository()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let folderID = try await repo.createFolder(name: "Strategy", parentID: nil)
        let folders = try await repo.fetchFolders()
        #expect(folders.count == 1)
        #expect(folders.first?.name == "Strategy")
        
        let noteID = NoteID()
        try await repo.apply(.createNote(noteID: noteID, folderID: nil))
        
        try await repo.apply(.move(noteID: noteID, folderID: folderID))
        let moved = try await repo.fetchNote(id: noteID)
        #expect(moved?.folderID == folderID)
        
        let folderNotes = try await repo.fetchNotes(matching: NoteQuery(folderID: folderID))
        #expect(folderNotes.count == 1)
    }
    
    @Test func testTagAssociations() async throws {
        let (repo, tempDir) = try makeTemporaryRepository()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let tagID = try await repo.createTag(name: "Important")
        let noteID = NoteID()
        try await repo.apply(.createNote(noteID: noteID, folderID: nil))
        
        try await repo.addTag(tagID, to: noteID)
        let tags = try await repo.fetchTags(for: noteID)
        #expect(tags.count == 1)
        #expect(tags.first?.name == "Important")
        
        let taggedNotes = try await repo.fetchNotes(matching: NoteQuery(tagIDs: [tagID]))
        #expect(taggedNotes.count == 1)
        
        try await repo.removeTag(tagID, from: noteID)
        let emptyTags = try await repo.fetchTags(for: noteID)
        #expect(emptyTags.isEmpty)
    }
    
    @Test func testSoftDeleteRestoreAndPermanentPurge() async throws {
        let (repo, tempDir) = try makeTemporaryRepository()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let noteID = NoteID()
        try await repo.apply(.createNote(noteID: noteID, folderID: nil))
        
        // Soft delete
        try await repo.apply(.markDeleted(noteID: noteID))
        
        let activeNotes = try await repo.fetchNotes(matching: .all)
        #expect(activeNotes.isEmpty)
        
        let deletedNotes = try await repo.fetchNotes(matching: .recentlyDeleted)
        #expect(deletedNotes.count == 1)
        #expect(deletedNotes.first?.id == noteID)
        
        // Restore
        try await repo.apply(.restore(noteID: noteID))
        let restoredNotes = try await repo.fetchNotes(matching: .all)
        #expect(restoredNotes.count == 1)
        
        // Permanent Delete
        try await repo.apply(.permanentlyDelete(noteID: noteID))
        let purged = try await repo.fetchNote(id: noteID)
        #expect(purged == nil)
    }
    
    @Test func testSearchNotes() async throws {
        let (repo, tempDir) = try makeTemporaryRepository()
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let noteID = NoteID()
        try await repo.apply(.createNote(noteID: noteID, folderID: nil))
        try await repo.apply(.setTitle(noteID: noteID, title: "Secret Roadmap"))
        
        let content = NoteContent(version: 1, blocks: [.paragraph(ParagraphBlock(text: "Launch date is October 2026"))])
        try await repo.apply(.updateContent(noteID: noteID, content: content))
        
        let titleSearch = try await repo.searchNotes(term: "Roadmap")
        #expect(titleSearch.count == 1)
        
        let bodySearch = try await repo.searchNotes(term: "October")
        #expect(bodySearch.count == 1)
        
        let missSearch = try await repo.searchNotes(term: "NonExistentTermXYZ")
        #expect(missSearch.isEmpty)
    }
}
