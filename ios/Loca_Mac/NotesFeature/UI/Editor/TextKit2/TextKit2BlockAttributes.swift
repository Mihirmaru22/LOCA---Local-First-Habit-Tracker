import Foundation
import AppKit

/// Typography, font metrics, and paragraph styling for TextKit 2 block rendering.
public enum TextKit2BlockAttributes {
    
    public static func attributes(for type: String, attributes: [String: String] = [:]) -> [NSAttributedString.Key: Any] {
        var attrs: [NSAttributedString.Key: Any] = [:]
        let style = NSMutableParagraphStyle()
        
        switch type {
        case "heading":
            let level = Int(attributes["level", default: "1"]) ?? 1
            if level == 1 {
                attrs[.font] = NSFont.systemFont(ofSize: 24, weight: .bold)
                attrs[.foregroundColor] = NSColor.labelColor
                style.paragraphSpacingBefore = 12
                style.paragraphSpacing = 6
                style.lineHeightMultiple = 1.15
            } else if level == 2 {
                attrs[.font] = NSFont.systemFont(ofSize: 18, weight: .bold)
                attrs[.foregroundColor] = NSColor.labelColor
                style.paragraphSpacingBefore = 10
                style.paragraphSpacing = 4
                style.lineHeightMultiple = 1.15
            } else {
                attrs[.font] = NSFont.systemFont(ofSize: 15, weight: .semibold)
                attrs[.foregroundColor] = NSColor.labelColor
                style.paragraphSpacingBefore = 8
                style.paragraphSpacing = 3
                style.lineHeightMultiple = 1.15
            }
            
        case "checklistItem":
            let isChecked = attributes["isChecked"] == "true"
            attrs[.font] = NSFont.systemFont(ofSize: 14, weight: .regular)
            
            if isChecked {
                attrs[.foregroundColor] = NSColor.secondaryLabelColor
                attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                attrs[.strikethroughColor] = NSColor.secondaryLabelColor
            } else {
                attrs[.foregroundColor] = NSColor.labelColor
            }
            
            style.headIndent = 24
            style.firstLineHeadIndent = 24
            style.paragraphSpacing = 4
            style.lineHeightMultiple = 1.2
            
        case "bullet":
            attrs[.font] = NSFont.systemFont(ofSize: 14, weight: .regular)
            attrs[.foregroundColor] = NSColor.labelColor
            style.headIndent = 18
            style.firstLineHeadIndent = 18
            style.paragraphSpacing = 4
            style.lineHeightMultiple = 1.2
            
        case "divider":
            attrs[.font] = NSFont.systemFont(ofSize: 8, weight: .regular)
            attrs[.foregroundColor] = NSColor.separatorColor
            style.paragraphSpacingBefore = 6
            style.paragraphSpacing = 6
            
        default: // "paragraph"
            attrs[.font] = NSFont.systemFont(ofSize: 14, weight: .regular)
            attrs[.foregroundColor] = NSColor.labelColor
            style.paragraphSpacing = 4
            style.lineHeightMultiple = 1.2
        }
        
        attrs[.paragraphStyle] = style
        return attrs
    }
}
