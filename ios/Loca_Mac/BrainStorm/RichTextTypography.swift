import AppKit
import Foundation

// MARK: - NoteParagraphStyle (Pure Apple Notes Hierarchy)

public enum NoteParagraphStyle: String, CaseIterable, Codable {
    case title = "Title"
    case heading = "Heading"
    case subheading = "Subheading"
    case body = "Body"
    case monostyled = "Monostyled"
    case bulletedList = "Bulleted List"
    case dashedList = "Dashed List"
    case numberedList = "Numbered List"
    case quote = "Block Quote"
    
    public var fontSize: CGFloat {
        switch self {
        case .title: return 26
        case .heading: return 19
        case .subheading: return 15.5
        case .body: return 13.5
        case .monostyled: return 13
        case .bulletedList, .dashedList, .numberedList: return 13.5
        case .quote: return 14
        }
    }
    
    public var fontWeight: NSFont.Weight {
        switch self {
        case .title: return .bold
        case .heading: return .bold
        case .subheading: return .semibold
        case .body: return .regular
        case .monostyled: return .regular
        case .bulletedList, .dashedList, .numberedList: return .regular
        case .quote: return .medium
        }
    }
    
    public var lineSpacing: CGFloat {
        switch self {
        case .title: return 4
        case .heading: return 3
        case .subheading: return 2
        case .body, .bulletedList, .dashedList, .numberedList: return 3
        case .monostyled: return 2
        case .quote: return 3
        }
    }
    
    public var paragraphSpacing: CGFloat {
        switch self {
        case .title: return 10
        case .heading: return 8
        case .subheading: return 6
        case .body, .monostyled: return 5
        case .bulletedList, .dashedList, .numberedList: return 3
        case .quote: return 6
        }
    }
    
    public var listPrefix: String? {
        switch self {
        case .bulletedList: return "• "
        case .dashedList: return "– "
        case .numberedList: return "1. "
        default: return nil
        }
    }
}

// MARK: - TypographyPreset

public enum TypographyPreset: String, CaseIterable, Codable {
    case standard = "Standard"
    case warmJournal = "Warm Journal"
    case monospaced = "Monospaced"
    
    public func font(for style: NoteParagraphStyle) -> NSFont {
        switch self {
        case .standard:
            if style == .monostyled {
                return NSFont.monospacedSystemFont(ofSize: style.fontSize, weight: style.fontWeight)
            }
            return NSFont.systemFont(ofSize: style.fontSize, weight: style.fontWeight)
            
        case .warmJournal:
            if style == .monostyled {
                return NSFont.monospacedSystemFont(ofSize: style.fontSize, weight: style.fontWeight)
            }
            if let serif = NSFont(name: "Georgia", size: style.fontSize + 1) {
                let descriptor = serif.fontDescriptor.withSymbolicTraits(style.fontWeight == .bold ? .bold : [])
                return NSFont(descriptor: descriptor, size: style.fontSize + 1) ?? serif
            }
            let descriptor = NSFont.systemFont(ofSize: style.fontSize + 1, weight: style.fontWeight).fontDescriptor.withDesign(.serif)
            return descriptor.flatMap { NSFont(descriptor: $0, size: style.fontSize + 1) } ?? NSFont.systemFont(ofSize: style.fontSize + 1, weight: style.fontWeight)
            
        case .monospaced:
            return NSFont.monospacedSystemFont(ofSize: style.fontSize, weight: style.fontWeight)
        }
    }
}

// MARK: - RichTextTypography Helper Utilities

public struct RichTextTypography {
    
    public static let checklistCheckedGlyph = "● "
    public static let checklistUncheckedGlyph = "○ "
    
    // MARK: Paragraph Style Attributes
    
