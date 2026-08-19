import SwiftUI
import AppKit
import Combine

// MARK: - RichTextEditorController (Live Command Bridge for Apple Notes Engine)

@MainActor
public final class RichTextEditorController: ObservableObject {
    public weak var textView: LocaAppKitTextView?
    public var onTextChange: ((NSAttributedString, String) -> Void)?
    
    // Live Active Formatting States (Observed by Aa Popover & Toolbar)
    @Published public var activeParagraphStyle: NoteParagraphStyle = .body
    @Published public var isBold: Bool = false
    @Published public var isItalic: Bool = false
    @Published public var isUnderlined: Bool = false
    @Published public var isStrikethrough: Bool = false
    @Published public var isHighlighted: Bool = false
    
    public init() {}
    
    // MARK: - Update Active States from Selection
    
    public func updateActiveStates() {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()
        let string = textStorage.string as NSString
        
        let targetLocation = selectedRange.location > 0 ? (selectedRange.location < string.length ? selectedRange.location : string.length - 1) : 0
        
        var newStyle: NoteParagraphStyle = .body
        var newBold = false
        var newItalic = false
        var newUnderlined = false
        var newStrikethrough = false
        var newHighlighted = false
        
        if string.length > 0 && targetLocation < string.length {
            let paragraphRange = string.paragraphRange(for: NSRange(location: targetLocation, length: 0))
            let paragraphText = string.substring(with: paragraphRange)
            
            // Check list prefixes
            if paragraphText.hasPrefix("• ") {
                newStyle = .bulletedList
            } else if paragraphText.hasPrefix("– ") {
                newStyle = .dashedList
            } else if paragraphText.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
                newStyle = .numberedList
            } else if let font = textStorage.attribute(.font, at: targetLocation, effectiveRange: nil) as? NSFont {
                if font.pointSize >= 24 {
                    newStyle = .title
                } else if font.pointSize >= 18 {
                    newStyle = .heading
                } else if font.pointSize >= 15 {
                    newStyle = .subheading
                } else if font.fontDescriptor.symbolicTraits.contains(.monoSpace) {
                    newStyle = .monostyled
                } else {
                    newStyle = .body
                }
            }
            
            // Check inline marks
            if let font = textStorage.attribute(.font, at: targetLocation, effectiveRange: nil) as? NSFont {
                newBold = font.fontDescriptor.symbolicTraits.contains(.bold)
                newItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
            }
            
            let underlineVal = textStorage.attribute(.underlineStyle, at: targetLocation, effectiveRange: nil) as? Int
            newUnderlined = (underlineVal != nil && underlineVal != 0)
            
            let strikeVal = textStorage.attribute(.strikethroughStyle, at: targetLocation, effectiveRange: nil) as? Int
            newStrikethrough = (strikeVal != nil && strikeVal != 0)
            
            let bgVal = textStorage.attribute(.backgroundColor, at: targetLocation, effectiveRange: nil)
            newHighlighted = (bgVal != nil)
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.activeParagraphStyle != newStyle { self.activeParagraphStyle = newStyle }
            if self.isBold != newBold { self.isBold = newBold }
            if self.isItalic != newItalic { self.isItalic = newItalic }
            if self.isUnderlined != newUnderlined { self.isUnderlined = newUnderlined }
            if self.isStrikethrough != newStrikethrough { self.isStrikethrough = newStrikethrough }
            if self.isHighlighted != newHighlighted { self.isHighlighted = newHighlighted }
        }
    }
    
    // MARK: - Paragraph Style
    
    public func applyParagraphStyle(_ style: NoteParagraphStyle, preset: TypographyPreset) {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()
        let paragraphRange = (textStorage.string as NSString).paragraphRange(for: selectedRange)
        
        RichTextTypography.applyParagraphStyle(style, to: textStorage, range: paragraphRange, preset: preset)
        textView.typingAttributes = RichTextTypography.defaultAttributes(for: style, preset: preset)
        textView.didChangeText()
        activeParagraphStyle = style
        onTextChange?(NSAttributedString(attributedString: textStorage), textStorage.string)
    }
    
    // MARK: - Inline Traits
    
    public func toggleBold(preset: TypographyPreset) {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()
        let defaultFont = preset.font(for: activeParagraphStyle)
        
        if selectedRange.length > 0 {
            RichTextTypography.toggleTrait(.bold, in: textStorage, range: selectedRange, defaultFont: defaultFont)
            textView.didChangeText()
            updateActiveStates()
            onTextChange?(NSAttributedString(attributedString: textStorage), textStorage.string)
        } else {
            var currentFont = (textView.typingAttributes[.font] as? NSFont) ?? defaultFont
            var traits = currentFont.fontDescriptor.symbolicTraits
            if traits.contains(.bold) {
                traits.remove(.bold)
                isBold = false
            } else {
                traits.insert(.bold)
                isBold = true
            }
            let descriptor = currentFont.fontDescriptor.withSymbolicTraits(traits)
            let newFont = NSFont(descriptor: descriptor, size: currentFont.pointSize) ?? currentFont
            textView.typingAttributes[.font] = newFont
        }
    }
    
    public func toggleItalic(preset: TypographyPreset) {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()
        let defaultFont = preset.font(for: activeParagraphStyle)
        
        if selectedRange.length > 0 {
            RichTextTypography.toggleTrait(.italic, in: textStorage, range: selectedRange, defaultFont: defaultFont)
            textView.didChangeText()
            updateActiveStates()
            onTextChange?(NSAttributedString(attributedString: textStorage), textStorage.string)
        } else {
            var currentFont = (textView.typingAttributes[.font] as? NSFont) ?? defaultFont
            var traits = currentFont.fontDescriptor.symbolicTraits
            if traits.contains(.italic) {
                traits.remove(.italic)
                isItalic = false
            } else {
                traits.insert(.italic)
                isItalic = true
            }
            let descriptor = currentFont.fontDescriptor.withSymbolicTraits(traits)
            let newFont = NSFont(descriptor: descriptor, size: currentFont.pointSize) ?? currentFont
            textView.typingAttributes[.font] = newFont
        }
    }
    
    public func toggleUnderline() {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()
        if selectedRange.length > 0 {
            RichTextTypography.toggleUnderline(in: textStorage, range: selectedRange)
            textView.didChangeText()
            updateActiveStates()
            onTextChange?(NSAttributedString(attributedString: textStorage), textStorage.string)
        } else {
            let current = (textView.typingAttributes[.underlineStyle] as? Int) ?? 0
            let newVal = (current == 0) ? NSUnderlineStyle.single.rawValue : 0
            textView.typingAttributes[.underlineStyle] = newVal
            isUnderlined = (newVal != 0)
        }
    }
    
    public func toggleStrikethrough() {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()
        if selectedRange.length > 0 {
            RichTextTypography.toggleStrikethrough(in: textStorage, range: selectedRange)
            textView.didChangeText()
            updateActiveStates()
            onTextChange?(NSAttributedString(attributedString: textStorage), textStorage.string)
        } else {
            let current = (textView.typingAttributes[.strikethroughStyle] as? Int) ?? 0
            let newVal = (current == 0) ? NSUnderlineStyle.single.rawValue : 0
            textView.typingAttributes[.strikethroughStyle] = newVal
            isStrikethrough = (newVal != 0)
        }
    }
    
    public func toggleHighlight() {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()
        if selectedRange.length > 0 {
            RichTextTypography.toggleHighlight(in: textStorage, range: selectedRange)
            textView.didChangeText()
            updateActiveStates()
            onTextChange?(NSAttributedString(attributedString: textStorage), textStorage.string)
        } else {
            let current = textView.typingAttributes[.backgroundColor]
            if current != nil {
                textView.typingAttributes.removeValue(forKey: .backgroundColor)
                isHighlighted = false
            } else {
                textView.typingAttributes[.backgroundColor] = NSColor.systemYellow.withAlphaComponent(0.35)
                isHighlighted = true
            }
        }
    }
    
    public func applyTextColor(_ color: NSColor) {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()
        if selectedRange.length > 0 {
            RichTextTypography.applyTextColor(color, in: textStorage, range: selectedRange)
            textView.didChangeText()
            onTextChange?(NSAttributedString(attributedString: textStorage), textStorage.string)
        } else {
            textView.typingAttributes[.foregroundColor] = color
        }
    }
    
    public func toggleChecklist(preset: TypographyPreset) {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()
        let defaultFont = preset.font(for: activeParagraphStyle)
        
        let newRange = RichTextTypography.toggleChecklistOnCurrentParagraph(in: textStorage, selectedRange: selectedRange, defaultFont: defaultFont)
        textView.setSelectedRange(newRange)
        textView.didChangeText()
        updateActiveStates()
        onTextChange?(NSAttributedString(attributedString: textStorage), textStorage.string)
    }
    
    public func insertLink(url: URL, title: String, preset: TypographyPreset) {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()
        
        let linkText = title.isEmpty ? url.absoluteString : title
        let attr = NSMutableAttributedString(string: linkText, attributes: RichTextTypography.defaultAttributes(for: activeParagraphStyle, preset: preset))
        attr.addAttribute(.link, value: url, range: NSRange(location: 0, length: attr.length))
        attr.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: attr.length))
        attr.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: NSRange(location: 0, length: attr.length))
        
        if selectedRange.length > 0 {
            textStorage.replaceCharacters(in: selectedRange, with: attr)
        } else {
            textStorage.insert(attr, at: selectedRange.location)
        }
        textView.didChangeText()
        onTextChange?(NSAttributedString(attributedString: textStorage), textStorage.string)
    }
    
    public func insertTable(rows: Int = 2, cols: Int = 2, preset: TypographyPreset) {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()
        
        var tableString = "\n┌" + String(repeating: "──────────────┬", count: cols - 1) + "──────────────┐\n"
        for r in 0..<rows {
            tableString += "│" + String(repeating: "              │", count: cols) + "\n"
            if r < rows - 1 {
                tableString += "├" + String(repeating: "──────────────┼", count: cols - 1) + "──────────────┤\n"
            }
        }
        tableString += "└" + String(repeating: "──────────────┴", count: cols - 1) + "──────────────┘\n"
        
        let font = preset.font(for: .monostyled)
        let attr = NSAttributedString(string: tableString, attributes: [
            .font: font,
            .foregroundColor: NSColor.textColor
        ])
        
        textStorage.insert(attr, at: selectedRange.location)
        textView.setSelectedRange(NSRange(location: selectedRange.location + attr.length, length: 0))
        textView.didChangeText()
        onTextChange?(NSAttributedString(attributedString: textStorage), textStorage.string)
    }
}

