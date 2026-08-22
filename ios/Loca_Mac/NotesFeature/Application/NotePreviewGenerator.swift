import Foundation

/// Pure functional generator producing concise, single-line note previews for list rows.
public enum NotePreviewGenerator {
    
    public static func preview(from plainText: String, limit: Int = 180) -> String {
        let cleaned = plainText
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard cleaned.count > limit else {
            return cleaned
        }
        
        let prefix = cleaned.prefix(limit)
        return String(prefix) + "…"
    }
}