    public static func makeParagraphStyle(for style: NoteParagraphStyle, preset: TypographyPreset = .standard) -> NSParagraphStyle {
        let p = NSMutableParagraphStyle()
        p.lineSpacing = style.lineSpacing
        p.paragraphSpacing = style.paragraphSpacing
        
        switch style {
        case .quote:
            p.headIndent = 18
            p.firstLineHeadIndent = 18
        case .bulletedList, .dashedList:
            p.headIndent = 20
            p.firstLineHeadIndent = 0
        case .numberedList:
            p.headIndent = 24
            p.firstLineHeadIndent = 0
        default:
            p.headIndent = 0
            p.firstLineHeadIndent = 0
        }
        return p
    }
    
    // MARK: Apply Paragraph Styles
    
    public static func applyParagraphStyle(_ style: NoteParagraphStyle, to textStorage: NSMutableAttributedString, range: NSRange, preset: TypographyPreset = .standard) {
        guard range.location != NSNotFound && range.length > 0 else { return }
        let totalLength = textStorage.length
        guard range.location < totalLength else { return }
        let safeRange = NSRange(location: range.location, length: min(range.length, totalLength - range.location))
        
        textStorage.beginEditing()
        
        let pStyle = makeParagraphStyle(for: style, preset: preset)
        let font = preset.font(for: style)
        
        textStorage.addAttribute(.paragraphStyle, value: pStyle, range: safeRange)
        textStorage.addAttribute(.font, value: font, range: safeRange)
        
        // Custom marks per style
        switch style {
        case .title, .heading, .subheading:
            textStorage.removeAttribute(.strikethroughStyle, range: safeRange)
            textStorage.removeAttribute(.underlineStyle, range: safeRange)
            textStorage.removeAttribute(.backgroundColor, range: safeRange)
            textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: safeRange)
        case .body:
            textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: safeRange)
        case .monostyled:
            textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: safeRange)
        case .quote:
            textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: safeRange)
        case .bulletedList:
            let string = textStorage.string as NSString
            if safeRange.location + safeRange.length <= string.length {
                let line = string.substring(with: safeRange)
                if !line.hasPrefix("• ") {
                    let clean = cleanPrefixes(from: line)
                    textStorage.replaceCharacters(in: safeRange, with: "• " + clean)
                }
            }
        case .dashedList:
            let string = textStorage.string as NSString
            if safeRange.location + safeRange.length <= string.length {
                let line = string.substring(with: safeRange)
                if !line.hasPrefix("– ") {
                    let clean = cleanPrefixes(from: line)
                    textStorage.replaceCharacters(in: safeRange, with: "– " + clean)
                }
            }
        case .numberedList:
            let string = textStorage.string as NSString
            if safeRange.location + safeRange.length <= string.length {
                let line = string.substring(with: safeRange)
                if line.range(of: #"^\d+\.\s"#, options: .regularExpression) == nil {
                    let clean = cleanPrefixes(from: line)
                    textStorage.replaceCharacters(in: safeRange, with: "1. " + clean)
                }
            }
        default: break
        }
        
        textStorage.endEditing()
    }
    
    private static func cleanPrefixes(from text: String) -> String {
        var result = text
        let prefixes = ["○ ", "● ", "☐ ", "☑︎ ", "☑ ", "• ", "– ", "1. ", "2. ", "3. ", "4. ", "5. "]
        for p in prefixes {
            if result.hasPrefix(p) {
                result = String(result.dropFirst(p.count))
                break
            }
        }
        return result
    }
    
    public static func defaultAttributes(for style: NoteParagraphStyle = .body, preset: TypographyPreset = .standard, textColor: NSColor = .textColor) -> [NSAttributedString.Key: Any] {
        let font = preset.font(for: style)
        let paragraph = makeParagraphStyle(for: style, preset: preset)
        
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraph,
            .foregroundColor: textColor
        ]
        
        if style == .quote {
            attrs[.foregroundColor] = textColor.withAlphaComponent(0.85)
        }
        
        return attrs
    }
    
    // MARK: Apply Paragraph Style to Range
    
    public static func applyParagraphStyle(_ style: NoteParagraphStyle, to textStorage: NSMutableAttributedString, range: NSRange, preset: TypographyPreset = .standard, textColor: NSColor = .textColor) {
        guard range.location != NSNotFound else { return }
        let currentLen = textStorage.length
        guard currentLen > 0 && range.location <= currentLen else { return }
        
        let safeInputRange = NSRange(location: min(range.location, currentLen), length: min(range.length, max(0, currentLen - range.location)))
        
        textStorage.beginEditing()
        let string = textStorage.string as NSString
        let paragraphRange = string.paragraphRange(for: safeInputRange)
        
        // If it's a list style, ensure prefix is present
        if let prefix = style.listPrefix, paragraphRange.location + paragraphRange.length <= string.length {
            let paragraphText = string.substring(with: paragraphRange)
            // Strip any existing list/checklist prefixes first
            let cleanText = cleanPrefixes(from: paragraphText)
            let newParagraphText = prefix + cleanText
            textStorage.replaceCharacters(in: paragraphRange, with: newParagraphText)
        }
        
        let newString = textStorage.string as NSString
        let finalLen = newString.length
        guard finalLen > 0 else {
            textStorage.endEditing()
            return
        }
        
        let safeTargetRange = NSRange(location: min(safeInputRange.location, finalLen - 1), length: min(safeInputRange.length, finalLen - min(safeInputRange.location, finalLen - 1)))
        let updatedParagraphRange = newString.paragraphRange(for: safeTargetRange)
        
        guard updatedParagraphRange.location + updatedParagraphRange.length <= finalLen else {
            textStorage.endEditing()
            return
        }
        
        let newFont = preset.font(for: style)
        let newParagraphStyle = makeParagraphStyle(for: style, preset: preset)
        
        textStorage.addAttribute(.paragraphStyle, value: newParagraphStyle, range: updatedParagraphRange)
        
        // Update font sizes across existing runs while keeping bold/italic traits if applicable
        textStorage.enumerateAttribute(.font, in: updatedParagraphRange, options: []) { currentFontObj, subRange, _ in
            guard subRange.location + subRange.length <= textStorage.length else { return }
            if let currentFont = currentFontObj as? NSFont {
                let traits = currentFont.fontDescriptor.symbolicTraits
                var descriptor = newFont.fontDescriptor
                if traits.contains(.bold) {
                    descriptor = descriptor.withSymbolicTraits(.bold)
                }
                if traits.contains(.italic) {
                    descriptor = descriptor.withSymbolicTraits(.italic)
                }
                let adjustedFont = NSFont(descriptor: descriptor, size: newFont.pointSize) ?? newFont
                textStorage.addAttribute(.font, value: adjustedFont, range: subRange)
            } else {
                textStorage.addAttribute(.font, value: newFont, range: subRange)
            }
        }
        
        textStorage.endEditing()
    }
    

    // MARK: Inline Trait Toggling (Bold / Italic)
    
    public static func toggleTrait(_ trait: NSFontDescriptor.SymbolicTraits, in textStorage: NSMutableAttributedString, range: NSRange, defaultFont: NSFont) {
        guard range.location != NSNotFound && range.length > 0 && range.location + range.length <= textStorage.length else { return }
        textStorage.beginEditing()
        
        // 1. Check if all characters in selection currently have this trait
        var allHaveTrait = true
        textStorage.enumerateAttribute(.font, in: range, options: []) { value, _, stop in
            let font = (value as? NSFont) ?? defaultFont
            if !font.fontDescriptor.symbolicTraits.contains(trait) {
                allHaveTrait = false
                stop.pointee = true
            }
        }
        
        // 2. Toggle trait across selection
        textStorage.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
            guard subRange.location + subRange.length <= textStorage.length else { return }
            let font = (value as? NSFont) ?? defaultFont
            var currentTraits = font.fontDescriptor.symbolicTraits
            if allHaveTrait {
                currentTraits.remove(trait)
            } else {
                currentTraits.insert(trait)
            }
            
            let descriptor = font.fontDescriptor.withSymbolicTraits(currentTraits)
            let newFont = NSFont(descriptor: descriptor, size: font.pointSize) ?? font
            textStorage.addAttribute(.font, value: newFont, range: subRange)
        }
        
        textStorage.endEditing()
    }
    
    // MARK: Underline & Strikethrough
    
    public static func toggleUnderline(in textStorage: NSMutableAttributedString, range: NSRange) {
        guard range.location != NSNotFound && range.length > 0 && range.location + range.length <= textStorage.length else { return }
        textStorage.beginEditing()
        var allUnderlined = true
        textStorage.enumerateAttribute(.underlineStyle, in: range, options: []) { value, _, stop in
            if let val = value as? Int, val != 0 {
                // has underline
            } else {
                allUnderlined = false
                stop.pointee = true
            }
        }
        
        let newStyle = allUnderlined ? 0 : NSUnderlineStyle.single.rawValue
        textStorage.addAttribute(.underlineStyle, value: newStyle, range: range)
        textStorage.endEditing()
    }
    
    public static func toggleStrikethrough(in textStorage: NSMutableAttributedString, range: NSRange) {
        guard range.location != NSNotFound && range.length > 0 && range.location + range.length <= textStorage.length else { return }
        textStorage.beginEditing()
        var allStruck = true
        textStorage.enumerateAttribute(.strikethroughStyle, in: range, options: []) { value, _, stop in
            if let val = value as? Int, val != 0 {
                // has strikethrough
            } else {
                allStruck = false
                stop.pointee = true
            }
        }
        
        let newStyle = allStruck ? 0 : NSUnderlineStyle.single.rawValue
        textStorage.addAttribute(.strikethroughStyle, value: newStyle, range: range)
        textStorage.endEditing()
    }
    
    // MARK: Highlight Marker
    
    public static func toggleHighlight(in textStorage: NSMutableAttributedString, range: NSRange) {
        guard range.location != NSNotFound && range.length > 0 && range.location + range.length <= textStorage.length else { return }
        textStorage.beginEditing()
        var allHighlighted = true
        textStorage.enumerateAttribute(.backgroundColor, in: range, options: []) { value, _, stop in
            if value != nil {
                // has highlight
            } else {
                allHighlighted = false
                stop.pointee = true
            }
        }
        
        if allHighlighted {
            textStorage.removeAttribute(.backgroundColor, range: range)
        } else {
            let highlightColor = NSColor.systemYellow.withAlphaComponent(0.35)
            textStorage.addAttribute(.backgroundColor, value: highlightColor, range: range)
        }
        textStorage.endEditing()
    }
    
    // MARK: Text Color
    
    public static func applyTextColor(_ color: NSColor, in textStorage: NSMutableAttributedString, range: NSRange) {
        guard range.location != NSNotFound && range.length > 0 && range.location + range.length <= textStorage.length else { return }
        textStorage.beginEditing()
        textStorage.addAttribute(.foregroundColor, value: color, range: range)
        textStorage.endEditing()
    }
    
    // MARK: Link Attachment
    
    public static func applyLink(url: URL?, in textStorage: NSMutableAttributedString, range: NSRange) {
        guard range.location != NSNotFound && range.length > 0 && range.location + range.length <= textStorage.length else { return }
        textStorage.beginEditing()
        if let url = url {
            textStorage.addAttribute(.link, value: url, range: range)
            textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            textStorage.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: range)
        } else {
            textStorage.removeAttribute(.link, range: range)
            textStorage.removeAttribute(.underlineStyle, range: range)
            textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: range)
        }
        textStorage.endEditing()
    }
    
    // MARK: Checklist Insertion & Toggle
    
    public static func toggleChecklistOnCurrentParagraph(in textStorage: NSMutableAttributedString, selectedRange: NSRange, defaultFont: NSFont) -> NSRange {
        let string = textStorage.string as NSString
        guard string.length > 0 else {
            textStorage.beginEditing()
            textStorage.insert(NSAttributedString(string: checklistUncheckedGlyph, attributes: [.font: defaultFont, .foregroundColor: NSColor.textColor]), at: 0)
            textStorage.endEditing()
            return NSRange(location: (checklistUncheckedGlyph as NSString).length, length: 0)
        }
        
        let safeSelectedRange = NSRange(location: min(selectedRange.location, string.length), length: min(selectedRange.length, string.length - min(selectedRange.location, string.length)))
        
        textStorage.beginEditing()
        let paragraphRange = string.paragraphRange(for: safeSelectedRange)
        guard paragraphRange.location + paragraphRange.length <= string.length else {
            textStorage.endEditing()
            return selectedRange
        }
        
        let paragraphText = string.substring(with: paragraphRange)
        
        var newSelectedRange = safeSelectedRange
        
        let uncheckedPrefixes = [checklistUncheckedGlyph, "☐ "]
        let checkedPrefixes = [checklistCheckedGlyph, "☑︎ ", "☑ "]
        
        if let matchingUnchecked = uncheckedPrefixes.first(where: { paragraphText.hasPrefix($0) }) {
            // Unchecked -> Checked
            let replaceRange = NSRange(location: paragraphRange.location, length: (matchingUnchecked as NSString).length)
            textStorage.replaceCharacters(in: replaceRange, with: checklistCheckedGlyph)
            let strikeLen = max(0, min(paragraphRange.length - replaceRange.length + (checklistCheckedGlyph as NSString).length, textStorage.length - paragraphRange.location))
            let strikeRange = NSRange(location: paragraphRange.location, length: strikeLen)
            if strikeRange.location + strikeRange.length <= textStorage.length {
                textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: strikeRange)
                textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: strikeRange)
            }
        } else if let matchingChecked = checkedPrefixes.first(where: { paragraphText.hasPrefix($0) }) {
            // Checked -> Remove checklist prefix
            let replaceRange = NSRange(location: paragraphRange.location, length: (matchingChecked as NSString).length)
            textStorage.replaceCharacters(in: replaceRange, with: "")
            let cleanLen = max(0, min(paragraphRange.length - replaceRange.length, textStorage.length - paragraphRange.location))
            let cleanRange = NSRange(location: paragraphRange.location, length: cleanLen)
            if cleanRange.location + cleanRange.length <= textStorage.length {
                textStorage.removeAttribute(.strikethroughStyle, range: cleanRange)
                textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: cleanRange)
            }
            newSelectedRange = NSRange(location: max(paragraphRange.location, safeSelectedRange.location - replaceRange.length), length: min(safeSelectedRange.length, max(0, textStorage.length - max(paragraphRange.location, safeSelectedRange.location - replaceRange.length))))
        } else {
            // Add Unchecked Circular Bullet
            textStorage.insert(NSAttributedString(string: checklistUncheckedGlyph, attributes: [.font: defaultFont, .foregroundColor: NSColor.textColor]), at: paragraphRange.location)
            newSelectedRange = NSRange(location: safeSelectedRange.location + (checklistUncheckedGlyph as NSString).length, length: safeSelectedRange.length)
        }
        
        textStorage.endEditing()
        return newSelectedRange
    }
    
    // MARK: RTFD Binary Serialization (RTFD with Attachments)
    
    public static func serializeToRTFD(attributedString: NSAttributedString) -> Data? {
        guard attributedString.length > 0 else { return Data() }
        let fullRange = NSRange(location: 0, length: attributedString.length)
        do {
            let data = try attributedString.data(
                from: fullRange,
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
            )
            return data
        } catch {
            return nil
        }
    }
    
    public static func deserializeFromRTFD(data: Data?) -> NSAttributedString? {
        guard let data = data, !data.isEmpty else { return nil }
        if let attr = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtfd],
            documentAttributes: nil
        ) {
            return attr
        }
        if let attr = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) {
            return attr
        }
        if let plainString = String(data: data, encoding: .utf8) {
            return NSAttributedString(string: plainString)
        }
        return nil
    }
    
    // MARK: Legacy Markdown Migration
    
    public static func convertMarkdownToAttributedString(markdown: String, preset: TypographyPreset = .standard) -> NSAttributedString {
        guard !markdown.isEmpty else { return NSAttributedString() }
        
        let result = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: "\n")
        
        for (index, line) in lines.enumerated() {
            var lineStyle: NoteParagraphStyle = .body
            var lineText = line
            
            if line.hasPrefix("# ") {
                lineStyle = .title
                lineText = String(line.dropFirst(2))
            } else if line.hasPrefix("## ") {
                lineStyle = .heading
                lineText = String(line.dropFirst(3))
            } else if line.hasPrefix("### ") {
                lineStyle = .subheading
                lineText = String(line.dropFirst(4))
            } else if line.hasPrefix("> ") {
                lineStyle = .quote
                lineText = String(line.dropFirst(2))
            } else if line.hasPrefix("- [ ] ") {
                lineText = checklistUncheckedGlyph + String(line.dropFirst(6))
            } else if line.hasPrefix("- [x] ") || line.hasPrefix("- [X] ") {
                lineText = checklistCheckedGlyph + String(line.dropFirst(6))
            } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
                lineStyle = .bulletedList
                lineText = "• " + String(line.dropFirst(2))
            }
            
            let attrs = defaultAttributes(for: lineStyle, preset: preset)
            let attrLine = NSMutableAttributedString(string: lineText, attributes: attrs)
            result.append(attrLine)
            
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n", attributes: defaultAttributes(for: .body, preset: preset)))
            }
        }
        
        return result
    }
    
    public static func convertAttributedStringToMarkdown(attributedString: NSAttributedString) -> String {
        let string = attributedString.string
        guard !string.isEmpty && attributedString.length > 0 else { return "" }
        
        var markdown = ""
        let nsString = string as NSString
        var location = 0
        
        while location < nsString.length {
            let paragraphRange = nsString.paragraphRange(for: NSRange(location: location, length: 0))
            guard paragraphRange.location + paragraphRange.length <= nsString.length else { break }
            let paragraphText = nsString.substring(with: paragraphRange)
            let trimmedText = paragraphText.trimmingCharacters(in: .newlines)
            
            if !trimmedText.isEmpty {
                var prefix = ""
                if paragraphRange.location < attributedString.length,
                   let font = attributedString.attribute(.font, at: paragraphRange.location, effectiveRange: nil) as? NSFont {
                    if font.pointSize >= 24 {
                        prefix = "# "
                    } else if font.pointSize >= 18 {
                        prefix = "## "
                    } else if font.pointSize >= 15 {
                        prefix = "### "
                    }
                }
                
                var clean = trimmedText
                if clean.hasPrefix(checklistUncheckedGlyph) {
                    clean = "- [ ] " + clean.dropFirst(checklistUncheckedGlyph.count)
                } else if clean.hasPrefix(checklistCheckedGlyph) {
                    clean = "- [x] " + clean.dropFirst(checklistCheckedGlyph.count)
                } else if clean.hasPrefix("• ") {
                    clean = "- " + clean.dropFirst(2)
                }
                
                markdown += prefix + clean + "\n"
            } else {
                markdown += "\n"
            }
            guard paragraphRange.length > 0 else { break }
            location = paragraphRange.location + paragraphRange.length
        }
        
        return markdown.trimmingCharacters(in: .newlines)
    }
}