// MARK: - MacRichTextEditor (AppKit NSTextView Wrapper)

public struct MacRichTextEditor: NSViewRepresentable {
    
    @Binding var attributedText: NSAttributedString
    @Binding var plainText: String
    var preset: TypographyPreset = .standard
    var isEditable: Bool = true
    var activeStyle: Binding<NoteParagraphStyle>? = nil
    var controller: RichTextEditorController? = nil
    var onTextChange: ((NSAttributedString, String) -> Void)? = nil
    
    public init(
        attributedText: Binding<NSAttributedString>,
        plainText: Binding<String>,
        preset: TypographyPreset = .standard,
        isEditable: Bool = true,
        activeStyle: Binding<NoteParagraphStyle>? = nil,
        controller: RichTextEditorController? = nil,
        onTextChange: ((NSAttributedString, String) -> Void)? = nil
    ) {
        self._attributedText = attributedText
        self._plainText = plainText
        self.preset = preset
        self.isEditable = isEditable
        self.activeStyle = activeStyle
        self.controller = controller
        self.onTextChange = onTextChange
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        let contentSize = scrollView.contentSize
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(containerSize: NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        
        let textView = LocaAppKitTextView(frame: .zero, textContainer: textContainer)
        textView.minSize = NSSize(width: 0.0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        textView.drawsBackground = false
        textView.isRichText = true
        textView.allowsUndo = true
        textView.usesFontPanel = false
        textView.usesRuler = false
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.delegate = context.coordinator
        
        // Insets & Spacing
        textView.textContainerInset = NSSize(width: 24, height: 16)
        
        // Typing attributes default
        textView.typingAttributes = RichTextTypography.defaultAttributes(for: .body, preset: preset)
        
        // Initial Attributed String
        if attributedText.length > 0 {
            textStorage.setAttributedString(attributedText)
        } else if !plainText.isEmpty {
            let migrated = RichTextTypography.convertMarkdownToAttributedString(markdown: plainText, preset: preset)
            textStorage.setAttributedString(migrated)
            DispatchQueue.main.async {
                self.attributedText = migrated
            }
        }
        
        context.coordinator.textView = textView
        if let ctrl = controller {
            ctrl.textView = textView
            ctrl.onTextChange = onTextChange
            ctrl.updateActiveStates()
        }
        
        scrollView.documentView = textView
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? LocaAppKitTextView else { return }
        
        context.coordinator.parent = self
        if let ctrl = controller {
            ctrl.textView = textView
            ctrl.onTextChange = onTextChange
        }
        
        textView.isEditable = isEditable
        
        // Skip expensive comparisons if the user is actively typing locally
        if context.coordinator.isTypingLocally { return }
        
        // Only synchronize if content was changed externally (e.g. switching notes)
        if !context.coordinator.isUpdatingDirectly {
            let currentText = textView.textStorage?.string ?? ""
            if currentText != plainText {
                context.coordinator.isUpdatingDirectly = true
                let savedSelection = textView.selectedRange()
                
                if attributedText.length > 0 {
                    textView.textStorage?.setAttributedString(attributedText)
                } else if !plainText.isEmpty {
                    let parsed = RichTextTypography.convertMarkdownToAttributedString(markdown: plainText, preset: preset)
                    textView.textStorage?.setAttributedString(parsed)
                } else {
                    textView.textStorage?.setAttributedString(NSAttributedString())
                }
                
                if savedSelection.location <= (textView.textStorage?.length ?? 0) {
                    textView.setSelectedRange(savedSelection)
                }
                context.coordinator.isUpdatingDirectly = false
            }
        }
    }
    
    // MARK: - Coordinator
    
    public class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacRichTextEditor
        weak var textView: LocaAppKitTextView?
        var isUpdatingDirectly = false
        var isTypingLocally = false
        private var typingResetWorkItem: DispatchWorkItem?
        
        init(_ parent: MacRichTextEditor) {
            self.parent = parent
        }
        
        public func textDidChange(_ notification: Notification) {
            guard let textView = textView, let textStorage = textView.textStorage else { return }
            
            isTypingLocally = true
            isUpdatingDirectly = true
            
            let updatedAttr = NSAttributedString(attributedString: textStorage)
            let updatedPlain = textStorage.string
            
            parent.onTextChange?(updatedAttr, updatedPlain)
            parent.controller?.updateActiveStates()
            
            isUpdatingDirectly = false
            
            // Reset typing lock after typing pauses
            typingResetWorkItem?.cancel()
            let resetWork = DispatchWorkItem { [weak self] in
                self?.isTypingLocally = false
            }
            typingResetWorkItem = resetWork
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: resetWork)
        }
        
        public func textViewDidChangeSelection(_ notification: Notification) {
            parent.controller?.updateActiveStates()
        }
    }
}

