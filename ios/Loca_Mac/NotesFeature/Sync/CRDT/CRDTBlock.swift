import Foundation

/// CRDT-backed representation of a NoteBlock supporting character-level text merges and LWW attributes.
public struct CRDTBlock: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var type: String // "paragraph", "heading", "checklistItem", "bullet", "divider"
    public var text: CRDTText
    public var attributes: [String: String]
    public var lastModified: Double
    public var isDeleted: Bool
    public var sortKey: String
    
    public init(
        id: UUID = UUID(),
        type: String = "paragraph",
        text: CRDTText = CRDTText(),
        attributes: [String: String] = [:],
        lastModified: Double = Date().timeIntervalSince1970,
        isDeleted: Bool = false,
        sortKey: String = FractionalIndex.initial
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.attributes = attributes
        self.lastModified = lastModified
        self.isDeleted = isDeleted
        self.sortKey = sortKey
    }
    
    /// Merges another block state into this block using CRDT rules.
    public mutating func merge(with other: CRDTBlock) {
        guard self.id == other.id else { return }
        
        // 1. Merge text via RGA
        self.text.merge(with: other.text)
        
        // 2. LWW attribute & type resolution
        if other.lastModified > self.lastModified {
            self.type = other.type
            for (key, val) in other.attributes {
                self.attributes[key] = val
            }
            self.lastModified = other.lastModified
        }
        
        // 3. Tombstone preservation
        if other.isDeleted {
            self.isDeleted = true
        }
    }
}
