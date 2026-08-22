import Foundation
import SQLite3

/// Actor-isolated local persistence engine executing asynchronous queries against SQLite.
public actor LocalNotesStore {
    
    private let database: NotesDatabase
    
    public init(database: NotesDatabase) {
        self.database = database
    }
    
    // MARK: - Notes Queries
    
    public func fetchNoteRows(matching query: NoteQuery) throws -> [NoteRow] {
        try database.read { db in
            var conditions: [String] = []
            var bindings: [(index: Int32, value: Any)] = []
            var bindIndex: Int32 = 1
            
            // Soft delete condition
            if query.includeDeleted {
                conditions.append("is_deleted = 1")
            } else {
                conditions.append("is_deleted = 0")
            }
            
            // Folder condition
            if let folderID = query.folderID {
                conditions.append("folder_id = ?")
                bindings.append((bindIndex, folderID.raw.uuidString))
                bindIndex += 1
            }
            
            // Search condition
            if let search = query.searchText, !search.trimmingCharacters(in: .whitespaces).isEmpty {
                conditions.append("(title LIKE ? OR plain_text_cache LIKE ?)")
                let pattern = "%\(search)%"
                bindings.append((bindIndex, pattern))
                bindIndex += 1
                bindings.append((bindIndex, pattern))
                bindIndex += 1
            }
            
            // Tags condition
            if !query.tagIDs.isEmpty {
                let tagPlaceholders = Array(repeating: "?", count: query.tagIDs.count).joined(separator: ", ")
                conditions.append("id IN (SELECT note_id FROM note_tags WHERE tag_id IN (\(tagPlaceholders)))")
                for tagID in query.tagIDs {
                    bindings.append((bindIndex, tagID.raw.uuidString))
                    bindIndex += 1
                }
            }
            
            let whereClause = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
            
            // Order by clause
            var orderClause = "ORDER BY is_pinned DESC, "
            switch query.sortOrder {
            case .updatedAtDescending:
                orderClause += "updated_at DESC"
            case .createdAtDescending:
                orderClause += "created_at DESC"
            case .titleAscending:
                orderClause += "title COLLATE NOCASE ASC"
            case .manual:
                orderClause += "sort_key ASC"
            }
            
            var limitClause = ""
            if let limit = query.limit {
                limitClause = "LIMIT \(limit)"
            }
            
            let sql = "SELECT id, folder_id, title, content_json, plain_text_cache, preview, is_pinned, is_locked, is_deleted, created_at, updated_at, deleted_at, sort_key, schema_version, client_updated_at, device_id FROM notes \(whereClause) \(orderClause) \(limitClause);"
            
            let statement = try SQLiteHelper.prepare(sql: sql, on: db)
            defer { sqlite3_finalize(statement) }
            
            for b in bindings {
                if let str = b.value as? String {
                    SQLiteHelper.bind(text: str, at: b.index, statement: statement)
                } else if let int = b.value as? Int {
                    SQLiteHelper.bind(int: int, at: b.index, statement: statement)
                }
            }
            
            var rows: [NoteRow] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                rows.append(readFullNoteRow(from: statement))
            }
            return rows
        }
    }
    
    public func fetchNoteSummaries(matching query: NoteQuery) throws -> [NoteSummary] {
        try database.read { db in
            var conditions: [String] = []
            var bindings: [(index: Int32, value: Any)] = []
            var bindIndex: Int32 = 1
            
            if query.includeDeleted {
                conditions.append("is_deleted = 1")
            } else {
                conditions.append("is_deleted = 0")
            }
            
            if let folderID = query.folderID {
                conditions.append("folder_id = ?")
                bindings.append((bindIndex, folderID.raw.uuidString))
                bindIndex += 1
            }
            
            if let search = query.searchText, !search.trimmingCharacters(in: .whitespaces).isEmpty {
                conditions.append("(title LIKE ? OR plain_text_cache LIKE ?)")
                let pattern = "%\(search)%"
                bindings.append((bindIndex, pattern))
                bindIndex += 1
                bindings.append((bindIndex, pattern))
                bindIndex += 1
            }
            
            if !query.tagIDs.isEmpty {
                let tagPlaceholders = Array(repeating: "?", count: query.tagIDs.count).joined(separator: ", ")
                conditions.append("id IN (SELECT note_id FROM note_tags WHERE tag_id IN (\(tagPlaceholders)))")
                for tagID in query.tagIDs {
                    bindings.append((bindIndex, tagID.raw.uuidString))
                    bindIndex += 1
                }
            }
            
            let whereClause = conditions.isEmpty ? "" : "WHERE " + conditions.joined(separator: " AND ")
            
            var orderClause = "ORDER BY is_pinned DESC, "
            switch query.sortOrder {
            case .updatedAtDescending:
                orderClause += "updated_at DESC"
            case .createdAtDescending:
                orderClause += "created_at DESC"
            case .titleAscending:
                orderClause += "title COLLATE NOCASE ASC"
            case .manual:
                orderClause += "sort_key ASC"
            }
            
            var limitClause = ""
            if let limit = query.limit {
                limitClause = "LIMIT \(limit)"
            }
            
            let sql = "SELECT id, folder_id, title, preview, is_pinned, is_locked, is_deleted, updated_at FROM notes \(whereClause) \(orderClause) \(limitClause);"
            
            let statement = try SQLiteHelper.prepare(sql: sql, on: db)
            defer { sqlite3_finalize(statement) }
            
            for b in bindings {
                if let str = b.value as? String {
                    SQLiteHelper.bind(text: str, at: b.index, statement: statement)
                } else if let int = b.value as? Int {
                    SQLiteHelper.bind(int: int, at: b.index, statement: statement)
                }
            }
            
            var summaries: [NoteSummary] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                let idStr = SQLiteHelper.nonNullText(at: 0, statement: statement)
                let folderIDStr = SQLiteHelper.text(at: 1, statement: statement)
                let title = SQLiteHelper.nonNullText(at: 2, statement: statement)
                let preview = SQLiteHelper.nonNullText(at: 3, statement: statement)
                let isPinned = SQLiteHelper.int(at: 4, statement: statement) != 0
                let isLocked = SQLiteHelper.int(at: 5, statement: statement) != 0
                let isDeleted = SQLiteHelper.int(at: 6, statement: statement) != 0
                let updatedAt = Date(timeIntervalSince1970: SQLiteHelper.nonNullDouble(at: 7, statement: statement))
                
                summaries.append(
                    NoteSummary(
                        id: NoteID(raw: UUID(uuidString: idStr) ?? UUID()),
                        title: title,
                        preview: preview,
                        folderID: folderIDStr.flatMap { UUID(uuidString: $0) }.map { FolderID(raw: $0) },
                        isPinned: isPinned,
                        isLocked: isLocked,
                        isDeleted: isDeleted,
                        updatedAt: updatedAt
                    )
                )
            }
            return summaries
        }
    }
    
    public func fetchNoteRow(id: String) throws -> NoteRow? {
        try database.read { db in
            let sql = "SELECT id, folder_id, title, content_json, plain_text_cache, preview, is_pinned, is_locked, is_deleted, created_at, updated_at, deleted_at, sort_key, schema_version, client_updated_at, device_id FROM notes WHERE id = ? LIMIT 1;"
            let statement = try SQLiteHelper.prepare(sql: sql, on: db)
            defer { sqlite3_finalize(statement) }
            
            SQLiteHelper.bind(text: id, at: 1, statement: statement)
            if sqlite3_step(statement) == SQLITE_ROW {
                return readFullNoteRow(from: statement)
            }
            return nil
        }
    }
    
    public func insertNoteRow(_ row: NoteRow) throws {
        try database.write { db in
            let sql = """
            INSERT INTO notes (id, folder_id, title, content_json, plain_text_cache, preview, is_pinned, is_locked, is_deleted, created_at, updated_at, deleted_at, sort_key, schema_version, client_updated_at, device_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            let statement = try SQLiteHelper.prepare(sql: sql, on: db)
            defer { sqlite3_finalize(statement) }
            
            bindFullNoteRow(row, statement: statement)
            if sqlite3_step(statement) != SQLITE_DONE {
                let msg = String(cString: sqlite3_errmsg(db))
                throw NotesError.persistenceFailure("Failed to insert note: \(msg)")
            }
        }
    }
    
    public func updateNoteRow(_ row: NoteRow) throws {
        try database.write { db in
            let sql = """
            UPDATE notes SET folder_id = ?, title = ?, content_json = ?, plain_text_cache = ?, preview = ?, is_pinned = ?, is_locked = ?, is_deleted = ?, updated_at = ?, deleted_at = ?, sort_key = ?, schema_version = ?, client_updated_at = ?, device_id = ?
            WHERE id = ?;
            """
            let statement = try SQLiteHelper.prepare(sql: sql, on: db)
            defer { sqlite3_finalize(statement) }
            
            SQLiteHelper.bind(text: row.folderID, at: 1, statement: statement)
            SQLiteHelper.bind(text: row.title, at: 2, statement: statement)
            SQLiteHelper.bind(text: row.contentJSON, at: 3, statement: statement)
            SQLiteHelper.bind(text: row.plainTextCache, at: 4, statement: statement)
            SQLiteHelper.bind(text: row.preview, at: 5, statement: statement)
            SQLiteHelper.bind(int: row.isPinned, at: 6, statement: statement)
            SQLiteHelper.bind(int: row.isLocked, at: 7, statement: statement)
            SQLiteHelper.bind(int: row.isDeleted, at: 8, statement: statement)
            SQLiteHelper.bind(double: row.updatedAt, at: 9, statement: statement)
            SQLiteHelper.bind(double: row.deletedAt, at: 10, statement: statement)
            SQLiteHelper.bind(text: row.sortKey, at: 11, statement: statement)
            SQLiteHelper.bind(int: row.schemaVersion, at: 12, statement: statement)
            SQLiteHelper.bind(double: row.clientUpdatedAt, at: 13, statement: statement)
            SQLiteHelper.bind(text: row.deviceID, at: 14, statement: statement)
            SQLiteHelper.bind(text: row.id, at: 15, statement: statement)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                let msg = String(cString: sqlite3_errmsg(db))
                throw NotesError.persistenceFailure("Failed to update note: \(msg)")
            }
        }
    }
    
    public func deleteNoteRow(id: String) throws {
        try database.write { db in
            let sql = "DELETE FROM notes WHERE id = ?;"
            let statement = try SQLiteHelper.prepare(sql: sql, on: db)
            defer { sqlite3_finalize(statement) }
            
            SQLiteHelper.bind(text: id, at: 1, statement: statement)
            if sqlite3_step(statement) != SQLITE_DONE {
                let msg = String(cString: sqlite3_errmsg(db))
                throw NotesError.persistenceFailure("Failed to delete note: \(msg)")
            }
        }
    }
    
    // MARK: - Folders
    
    public func fetchFolderRows() throws -> [FolderRow] {
        try database.read { db in
            let sql = "SELECT id, name, parent_id, created_at, updated_at FROM folders ORDER BY name COLLATE NOCASE ASC;"
            let statement = try SQLiteHelper.prepare(sql: sql, on: db)
            defer { sqlite3_finalize(statement) }
            
            var folders: [FolderRow] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                folders.append(
                    FolderRow(
                        id: SQLiteHelper.nonNullText(at: 0, statement: statement),
                        name: SQLiteHelper.nonNullText(at: 1, statement: statement),
                        parentID: SQLiteHelper.text(at: 2, statement: statement),
                        createdAt: SQLiteHelper.nonNullDouble(at: 3, statement: statement),
                        updatedAt: SQLiteHelper.nonNullDouble(at: 4, statement: statement)
                    )
                )
            }
            return folders
        }
    }
    
    public func insertFolderRow(_ row: FolderRow) throws {
        try database.write { db in
            let sql = "INSERT INTO folders (id, name, parent_id, created_at, updated_at) VALUES (?, ?, ?, ?, ?);"
            let statement = try SQLiteHelper.prepare(sql: sql, on: db)
            defer { sqlite3_finalize(statement) }
            
            SQLiteHelper.bind(text: row.id, at: 1, statement: statement)
            SQLiteHelper.bind(text: row.name, at: 2, statement: statement)
            SQLiteHelper.bind(text: row.parentID, at: 3, statement: statement)
            SQLiteHelper.bind(double: row.createdAt, at: 4, statement: statement)
            SQLiteHelper.bind(double: row.updatedAt, at: 5, statement: statement)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                let msg = String(cString: sqlite3_errmsg(db))
                throw NotesError.persistenceFailure("Failed to insert folder: \(msg)")
            }
        }
    }
    
    public func deleteFolderRow(id: String) throws {
        try database.write { db in
            let sql = "DELETE FROM folders WHERE id = ?;"
            let statement = try SQLiteHelper.prepare(sql: sql, on: db)
            defer { sqlite3_finalize(statement) }
            
            SQLiteHelper.bind(text: id, at: 1, statement: statement)
            if sqlite3_step(statement) != SQLITE_DONE {
                let msg = String(cString: sqlite3_errmsg(db))
                throw NotesError.persistenceFailure("Failed to delete folder: \(msg)")
            }
        }
    }
    
    // MARK: - Tags
    
    public func fetchTagRows() throws -> [TagRow] {
        try database.read { db in
            let sql = "SELECT id, name, created_at FROM tags ORDER BY name COLLATE NOCASE ASC;"
            let statement = try SQLiteHelper.prepare(sql: sql, on: db)
            defer { sqlite3_finalize(statement) }
            
            var tags: [TagRow] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                tags.append(
                    TagRow(
                        id: SQLiteHelper.nonNullText(at: 0, statement: statement),
                        name: SQLiteHelper.nonNullText(at: 1, statement: statement),
                        createdAt: SQLiteHelper.nonNullDouble(at: 2, statement: statement)
                    )
                )
            }
            return tags
        }
    }
    
    public func insertTagRow(_ row: TagRow) throws {
        try database.write { db in
            let sql = "INSERT INTO tags (id, name, created_at) VALUES (?, ?, ?);"
            let statement = try SQLiteHelper.prepare(sql: sql, on: db)
            defer { sqlite3_finalize(statement) }
            
            SQLiteHelper.bind(text: row.id, at: 1, statement: statement)
            SQLiteHelper.bind(text: row.name, at: 2, statement: statement)
            SQLiteHelper.bind(double: row.createdAt, at: 3, statement: statement)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                let msg = String(cString: sqlite3_errmsg(db))
                throw NotesError.persistenceFailure("Failed to insert tag: \(msg)")
            }
        }
    }
    
    public func addTagToNote(tagID: String, noteID: String) throws {
        try database.write { db in
            let sql = "INSERT OR IGNORE INTO note_tags (note_id, tag_id) VALUES (?, ?);"
            let statement = try SQLiteHelper.prepare(sql: sql, on: db)
            defer { sqlite3_finalize(statement) }
            
            SQLiteHelper.bind(text: noteID, at: 1, statement: statement)
            SQLiteHelper.bind(text: tagID, at: 2, statement: statement)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                let msg = String(cString: sqlite3_errmsg(db))
                throw NotesError.persistenceFailure("Failed to associate tag to note: \(msg)")
            }
        }
    }
    
    public func removeTagFromNote(tagID: String, noteID: String) throws {
        try database.write { db in
            let sql = "DELETE FROM note_tags WHERE note_id = ? AND tag_id = ?;"
            let statement = try SQLiteHelper.prepare(sql: sql, on: db)
            defer { sqlite3_finalize(statement) }
            
            SQLiteHelper.bind(text: noteID, at: 1, statement: statement)
            SQLiteHelper.bind(text: tagID, at: 2, statement: statement)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                let msg = String(cString: sqlite3_errmsg(db))
                throw NotesError.persistenceFailure("Failed to remove tag from note: \(msg)")
            }
        }
    }
    
    public func fetchTagsForNote(noteID: String) throws -> [TagRow] {
        try database.read { db in
            let sql = """
            SELECT t.id, t.name, t.created_at
            FROM tags t
            INNER JOIN note_tags nt ON t.id = nt.tag_id
            WHERE nt.note_id = ?
            ORDER BY t.name COLLATE NOCASE ASC;
            """
            let statement = try SQLiteHelper.prepare(sql: sql, on: db)
            defer { sqlite3_finalize(statement) }
            
            SQLiteHelper.bind(text: noteID, at: 1, statement: statement)
            
            var tags: [TagRow] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                tags.append(
                    TagRow(
                        id: SQLiteHelper.nonNullText(at: 0, statement: statement),
                        name: SQLiteHelper.nonNullText(at: 1, statement: statement),
                        createdAt: SQLiteHelper.nonNullDouble(at: 2, statement: statement)
                    )
                )
            }
            return tags
        }
    }
    
    // MARK: - Row Mapping Helpers
    
    private func readFullNoteRow(from statement: OpaquePointer) -> NoteRow {
        NoteRow(
            id: SQLiteHelper.nonNullText(at: 0, statement: statement),
            folderID: SQLiteHelper.text(at: 1, statement: statement),
            title: SQLiteHelper.nonNullText(at: 2, statement: statement),
            contentJSON: SQLiteHelper.nonNullText(at: 3, statement: statement),
            plainTextCache: SQLiteHelper.nonNullText(at: 4, statement: statement),
            preview: SQLiteHelper.nonNullText(at: 5, statement: statement),
            isPinned: SQLiteHelper.int(at: 6, statement: statement),
            isLocked: SQLiteHelper.int(at: 7, statement: statement),
            isDeleted: SQLiteHelper.int(at: 8, statement: statement),
            createdAt: SQLiteHelper.nonNullDouble(at: 9, statement: statement),
            updatedAt: SQLiteHelper.nonNullDouble(at: 10, statement: statement),
            deletedAt: SQLiteHelper.double(at: 11, statement: statement),
            sortKey: SQLiteHelper.nonNullText(at: 12, statement: statement),
            schemaVersion: SQLiteHelper.int(at: 13, statement: statement),
            clientUpdatedAt: SQLiteHelper.nonNullDouble(at: 14, statement: statement),
            deviceID: SQLiteHelper.nonNullText(at: 15, statement: statement)
        )
    }
    
    private func bindFullNoteRow(_ row: NoteRow, statement: OpaquePointer) {
        SQLiteHelper.bind(text: row.id, at: 1, statement: statement)
        SQLiteHelper.bind(text: row.folderID, at: 2, statement: statement)
        SQLiteHelper.bind(text: row.title, at: 3, statement: statement)
        SQLiteHelper.bind(text: row.contentJSON, at: 4, statement: statement)
        SQLiteHelper.bind(text: row.plainTextCache, at: 5, statement: statement)
        SQLiteHelper.bind(text: row.preview, at: 6, statement: statement)
        SQLiteHelper.bind(int: row.isPinned, at: 7, statement: statement)
        SQLiteHelper.bind(int: row.isLocked, at: 8, statement: statement)
        SQLiteHelper.bind(int: row.isDeleted, at: 9, statement: statement)
        SQLiteHelper.bind(double: row.createdAt, at: 10, statement: statement)
        SQLiteHelper.bind(double: row.updatedAt, at: 11, statement: statement)
        SQLiteHelper.bind(double: row.deletedAt, at: 12, statement: statement)
        SQLiteHelper.bind(text: row.sortKey, at: 13, statement: statement)
        SQLiteHelper.bind(int: row.schemaVersion, at: 14, statement: statement)
        SQLiteHelper.bind(double: row.clientUpdatedAt, at: 15, statement: statement)
        SQLiteHelper.bind(text: row.deviceID, at: 16, statement: statement)
    }
}