// MARK: - LocaAppKitTextView (Subclass for Apple Notes Mechanics)

public final class LocaAppKitTextView: NSTextView {
    
    public override func insertNewline(_ sender: Any?) {
        guard let textStorage = self.textStorage else {
            super.insertNewline(sender)
            return
        }
        
        let selectedRange = self.selectedRange()
        let string = textStorage.string as NSString
        let paragraphRange = string.paragraphRange(for: selectedRange)
        let paragraphText = string.substring(with: paragraphRange)
        
        // 1. Checklist smart continuation
        if paragraphText.hasPrefix(RichTextTypography.checklistUncheckedGlyph) || paragraphText.hasPrefix(RichTextTypography.checklistCheckedGlyph) {
            let prefix = RichTextTypography.checklistUncheckedGlyph
            let contentInLine = paragraphText
                .replacingOccurrences(of: RichTextTypography.checklistUncheckedGlyph, with: "")
                .replacingOccurrences(of: RichTextTypography.checklistCheckedGlyph, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if contentInLine.isEmpty {
                textStorage.replaceCharacters(in: paragraphRange, with: "\n")
                self.setSelectedRange(NSRange(location: paragraphRange.location, length: 0))
                self.didChangeText()
                return
            } else {
                super.insertNewline(sender)
                let font = (self.typingAttributes[.font] as? NSFont) ?? NSFont.systemFont(ofSize: 13.5)
                let checklistAttr = NSAttributedString(string: prefix, attributes: [
                    .font: font,
                    .foregroundColor: NSColor.textColor
                ])
                let newLocation = self.selectedRange().location
                textStorage.insert(checklistAttr, at: newLocation)
                self.setSelectedRange(NSRange(location: newLocation + prefix.count, length: 0))
                self.didChangeText()
                return
            }
        }
        
        // 2. Bullet List smart continuation
        if paragraphText.hasPrefix("• ") {
            let contentInLine = paragraphText.dropFirst(2).trimmingCharacters(in: .whitespacesAndNewlines)
            if contentInLine.isEmpty {
                textStorage.replaceCharacters(in: paragraphRange, with: "\n")
                self.setSelectedRange(NSRange(location: paragraphRange.location, length: 0))
                self.didChangeText()
                return
            } else {
                super.insertNewline(sender)
                let font = (self.typingAttributes[.font] as? NSFont) ?? NSFont.systemFont(ofSize: 13.5)
                let bulletAttr = NSAttributedString(string: "• ", attributes: [
                    .font: font,
                    .foregroundColor: NSColor.textColor
                ])
                let newLocation = self.selectedRange().location
                textStorage.insert(bulletAttr, at: newLocation)
                self.setSelectedRange(NSRange(location: newLocation + 2, length: 0))
                self.didChangeText()
                return
            }
        }
        
        // 3. Dashed List smart continuation
        if paragraphText.hasPrefix("– ") {
            let contentInLine = paragraphText.dropFirst(2).trimmingCharacters(in: .whitespacesAndNewlines)
            if contentInLine.isEmpty {
                textStorage.replaceCharacters(in: paragraphRange, with: "\n")
                self.setSelectedRange(NSRange(location: paragraphRange.location, length: 0))
                self.didChangeText()
                return
            } else {
                super.insertNewline(sender)
                let font = (self.typingAttributes[.font] as? NSFont) ?? NSFont.systemFont(ofSize: 13.5)
                let dashAttr = NSAttributedString(string: "– ", attributes: [
                    .font: font,
                    .foregroundColor: NSColor.textColor
                ])
                let newLocation = self.selectedRange().location
                textStorage.insert(dashAttr, at: newLocation)
                self.setSelectedRange(NSRange(location: newLocation + 2, length: 0))
                self.didChangeText()
                return
            }
        }
        
        // 4. Numbered List smart continuation
        if let match = paragraphText.range(of: #"^(\d+)\.\s"#, options: .regularExpression) {
            let numString = paragraphText[match].dropLast(2)
            if let num = Int(numString) {
                let contentInLine = paragraphText[match.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                if contentInLine.isEmpty {
                    textStorage.replaceCharacters(in: paragraphRange, with: "\n")
                    self.setSelectedRange(NSRange(location: paragraphRange.location, length: 0))
                    self.didChangeText()
                    return
                } else {
                    super.insertNewline(sender)
                    let nextPrefix = "\(num + 1). "
                    let font = (self.typingAttributes[.font] as? NSFont) ?? NSFont.systemFont(ofSize: 13.5)
                    let numAttr = NSAttributedString(string: nextPrefix, attributes: [
                        .font: font,
                        .foregroundColor: NSColor.textColor
                    ])
                    let newLocation = self.selectedRange().location
                    textStorage.insert(numAttr, at: newLocation)
                    self.setSelectedRange(NSRange(location: newLocation + nextPrefix.count, length: 0))
                    self.didChangeText()
                    return
                }
            }
        }
        
        super.insertNewline(sender)
    }
    
    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let layoutManager = self.layoutManager, let textContainer = self.textContainer, let textStorage = self.textStorage else {
            super.mouseDown(with: event)
            return
        }
        
        let glyphIndex = layoutManager.glyphIndex(for: point, in: textContainer)
        let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
        
        let string = textStorage.string as NSString
        guard charIndex < string.length else {
            super.mouseDown(with: event)
            return
        }
        
        let paragraphRange = string.paragraphRange(for: NSRange(location: charIndex, length: 0))
        let paragraphText = string.substring(with: paragraphRange)
        
        // Click on checklist checkbox glyph
        let unchecked = RichTextTypography.checklistUncheckedGlyph
        let checked = RichTextTypography.checklistCheckedGlyph
        
        if paragraphText.hasPrefix(unchecked) && charIndex < paragraphRange.location + unchecked.count + 2 {
            // Toggle Unchecked -> Checked
            textStorage.beginEditing()
            let glyphRange = NSRange(location: paragraphRange.location, length: (unchecked as NSString).length)
            textStorage.replaceCharacters(in: glyphRange, with: checked)
            let strikeRange = NSRange(location: paragraphRange.location, length: paragraphRange.length)
            textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: strikeRange)
            textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: strikeRange)
            textStorage.endEditing()
            self.didChangeText()
            Haptics.impact(.light)
            return
        } else if paragraphText.hasPrefix(checked) && charIndex < paragraphRange.location + checked.count + 2 {
            // Toggle Checked -> Unchecked
            textStorage.beginEditing()
            let glyphRange = NSRange(location: paragraphRange.location, length: (checked as NSString).length)
            textStorage.replaceCharacters(in: glyphRange, with: unchecked)
            let strikeRange = NSRange(location: paragraphRange.location, length: paragraphRange.length)
            textStorage.removeAttribute(.strikethroughStyle, range: strikeRange)
            textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: strikeRange)
            textStorage.endEditing()
            self.didChangeText()
            Haptics.impact(.light)
            return
        }
        
        super.mouseDown(with: event)
    }
}
