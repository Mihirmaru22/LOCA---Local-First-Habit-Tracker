import Foundation
import SQLite3

/// Schema migrations manager for the SQLite notes database.
public enum NotesMigrations {
    
    public static func runMigrations(on db: OpaquePointer?) throws {
        try execute(sql: "PRAGMA foreign_keys = ON;", on: db)
        try execute(sql: "PRAGMA journal_mode = WAL;", on: db)
        
        // Migration v1
        try runMigrationV1(on: db)
    }
    
    private static func runMigrationV1(on db: OpaquePointer?) throws {
        let sql = """
        CREATE TABLE IF NOT EXISTS notes (
            id TEXT PRIMARY KEY,
            folder_id TEXT,
            title TEXT NOT NULL DEFAULT '',
            content_json TEXT NOT NULL,
            plain_text_cache TEXT NOT NULL DEFAULT '',
            preview TEXT NOT NULL DEFAULT '',
            is_pinned INTEGER NOT NULL DEFAULT 0,
            is_locked INTEGER NOT NULL DEFAULT 0,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL,
            deleted_at REAL,
            sort_key TEXT NOT NULL,
            schema_version INTEGER NOT NULL DEFAULT 1,
            client_updated_at REAL NOT NULL,
            device_id TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS folders (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            parent_id TEXT,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );

        CREATE TABLE IF NOT EXISTS tags (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            created_at REAL NOT NULL
        );

        CREATE TABLE IF NOT EXISTS note_tags (
            note_id TEXT NOT NULL,
            tag_id TEXT NOT NULL,
            PRIMARY KEY (note_id, tag_id),
            FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE,
            FOREIGN KEY(tag_id) REFERENCES tags(id) ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS attachments (
            id TEXT PRIMARY KEY,
            note_id TEXT NOT NULL,
            kind TEXT NOT NULL,
            file_path TEXT NOT NULL,
            created_at REAL NOT NULL,
            metadata_json TEXT,
            FOREIGN KEY(note_id) REFERENCES notes(id) ON DELETE CASCADE
        );

        CREATE INDEX IF NOT EXISTS idx_notes_folder ON notes(folder_id);
        CREATE INDEX IF NOT EXISTS idx_notes_updated ON notes(updated_at DESC);
        CREATE INDEX IF NOT EXISTS idx_notes_deleted ON notes(is_deleted);
        CREATE INDEX IF NOT EXISTS idx_notes_pinned ON notes(is_pinned);
        CREATE INDEX IF NOT EXISTS idx_notes_sort ON notes(sort_key);
        """
        
        try execute(sql: sql, on: db)
    }
    
    private static func execute(sql: String, on db: OpaquePointer?) throws {
        guard let db = db else {
            throw NotesError.persistenceFailure("Database connection pointer is null")
        }
        var errorMessage: UnsafeMutablePointer<CChar>? = nil
        let result = sqlite3_exec(db, sql, nil, nil, &errorMessage)
        if result != SQLITE_OK {
            let msg = errorMessage.map { String(cString: $0) } ?? "Unknown SQLite error (code \(result))"
            sqlite3_free(errorMessage)
            throw NotesError.migrationFailure(msg)
        }
    }
}
