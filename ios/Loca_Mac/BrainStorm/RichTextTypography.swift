import AppKit
import Foundation
import SwiftUI

// MARK: - NoteParagraphStyle (Pure Apple Notes Hierarchy)

public enum NoteParagraphStyle: String, CaseIterable, Codable {
    case title = "Title"
    case heading = "Heading"
    case subheading = "Subheading"
    case body = "Body"
    case checklist = "Checklist"
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
        case .body, .checklist: return 14.5
        case .monostyled: return 13.5
        case .bulletedList, .dashedList, .numberedList: return 14
        case .quote: return 14.5
        }
    }
    
    public var fontWeight: NSFont.Weight {
        switch self {
        case .title: return .bold
        case .heading: return .bold
        case .subheading: return .semibold
        case .body, .checklist: return .regular
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
        case .body: return 3
        case .checklist: return 5
        case .bulletedList, .dashedList, .numberedList: return 4
        case .monostyled: return 2
        case .quote: return 3
        }
    }
    
    public var paragraphSpacing: CGFloat {
        switch self {
        case .title: return 10
        case .heading: return 8
        case .subheading: return 6
        case .body: return 5
        case .checklist: return 6
        case .bulletedList, .dashedList, .numberedList: return 4
        case .monostyled: return 4
        case .quote: return 6
        }
    }
    
    public var listPrefix: String? {
        switch self {
        case .checklist: return "○  "
        case .bulletedList: return "•  "
        case .dashedList: return "–  "
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
    
    public static let checklistCheckedGlyph = "●  "
    public static let checklistUncheckedGlyph = "○  "
    
    // MARK: Paragraph Style Attributes
    
    public static func makeParagraphStyle(for style: NoteParagraphStyle, preset: TypographyPreset = .standard) -> NSParagraphStyle {
        let p = NSMutableParagraphStyle()
        p.lineSpacing = style.lineSpacing
        p.paragraphSpacing = style.paragraphSpacing
        
        switch style {
        case .quote:
            p.headIndent = 18
            p.firstLineHeadIndent = 18
        case .checklist:
            p.headIndent = 26
            p.firstLineHeadIndent = 0
        case .bulletedList, .dashedList:
            p.headIndent = 22
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
        textStorage.beginEditing()
        let string = textStorage.string as NSString
        let paragraphRange = string.paragraphRange(for: range)
        
        // If it's a list style, ensure prefix is present
        if let prefix = style.listPrefix {
            let paragraphText = string.substring(with: paragraphRange)
            // Strip any existing list/checklist prefixes first
            let cleanText = cleanPrefixes(from: paragraphText)
            let newParagraphText = prefix + cleanText
            textStorage.replaceCharacters(in: paragraphRange, with: newParagraphText)
        }
        
        let newString = textStorage.string as NSString
        let updatedParagraphRange = newString.paragraphRange(for: range)
        
        let newFont = preset.font(for: style)
        let newParagraphStyle = makeParagraphStyle(for: style, preset: preset)
        
        textStorage.addAttribute(.paragraphStyle, value: newParagraphStyle, range: updatedParagraphRange)
        
        // Update font sizes across existing runs while keeping bold/italic traits if applicable
        textStorage.enumerateAttribute(.font, in: updatedParagraphRange, options: []) { currentFontObj, subRange, _ in
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
    
    private static func cleanPrefixes(from text: String) -> String {
        var result = text
        let prefixes = [checklistUncheckedGlyph, checklistCheckedGlyph, "○ ", "● ", "☐ ", "☑︎ ", "• ", "– ", "1. ", "2. ", "3. ", "4. ", "5. "]
        for p in prefixes {
            if result.hasPrefix(p) {
                result = String(result.dropFirst(p.count))
                break
            }
        }
        return result
    }

    // MARK: Checklist Insertion & Toggle
    
    public static func toggleChecklistOnCurrentParagraph(in textStorage: NSMutableAttributedString, selectedRange: NSRange, defaultFont: NSFont) -> NSRange {
        textStorage.beginEditing()
        let string = textStorage.string as NSString
        let paragraphRange = string.paragraphRange(for: selectedRange)
        let paragraphText = string.substring(with: paragraphRange)
        
        var newSelectedRange = selectedRange
        
        let isUnchecked = paragraphText.hasPrefix(checklistUncheckedGlyph) || paragraphText.hasPrefix("☐ ") || paragraphText.hasPrefix("[ ] ")
        let isChecked = paragraphText.hasPrefix(checklistCheckedGlyph) || paragraphText.hasPrefix("☑︎ ") || paragraphText.hasPrefix("[x] ")
        
        if isUnchecked {
            // Unchecked -> Checked
            let oldPrefix = paragraphText.hasPrefix(checklistUncheckedGlyph) ? checklistUncheckedGlyph : (paragraphText.hasPrefix("☐ ") ? "☐ " : "[ ] ")
            let replaceRange = NSRange(location: paragraphRange.location, length: (oldPrefix as NSString).length)
            textStorage.replaceCharacters(in: replaceRange, with: checklistCheckedGlyph)
            
            let updatedParaRange = (textStorage.string as NSString).paragraphRange(for: selectedRange)
            let prefixLen = (checklistCheckedGlyph as NSString).length
            let textLen = updatedParaRange.length - prefixLen
            
            // Remove strikethrough from the entire paragraph first (glyph never has strike)
            textStorage.removeAttribute(.strikethroughStyle, range: updatedParaRange)
            
            let textSnippet = (textStorage.string as NSString).substring(with: NSRange(location: updatedParaRange.location + prefixLen, length: max(0, textLen))).trimmingCharacters(in: .whitespacesAndNewlines)
            if !textSnippet.isEmpty && textLen > 0 {
                let strikeRange = NSRange(location: updatedParaRange.location + prefixLen, length: textLen)
                textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: strikeRange)
                textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: strikeRange)
            }
        } else if isChecked {
            // Checked -> Remove checklist prefix
            let oldPrefix = paragraphText.hasPrefix(checklistCheckedGlyph) ? checklistCheckedGlyph : (paragraphText.hasPrefix("☑︎ ") ? "☑︎ " : "[x] ")
            let replaceRange = NSRange(location: paragraphRange.location, length: (oldPrefix as NSString).length)
            textStorage.replaceCharacters(in: replaceRange, with: "")
            let cleanRange = NSRange(location: paragraphRange.location, length: paragraphRange.length - replaceRange.length)
            textStorage.removeAttribute(.strikethroughStyle, range: cleanRange)
            textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: cleanRange)
            newSelectedRange = NSRange(location: max(paragraphRange.location, selectedRange.location - replaceRange.length), length: selectedRange.length)
        } else {
            // Add Unchecked Circle with generous checklist paragraph styling
            let cleanText = cleanPrefixes(from: paragraphText)
            let newParaText = checklistUncheckedGlyph + cleanText
            textStorage.replaceCharacters(in: paragraphRange, with: newParaText)
            
            let updatedRange = NSRange(location: paragraphRange.location, length: (newParaText as NSString).length)
            let pStyle = makeParagraphStyle(for: .checklist)
            textStorage.addAttribute(.paragraphStyle, value: pStyle, range: updatedRange)
            newSelectedRange = NSRange(location: selectedRange.location + (checklistUncheckedGlyph as NSString).length, length: selectedRange.length)
        }
        
        textStorage.endEditing()
        return newSelectedRange
    }
    
    // MARK: Inline Trait Toggling (Bold / Italic)
    
    public static func toggleTrait(_ trait: NSFontDescriptor.SymbolicTraits, in textStorage: NSMutableAttributedString, range: NSRange, defaultFont: NSFont) {
        guard range.length > 0 else { return }
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
        guard range.length > 0 else { return }
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
        guard range.length > 0 else { return }
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
    
    // MARK: Highlight Marker (Apple Notes 5-Color Palette)
    
    public enum NoteHighlightColor: String, CaseIterable, Identifiable, Codable {
        case amber = "Amber Gold"
        case emerald = "Emerald Mint"
        case cyan = "Cyan Sky"
        case violet = "Iris Violet"
        case pink = "Coral Pink"
        
        public var id: String { rawValue }
        
        public var color: NSColor {
            switch self {
            case .amber:   return NSColor(red: 1.0, green: 0.84, blue: 0.04, alpha: 0.38)
            case .emerald: return NSColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 0.38)
            case .cyan:    return NSColor(red: 0.0, green: 0.78, blue: 0.75, alpha: 0.38)
            case .violet:  return NSColor(red: 0.69, green: 0.32, blue: 0.87, alpha: 0.38)
            case .pink:    return NSColor(red: 1.0, green: 0.18, blue: 0.33, alpha: 0.38)
            }
        }
        
        public var swiftUIColor: SwiftUI.Color {
            SwiftUI.Color(nsColor: color.withAlphaComponent(1.0))
        }
    }
    
    public static func toggleHighlight(in textStorage: NSMutableAttributedString, range: NSRange, color: NoteHighlightColor = .amber) {
        guard range.length > 0 else { return }
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
            textStorage.addAttribute(.backgroundColor, value: color.color, range: range)
        }
        textStorage.endEditing()
    }
    
    // MARK: Real NSTextAttachment Inline Images
    
    public static func insertImageAttachment(image: NSImage, in textStorage: NSMutableAttributedString, at location: Int, maxDisplayWidth: CGFloat = 520) {
        let attachment = NSTextAttachment()
        
        var targetSize = image.size
        if targetSize.width > maxDisplayWidth && targetSize.width > 0 {
            let ratio = maxDisplayWidth / targetSize.width
            targetSize = NSSize(width: maxDisplayWidth, height: targetSize.height * ratio)
        }
        
        let cell = NSTextAttachmentCell(imageCell: image)
        cell.image = image
        attachment.attachmentCell = cell
        
        let attr = NSMutableAttributedString(string: "\n")
        let imageAttr = NSAttributedString(attachment: attachment)
        attr.append(imageAttr)
        attr.append(NSAttributedString(string: "\n"))
        
        textStorage.beginEditing()
        let safeLocation = min(location, textStorage.length)
        textStorage.insert(attr, at: safeLocation)
        textStorage.endEditing()
    }
    
    // MARK: Text Color
    
    public static func applyTextColor(_ color: NSColor, in textStorage: NSMutableAttributedString, range: NSRange) {
        guard range.length > 0 else { return }
        textStorage.beginEditing()
        textStorage.addAttribute(.foregroundColor, value: color, range: range)
        textStorage.endEditing()
    }
    
    // MARK: Link Attachment
    
    public static func applyLink(url: URL?, in textStorage: NSMutableAttributedString, range: NSRange) {
        guard range.length > 0 else { return }
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
        do {
            let attr = try NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtfd],
                documentAttributes: nil
            )
            return attr
        } catch {
            return nil
        }
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
        guard !string.isEmpty else { return "" }
        
        var markdown = ""
        let nsString = string as NSString
        var location = 0
        
        while location < nsString.length {
            let paragraphRange = nsString.paragraphRange(for: NSRange(location: location, length: 0))
            let paragraphText = nsString.substring(with: paragraphRange)
            let trimmedText = paragraphText.trimmingCharacters(in: .newlines)
            
            if !trimmedText.isEmpty {
                var prefix = ""
                if let font = attributedString.attribute(.font, at: paragraphRange.location, effectiveRange: nil) as? NSFont {
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
            location = paragraphRange.location + paragraphRange.length
        }
        
        return markdown.trimmingCharacters(in: .newlines)
    }
}
