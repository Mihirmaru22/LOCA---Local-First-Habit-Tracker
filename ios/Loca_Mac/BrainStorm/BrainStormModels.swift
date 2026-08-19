import Foundation
import SwiftData
import SwiftUI

// MARK: - BrainStormNote (@Model)

@Model
final class BrainStormNote {
    var id: UUID = UUID()
    var title: String = "New Note"
    var bodyText: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // Status flags
    var isPinned: Bool = false
    var isFavorite: Bool = false
    var isLocked: Bool = false
    var isArchived: Bool = false
    var deletedAt: Date? = nil // Non-nil indicates note is in Recently Deleted
    
    // Organization
    var folderID: UUID? = nil
    var tags: [String] = []
    
    // Feature Indicators
    var hasChecklist: Bool = false
    var hasAttachments: Bool = false
    var hasTable: Bool = false
    
    // Typography & Display Preferences
    var fontDesign: String = "system" // "system", "serif", "monospaced"
    var defaultStyle: String = "title" // "title", "heading", "body"
    
    // Structured Data Payloads (JSON)
    var tableDataJSON: String? = nil
    var checklistItemsJSON: String? = nil
    var attachmentsJSON: String? = nil
    // Rich Text Storage
    var bodyRTFData: Data? = nil

    init(
        id: UUID = UUID(),
        title: String = "New Note",
        bodyText: String = "",
        bodyRTFData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false,
        isFavorite: Bool = false,
        isLocked: Bool = false,
        isArchived: Bool = false,
        deletedAt: Date? = nil,
        folderID: UUID? = nil,
        tags: [String] = [],
        hasChecklist: Bool = false,
        hasAttachments: Bool = false,
        hasTable: Bool = false,
        fontDesign: String = "system",
        defaultStyle: String = "title",
        tableDataJSON: String? = nil,
        checklistItemsJSON: String? = nil,
        attachmentsJSON: String? = nil
    ) {
        self.id = id
        self.title = title
        self.bodyText = bodyText
        self.bodyRTFData = bodyRTFData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.isLocked = isLocked
        self.isArchived = isArchived
        self.deletedAt = deletedAt
        self.folderID = folderID
        self.tags = tags
        self.hasChecklist = hasChecklist
        self.hasAttachments = hasAttachments
        self.hasTable = hasTable
        self.fontDesign = fontDesign
        self.defaultStyle = defaultStyle
        self.tableDataJSON = tableDataJSON
        self.checklistItemsJSON = checklistItemsJSON
        self.attachmentsJSON = attachmentsJSON
    }

    /// Read/Write attributed string backed by bodyRTFData
    var attributedBody: NSAttributedString {
        get {
            if let data = bodyRTFData, let attr = RichTextTypography.deserializeFromRTFD(data: data) {
                return attr
            }
            if !bodyText.isEmpty {
                return RichTextTypography.convertMarkdownToAttributedString(markdown: bodyText)
            }
            return NSAttributedString(string: "")
        }
        set {
            self.bodyRTFData = RichTextTypography.serializeToRTFD(attributedString: newValue)
            self.bodyText = newValue.string
            self.updateTitleFromContent()
        }
    }

    /// Automatically extracts and updates note title from the first non-empty line
    func updateTitleFromContent() {
        let lines = bodyText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if let firstLine = lines.first {
            // Strip leading markdown formatting headers (#, ##, -, *, [ ], etc.)
            var clean = firstLine
            if clean.hasPrefix("#") {
                clean = clean.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
            } else if clean.hasPrefix("- [ ] ") || clean.hasPrefix("- [x] ") {
                clean = String(clean.dropFirst(6))
            } else if clean.hasPrefix("- ") || clean.hasPrefix("* ") {
                clean = String(clean.dropFirst(2))
            }
            self.title = clean.isEmpty ? "New Note" : clean
        } else {
            self.title = "New Note"
        }
        
        // Extract inline #tags
        extractTags()
        self.updatedAt = Date()
    }

    /// Extracts all `#tag` patterns from the note body
    func extractTags() {
        let pattern = "(?<=^|\\s)#([a-zA-Z0-9_-]+)"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsString = bodyText as NSString
            let results = regex.matches(in: bodyText, range: NSRange(location: 0, length: nsString.length))
            let extracted = results.map { nsString.substring(with: $0.range(at: 1)).lowercased() }
            self.tags = Array(Set(extracted)).sorted()
        }
    }

    /// Snippet preview for List and Gallery views (generous preview of note contents)
    var previewSnippet: String {
        let lines = bodyText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if lines.count > 1 {
            // Join up to 4 preview lines
            let contentLines = lines.dropFirst().prefix(4)
            let joined = contentLines.joined(separator: " · ")
            return joined.isEmpty ? "No additional text" : joined
        } else if let first = lines.first {
            // If only 1 line, show remaining portion after title
            if first.count > title.count {
                let remainder = String(first.dropFirst(title.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !remainder.isEmpty { return remainder }
            }
        }
        return "No additional text"
    }

    /// True if the note is in active state (not in Recently Deleted)
    var isLive: Bool {
        deletedAt == nil && !isArchived
    }
}

// MARK: - BrainStormFolder (@Model)

@Model
final class BrainStormFolder {
    var id: UUID = UUID()
    var name: String = "Notes"
    var icon: String = "folder"
    var parentFolderID: UUID? = nil
    var createdAt: Date = Date()
    var isSmartFolder: Bool = false
    var smartFolderRulesJSON: String? = nil
    var sortOrder: Int = 0

    init(
        id: UUID = UUID(),
        name: String = "Notes",
        icon: String = "folder",
        parentFolderID: UUID? = nil,
        createdAt: Date = Date(),
        isSmartFolder: Bool = false,
        smartFolderRulesJSON: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.parentFolderID = parentFolderID
        self.createdAt = createdAt
        self.isSmartFolder = isSmartFolder
        self.smartFolderRulesJSON = smartFolderRulesJSON
        self.sortOrder = sortOrder
    }
}

// MARK: - Plain Data Structs for Editor Payloads (JSON Encodable/Decodable)

struct BrainStormTableCell: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var text: String = ""
}

struct BrainStormTableRow: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var cells: [BrainStormTableCell] = []
}

struct BrainStormTable: Codable, Equatable {
    var rows: [BrainStormTableRow] = []
    var hasHeaderRow: Bool = true
    var hasHeaderColumn: Bool = false

    static func makeDefault() -> BrainStormTable {
        var row1 = BrainStormTableRow()
        row1.cells = [BrainStormTableCell(text: "Header 1"), BrainStormTableCell(text: "Header 2")]
        
        var row2 = BrainStormTableRow()
        row2.cells = [BrainStormTableCell(text: ""), BrainStormTableCell(text: "")]
        
        return BrainStormTable(rows: [row1, row2], hasHeaderRow: true, hasHeaderColumn: false)
    }
}

struct BrainStormChecklistItem: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var text: String = ""
    var isCompleted: Bool = false
    var indentLevel: Int = 0
}

struct BrainStormAttachment: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var fileName: String
    var fileSize: Int64
    var fileType: String // "image", "pdf", "file"
    var localPath: String?
    var thumbnailBase64: String?
    var displaySize: String = "medium" // "small", "medium", "large", "fit"
    var createdAt: Date = Date()
}

struct SmartFolderRules: Codable, Equatable {
    var tagFilter: String? = nil
    var requiresChecklist: Bool? = nil
    var requiresAttachments: Bool? = nil
    var requiresLocked: Bool? = nil
    var dateEditedWithinDays: Int? = nil
}
