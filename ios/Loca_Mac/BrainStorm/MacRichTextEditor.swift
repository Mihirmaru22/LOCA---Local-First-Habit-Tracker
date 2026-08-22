import SwiftUI
import AppKit
import Combine

// MARK: - RichTextEditorController (Live Command Bridge for Apple Notes Engine)

@MainActor
public final class RichTextEditorController: ObservableObject {
    public weak var textView: LocaAppKitTextView?
    public var onTextChange: ((NSAttributedString, String) -> Void)?
    public var onSlashTriggered: ((CGPoint) -> Void)?
    
    // Live Active Formatting States (Observed by Aa Popover & Toolbar)
    @Published public var activeParagraphStyle: NoteParagraphStyle = .body
    @Published public var isBold: Bool = false
    @Published public var isItalic: Bool = false
    @Published public var isUnderlined: Bool = false
    @Published public var isStrikethrough: Bool = false
    @Published public var isHighlighted: Bool = false
    
    private var stateUpdateWorkItem: DispatchWorkItem?
    
    public init() {}
    
    // MARK: - Update Active States from Selection (Throttled for 120Hz Fluidity)
    
    public func updateActiveStates(immediate: Bool = false) {
        stateUpdateWorkItem?.cancel()
        
        let updateBlock = { [weak self] in
            guard let self = self, let textView = self.textView, let textStorage = textView.textStorage else { return }
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
            
            if self.activeParagraphStyle != newStyle { self.activeParagraphStyle = newStyle }
            if self.isBold != newBold { self.isBold = newBold }
            if self.isItalic != newItalic { self.isItalic = newItalic }
            if self.isUnderlined != newUnderlined { self.isUnderlined = newUnderlined }
            if self.isStrikethrough != newStrikethrough { self.isStrikethrough = newStrikethrough }
            if self.isHighlighted != newHighlighted { self.isHighlighted = newHighlighted }
        }
        
        if immediate {
            updateBlock()
        } else {
            let work = DispatchWorkItem(block: updateBlock)
            stateUpdateWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: work)
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
            updateActiveStates(immediate: true)
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
            updateActiveStates(immediate: true)
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
            updateActiveStates(immediate: true)
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
            updateActiveStates(immediate: true)
            onTextChange?(NSAttributedString(attributedString: textStorage), textStorage.string)
        } else {
            let current = (textView.typingAttributes[.strikethroughStyle] as? Int) ?? 0
            let newVal = (current == 0) ? NSUnderlineStyle.single.rawValue : 0
            textView.typingAttributes[.strikethroughStyle] = newVal
            isStrikethrough = (newVal != 0)
        }
    }
    
    public func toggleHighlight(color: RichTextTypography.NoteHighlightColor = .amber) {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        let selectedRange = textView.selectedRange()
        if selectedRange.length > 0 {
            RichTextTypography.toggleHighlight(in: textStorage, range: selectedRange, color: color)
            textView.didChangeText()
            updateActiveStates(immediate: true)
            onTextChange?(NSAttributedString(attributedString: textStorage), textStorage.string)
        } else {
            let current = textView.typingAttributes[.backgroundColor]
            if current != nil {
                textView.typingAttributes.removeValue(forKey: .backgroundColor)
                isHighlighted = false
            } else {
                textView.typingAttributes[.backgroundColor] = color.color
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
        updateActiveStates(immediate: true)
        onTextChange?(NSAttributedString(attributedString: textStorage), textStorage.string)
    }
    
    public func insertImage(image: NSImage) {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        let location = textView.selectedRange().location
        RichTextTypography.insertImageAttachment(image: image, in: textStorage, at: location)
        textView.didChangeText()
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
    
    // MARK: - In-Note Search Navigation
    
    public func jumpToNextMatch(query: String) {
        guard let textView = textView, let textStorage = textView.textStorage, !query.isEmpty else { return }
        let currentPos = textView.selectedRange().location + textView.selectedRange().length
        let fullString = textStorage.string as NSString
        let searchRange = NSRange(location: currentPos < fullString.length ? currentPos : 0, length: currentPos < fullString.length ? fullString.length - currentPos : fullString.length)
        
        var foundRange = fullString.range(of: query, options: .caseInsensitive, range: searchRange)
        if foundRange.location == NSNotFound && currentPos > 0 {
            // Wrap around
            foundRange = fullString.range(of: query, options: .caseInsensitive, range: NSRange(location: 0, length: fullString.length))
        }
        
        if foundRange.location != NSNotFound {
            textView.setSelectedRange(foundRange)
            textView.scrollRangeToVisible(foundRange)
            textView.showFindIndicator(for: foundRange)
        }
    }
    
    public func jumpToPreviousMatch(query: String) {
        guard let textView = textView, let textStorage = textView.textStorage, !query.isEmpty else { return }
        let currentPos = textView.selectedRange().location
        let fullString = textStorage.string as NSString
        let searchRange = NSRange(location: 0, length: min(currentPos, fullString.length))
        
        var foundRange = fullString.range(of: query, options: [.caseInsensitive, .backwards], range: searchRange)
        if foundRange.location == NSNotFound {
            // Wrap to end
            foundRange = fullString.range(of: query, options: [.caseInsensitive, .backwards], range: NSRange(location: 0, length: fullString.length))
        }
        
        if foundRange.location != NSNotFound {
            textView.setSelectedRange(foundRange)
            textView.scrollRangeToVisible(foundRange)
            textView.showFindIndicator(for: foundRange)
        }
    }
}

// MARK: - MacRichTextEditor (AppKit NSTextView Wrapper with 120Hz Decoupled Pipeline)

public struct MacRichTextEditor: NSViewRepresentable {
    
    let initialAttributedText: NSAttributedString
    let initialPlainText: String
    var preset: TypographyPreset = .standard
    var isEditable: Bool = true
    var controller: RichTextEditorController? = nil
    var onTextChangeDebounced: ((NSAttributedString, String) -> Void)? = nil
    var onSlashTriggered: ((CGPoint) -> Void)? = nil
    
    public init(
        initialAttributedText: NSAttributedString,
        initialPlainText: String,
        preset: TypographyPreset = .standard,
        isEditable: Bool = true,
        controller: RichTextEditorController? = nil,
        onTextChangeDebounced: ((NSAttributedString, String) -> Void)? = nil,
        onSlashTriggered: ((CGPoint) -> Void)? = nil
    ) {
        self.initialAttributedText = initialAttributedText
        self.initialPlainText = initialPlainText
        self.preset = preset
        self.isEditable = isEditable
        self.controller = controller
        self.onTextChangeDebounced = onTextChangeDebounced
        self.onSlashTriggered = onSlashTriggered
    }

    public init(
        attributedText: Binding<NSAttributedString>,
        plainText: Binding<String>,
        preset: TypographyPreset = .standard,
        isEditable: Bool = true,
        controller: RichTextEditorController? = nil,
        onTextChange: ((NSAttributedString, String) -> Void)? = nil
    ) {
        self.initialAttributedText = attributedText.wrappedValue
        self.initialPlainText = plainText.wrappedValue
        self.preset = preset
        self.isEditable = isEditable
        self.controller = controller
        self.onTextChangeDebounced = { attr, plain in
            attributedText.wrappedValue = attr
            plainText.wrappedValue = plain
            onTextChange?(attr, plain)
        }
        self.onSlashTriggered = nil
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
        textContainer.lineFragmentPadding = 0
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
        
        // Drag & Drop
        textView.registerForDraggedTypes([.fileURL, .png, .tiff, .string])
        
        // Native Apple Notes Insets & Caret
        textView.textContainerInset = NSSize(width: 32, height: 20)
        textView.insertionPointColor = NSColor(red: 0.96, green: 0.65, blue: 0.18, alpha: 1.0)
        textView.currentPreset = preset
        
        // Default typing attributes
        textView.typingAttributes = RichTextTypography.defaultAttributes(for: .body, preset: preset)
        
        // Populate Initial Content
        if initialAttributedText.length > 0 {
            textStorage.setAttributedString(initialAttributedText)
        } else if !initialPlainText.isEmpty {
            let migrated = RichTextTypography.convertMarkdownToAttributedString(markdown: initialPlainText, preset: preset)
            textStorage.setAttributedString(migrated)
        }
        
        context.coordinator.textView = textView
        if let ctrl = controller {
            ctrl.textView = textView
            ctrl.onTextChange = onTextChangeDebounced
            ctrl.onSlashTriggered = onSlashTriggered
            ctrl.updateActiveStates(immediate: true)
        }
        
        scrollView.documentView = textView
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? LocaAppKitTextView else { return }
        
        context.coordinator.parent = self
        textView.currentPreset = preset
        if let ctrl = controller {
            ctrl.textView = textView
            ctrl.onTextChange = onTextChangeDebounced
            ctrl.onSlashTriggered = onSlashTriggered
        }
        
        textView.isEditable = isEditable
    }
    
    // MARK: - Coordinator (Decoupled Zero-Lag RunLoop Coordinator)
    
    public class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacRichTextEditor
        weak var textView: LocaAppKitTextView?
        private var debounceWorkItem: DispatchWorkItem?
        
        init(_ parent: MacRichTextEditor) {
            self.parent = parent
        }
        
        public func textDidChange(_ notification: Notification) {
            guard let textView = textView, let textStorage = textView.textStorage else { return }
            
            // 1. Throttled UI state update for formatting toolbar
            parent.controller?.updateActiveStates(immediate: false)
            
            // 2. Debounced save callback (Zero lag during continuous 120Hz keystrokes)
            debounceWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self, weak textStorage] in
                guard let self = self, let storage = textStorage else { return }
                let attrCopy = NSAttributedString(attributedString: storage)
                let plainCopy = storage.string
                self.parent.onTextChangeDebounced?(attrCopy, plainCopy)
            }
            debounceWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: work)
        }
        
        public func textViewDidChangeSelection(_ notification: Notification) {
            parent.controller?.updateActiveStates(immediate: false)
        }
    }
}

// MARK: - LocaAppKitTextView (Subclass for Apple Notes Smart Mechanics, Line Swapping & Drag-Drop)

public final class LocaAppKitTextView: NSTextView {
    
    public var currentPreset: TypographyPreset = .standard
    public var onSlashRequested: ((CGPoint) -> Void)?
    
    // MARK: - Drag & Drop Operations (Images & Files from Finder)
    
    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if sender.draggingPasteboard.canReadItem(withDataConformingToTypes: ["public.file-url", "public.image"]) {
            return .copy
        }
        return super.draggingEntered(sender)
    }
    
    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard
        
        // 1. Image Files
        if let urls = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], let firstURL = urls.first {
            if let image = NSImage(contentsOf: firstURL) {
                let point = convert(sender.draggingLocation, from: nil)
                if let layoutManager = self.layoutManager, let textContainer = self.textContainer, let textStorage = self.textStorage {
                    let glyph = layoutManager.glyphIndex(for: point, in: textContainer)
                    let charIndex = layoutManager.characterIndexForGlyph(at: glyph)
                    RichTextTypography.insertImageAttachment(image: image, in: textStorage, at: charIndex)
                    self.didChangeText()
                    Haptics.notify(.success)
                    return true
                }
            }
        }
        
        // 2. Direct Image Objects
        if let images = pboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], let firstImage = images.first {
            if let textStorage = self.textStorage {
                let location = self.selectedRange().location
                RichTextTypography.insertImageAttachment(image: firstImage, in: textStorage, at: location)
                self.didChangeText()
                Haptics.notify(.success)
                return true
            }
        }
        
        return super.performDragOperation(sender)
    }
    
    // MARK: - Line Reordering Handlers (⌥↑ / ⌥↓)
    
    public override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.option) {
            if event.keyCode == 126 { // Option + Up Arrow
                moveParagraphUp()
                return
            } else if event.keyCode == 125 { // Option + Down Arrow
                moveParagraphDown()
                return
            }
        }
        super.keyDown(with: event)
    }
    
    public func moveParagraphUp() {
        guard let textStorage = self.textStorage else { return }
        let string = textStorage.string as NSString
        let selectedRange = self.selectedRange()
        let currentParaRange = string.paragraphRange(for: selectedRange)
        
        guard currentParaRange.location > 0 else { return }
        
        let prevParaRange = string.paragraphRange(for: NSRange(location: currentParaRange.location - 1, length: 0))
        
        textStorage.beginEditing()
        let currentAttr = textStorage.attributedSubstring(from: currentParaRange)
        let prevAttr = textStorage.attributedSubstring(from: prevParaRange)
        
        let combinedRange = NSRange(location: prevParaRange.location, length: prevParaRange.length + currentParaRange.length)
        let swapped = NSMutableAttributedString(attributedString: currentAttr)
        swapped.append(prevAttr)
        
        textStorage.replaceCharacters(in: combinedRange, with: swapped)
        textStorage.endEditing()
        
        let relativeOffset = selectedRange.location - currentParaRange.location
        let newLocation = prevParaRange.location + relativeOffset
        self.setSelectedRange(NSRange(location: min(newLocation, textStorage.length), length: selectedRange.length))
        self.didChangeText()
        Haptics.impact(.light)
    }
    
    public func moveParagraphDown() {
        guard let textStorage = self.textStorage else { return }
        let string = textStorage.string as NSString
        let selectedRange = self.selectedRange()
        let currentParaRange = string.paragraphRange(for: selectedRange)
        let nextLocation = currentParaRange.location + currentParaRange.length
        
        guard nextLocation < string.length else { return }
        
        let nextParaRange = string.paragraphRange(for: NSRange(location: nextLocation, length: 0))
        
        textStorage.beginEditing()
        let currentAttr = textStorage.attributedSubstring(from: currentParaRange)
        let nextAttr = textStorage.attributedSubstring(from: nextParaRange)
        
        let combinedRange = NSRange(location: currentParaRange.location, length: currentParaRange.length + nextParaRange.length)
        let swapped = NSMutableAttributedString(attributedString: nextAttr)
        swapped.append(currentAttr)
        
        textStorage.replaceCharacters(in: combinedRange, with: swapped)
        textStorage.endEditing()
        
        let relativeOffset = selectedRange.location - currentParaRange.location
        let newLocation = currentParaRange.location + nextParaRange.length + relativeOffset
        self.setSelectedRange(NSRange(location: min(newLocation, textStorage.length), length: selectedRange.length))
        self.didChangeText()
        Haptics.impact(.light)
    }
    
    // MARK: - Smart Markdown Trigger on Type (e.g. '# ', '- ', '1. ', '[] ')
    
    public override func shouldChangeText(in affectedCharRange: NSRange, replacementString: String?) -> Bool {
        guard let rep = replacementString, let textStorage = self.textStorage else {
            return super.shouldChangeText(in: affectedCharRange, replacementString: replacementString)
        }
        
        let string = textStorage.string as NSString
        let paragraphRange = string.paragraphRange(for: affectedCharRange)
        let prefixLength = affectedCharRange.location - paragraphRange.location
        
        if rep == " " {
            if prefixLength > 0 && prefixLength <= 6 {
                let typedPrefix = string.substring(with: NSRange(location: paragraphRange.location, length: prefixLength))
                
                // 1. Title (# )
                if typedPrefix == "#" {
                    textStorage.beginEditing()
                    textStorage.replaceCharacters(in: NSRange(location: paragraphRange.location, length: prefixLength), with: "")
                    RichTextTypography.applyParagraphStyle(.title, to: textStorage, range: NSRange(location: paragraphRange.location, length: 0), preset: currentPreset)
                    self.typingAttributes = RichTextTypography.defaultAttributes(for: .title, preset: currentPreset)
                    textStorage.endEditing()
                    self.setSelectedRange(NSRange(location: paragraphRange.location, length: 0))
                    self.didChangeText()
                    return false
                }
                
                // 2. Heading (## )
                if typedPrefix == "##" {
                    textStorage.beginEditing()
                    textStorage.replaceCharacters(in: NSRange(location: paragraphRange.location, length: prefixLength), with: "")
                    RichTextTypography.applyParagraphStyle(.heading, to: textStorage, range: NSRange(location: paragraphRange.location, length: 0), preset: currentPreset)
                    self.typingAttributes = RichTextTypography.defaultAttributes(for: .heading, preset: currentPreset)
                    textStorage.endEditing()
                    self.setSelectedRange(NSRange(location: paragraphRange.location, length: 0))
                    self.didChangeText()
                    return false
                }
                
                // 3. Subheading (### )
                if typedPrefix == "###" {
                    textStorage.beginEditing()
                    textStorage.replaceCharacters(in: NSRange(location: paragraphRange.location, length: prefixLength), with: "")
                    RichTextTypography.applyParagraphStyle(.subheading, to: textStorage, range: NSRange(location: paragraphRange.location, length: 0), preset: currentPreset)
                    self.typingAttributes = RichTextTypography.defaultAttributes(for: .subheading, preset: currentPreset)
                    textStorage.endEditing()
                    self.setSelectedRange(NSRange(location: paragraphRange.location, length: 0))
                    self.didChangeText()
                    return false
                }
                
                // 4. Bullet List (- or *)
                if typedPrefix == "-" || typedPrefix == "*" {
                    textStorage.beginEditing()
                    textStorage.replaceCharacters(in: NSRange(location: paragraphRange.location, length: prefixLength), with: "• ")
                    RichTextTypography.applyParagraphStyle(.bulletedList, to: textStorage, range: NSRange(location: paragraphRange.location, length: 2), preset: currentPreset)
                    self.typingAttributes = RichTextTypography.defaultAttributes(for: .bulletedList, preset: currentPreset)
                    textStorage.endEditing()
                    self.setSelectedRange(NSRange(location: paragraphRange.location + 2, length: 0))
                    self.didChangeText()
                    return false
                }
                
                // 5. Checklist ([] or [ ])
                if typedPrefix == "[]" || typedPrefix == "[ ]" {
                    let glyph = RichTextTypography.checklistUncheckedGlyph
                    textStorage.beginEditing()
                    textStorage.replaceCharacters(in: NSRange(location: paragraphRange.location, length: prefixLength), with: glyph)
                    let pStyle = RichTextTypography.makeParagraphStyle(for: .checklist, preset: currentPreset)
                    let updatedRange = (textStorage.string as NSString).paragraphRange(for: NSRange(location: paragraphRange.location, length: 0))
                    textStorage.addAttribute(.paragraphStyle, value: pStyle, range: updatedRange)
                    textStorage.addAttribute(.noteChecklistState, value: ChecklistState.unchecked.rawValue, range: updatedRange)
                    textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: NSRange(location: paragraphRange.location, length: (glyph as NSString).length))
                    self.typingAttributes = RichTextTypography.defaultAttributes(for: .checklist, preset: currentPreset)
                    textStorage.endEditing()
                    self.setSelectedRange(NSRange(location: paragraphRange.location + glyph.count, length: 0))
                    self.didChangeText()
                    return false
                }
                
                // 6. Blockquote (> )
                if typedPrefix == ">" {
                    textStorage.beginEditing()
                    textStorage.replaceCharacters(in: NSRange(location: paragraphRange.location, length: prefixLength), with: "")
                    RichTextTypography.applyParagraphStyle(.quote, to: textStorage, range: NSRange(location: paragraphRange.location, length: 0), preset: currentPreset)
                    self.typingAttributes = RichTextTypography.defaultAttributes(for: .quote, preset: currentPreset)
                    textStorage.endEditing()
                    self.setSelectedRange(NSRange(location: paragraphRange.location, length: 0))
                    self.didChangeText()
                    return false
                }
            }
        }
        
        return super.shouldChangeText(in: affectedCharRange, replacementString: replacementString)
    }
    
    // MARK: - Smart Return & Continuations
    
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
        if paragraphText.hasPrefix(RichTextTypography.checklistUncheckedGlyph) || paragraphText.hasPrefix(RichTextTypography.checklistCheckedGlyph) || paragraphText.hasPrefix("○ ") || paragraphText.hasPrefix("● ") {
            let prefix = RichTextTypography.checklistUncheckedGlyph
            let contentInLine = paragraphText
                .replacingOccurrences(of: RichTextTypography.checklistUncheckedGlyph, with: "")
                .replacingOccurrences(of: RichTextTypography.checklistCheckedGlyph, with: "")
                .replacingOccurrences(of: "○ ", with: "")
                .replacingOccurrences(of: "● ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if contentInLine.isEmpty {
                textStorage.replaceCharacters(in: paragraphRange, with: "\n")
                self.setSelectedRange(NSRange(location: paragraphRange.location, length: 0))
                self.didChangeText()
                return
            } else {
                super.insertNewline(sender)
                let font = (self.typingAttributes[.font] as? NSFont) ?? currentPreset.font(for: .checklist)
                let pStyle = RichTextTypography.makeParagraphStyle(for: .checklist, preset: currentPreset)
                let checklistAttr = NSAttributedString(string: prefix, attributes: [
                    .font: font,
                    .paragraphStyle: pStyle,
                    .noteChecklistState: ChecklistState.unchecked.rawValue,
                    .foregroundColor: NSColor.clear
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
                let font = (self.typingAttributes[.font] as? NSFont) ?? currentPreset.font(for: .bulletedList)
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
                let font = (self.typingAttributes[.font] as? NSFont) ?? currentPreset.font(for: .dashedList)
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
                    let font = (self.typingAttributes[.font] as? NSFont) ?? currentPreset.font(for: .numberedList)
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
        
        // 5. Title / Heading -> Transition down to Body on Enter
        if let currentFont = self.typingAttributes[.font] as? NSFont, currentFont.pointSize >= 18 {
            super.insertNewline(sender)
            self.typingAttributes = RichTextTypography.defaultAttributes(for: .body, preset: currentPreset)
            return
        }
        
        super.insertNewline(sender)
    }
    
    // MARK: - Smart Tab & Shift-Tab Indentation
    
    public override func insertTab(_ sender: Any?) {
        guard let textStorage = self.textStorage else {
            super.insertTab(sender)
            return
        }
        
        let selectedRange = self.selectedRange()
        let string = textStorage.string as NSString
        let paragraphRange = string.paragraphRange(for: selectedRange)
        
        if let existingStyle = textStorage.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSParagraphStyle {
            let mutableStyle = existingStyle.mutableCopy() as! NSMutableParagraphStyle
            mutableStyle.headIndent += 20
            mutableStyle.firstLineHeadIndent += 20
            textStorage.addAttribute(.paragraphStyle, value: mutableStyle, range: paragraphRange)
            self.didChangeText()
            return
        }
        
        super.insertTab(sender)
    }
    
    public override func insertBacktab(_ sender: Any?) {
        guard let textStorage = self.textStorage else {
            super.insertBacktab(sender)
            return
        }
        
        let selectedRange = self.selectedRange()
        let string = textStorage.string as NSString
        let paragraphRange = string.paragraphRange(for: selectedRange)
        
        if let existingStyle = textStorage.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSParagraphStyle {
            let mutableStyle = existingStyle.mutableCopy() as! NSMutableParagraphStyle
            if mutableStyle.headIndent >= 20 {
                mutableStyle.headIndent -= 20
                mutableStyle.firstLineHeadIndent = max(0, mutableStyle.firstLineHeadIndent - 20)
                textStorage.addAttribute(.paragraphStyle, value: mutableStyle, range: paragraphRange)
                self.didChangeText()
                return
            }
        }
        
        super.insertBacktab(sender)
    }
    
    // MARK: - Smart Delete Backward (Backspace deletes list/checklist prefix in 1 hit)
    
    public override func deleteBackward(_ sender: Any?) {
        guard let textStorage = self.textStorage else {
            super.deleteBackward(sender)
            return
        }
        
        let selectedRange = self.selectedRange()
        if selectedRange.length > 0 {
            super.deleteBackward(sender)
            return
        }
        
        let string = textStorage.string as NSString
        let paragraphRange = string.paragraphRange(for: selectedRange)
        let paragraphText = string.substring(with: paragraphRange)
        
        let prefixes = [
            RichTextTypography.checklistUncheckedGlyph,
            RichTextTypography.checklistCheckedGlyph,
            "○ ", "● ", "☐ ", "☑︎ ", "• ", "– "
        ]
        
        for prefix in prefixes {
            if paragraphText.hasPrefix(prefix) {
                let prefixLen = (prefix as NSString).length
                if selectedRange.location == paragraphRange.location + prefixLen || paragraphText.trimmingCharacters(in: .whitespacesAndNewlines) == prefix.trimmingCharacters(in: .whitespacesAndNewlines) {
                    textStorage.beginEditing()
                    let replaceRange = NSRange(location: paragraphRange.location, length: prefixLen)
                    textStorage.replaceCharacters(in: replaceRange, with: "")
                    let remainingLen = max(0, paragraphRange.length - prefixLen)
                    textStorage.removeAttribute(.strikethroughStyle, range: NSRange(location: paragraphRange.location, length: remainingLen))
                    textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: NSRange(location: paragraphRange.location, length: remainingLen))
                    textStorage.endEditing()
                    self.setSelectedRange(NSRange(location: paragraphRange.location, length: 0))
                    self.didChangeText()
                    return
                }
            }
        }
        
        super.deleteBackward(sender)
    }
    
    private var hoveredCheckboxParaRange: NSRange? = nil
    private var checklistTrackingArea: NSTrackingArea? = nil
    
    public override func updateTrackingAreas() {
        if let existing = checklistTrackingArea {
            removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect]
        checklistTrackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        if let trackingArea = checklistTrackingArea {
            addTrackingArea(trackingArea)
        }
        super.updateTrackingAreas()
    }
    
    public override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let layoutManager = self.layoutManager, let textContainer = self.textContainer, let textStorage = self.textStorage else {
            super.mouseMoved(with: event)
            return
        }
        
        let string = textStorage.string as NSString
        var foundCheckbox = false
        
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        var paraLoc = charRange.location
        
        while paraLoc < charRange.location + charRange.length && paraLoc < string.length {
            let paraRange = string.paragraphRange(for: NSRange(location: paraLoc, length: 0))
            let paraText = string.substring(with: paraRange)
            
            let isUnchecked = paraText.hasPrefix("○  ") || paraText.hasPrefix("○ ") || paraText.hasPrefix("☐ ") || (textStorage.attribute(.noteChecklistState, at: paraRange.location, effectiveRange: nil) as? String == ChecklistState.unchecked.rawValue)
            let isChecked = paraText.hasPrefix("●  ") || paraText.hasPrefix("● ") || paraText.hasPrefix("☑︎ ") || (textStorage.attribute(.noteChecklistState, at: paraRange.location, effectiveRange: nil) as? String == ChecklistState.checked.rawValue)
            
            if isUnchecked || isChecked {
                let firstGlyph = layoutManager.glyphIndexForCharacter(at: paraRange.location)
                if firstGlyph < layoutManager.numberOfGlyphs {
                    let lineRect = layoutManager.lineFragmentRect(forGlyphAt: firstGlyph, effectiveRange: nil)
                    let hitRect = NSRect(x: 0, y: lineRect.origin.y, width: 38, height: lineRect.height)
                    if hitRect.contains(point) {
                        foundCheckbox = true
                        if hoveredCheckboxParaRange != paraRange {
                            hoveredCheckboxParaRange = paraRange
                            self.setNeedsDisplay(hitRect)
                        }
                        NSCursor.pointingHand.set()
                        return
                    }
                }
            }
            paraLoc = paraRange.location + paraRange.length
        }
        
        if !foundCheckbox && hoveredCheckboxParaRange != nil {
            hoveredCheckboxParaRange = nil
            self.setNeedsDisplay(self.bounds)
            NSCursor.iBeam.set()
        }
        
        super.mouseMoved(with: event)
    }
    
    // MARK: - Native Vector Checklist Drawing (Apple Notes Retina Standard)
    
    public override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)
        
        guard let layoutManager = self.layoutManager, let textContainer = self.textContainer, let textStorage = self.textStorage else { return }
        let string = textStorage.string as NSString
        let origin = self.textContainerOrigin
        
        let glyphRange = layoutManager.glyphRange(forBoundingRect: rect, in: textContainer)
        var charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        charRange = string.paragraphRange(for: charRange)
        
        var paraLoc = charRange.location
        while paraLoc < charRange.location + charRange.length && paraLoc < string.length {
            let paraRange = string.paragraphRange(for: NSRange(location: paraLoc, length: 0))
            let paraText = string.substring(with: paraRange)
            
            let isUnchecked = paraText.hasPrefix("○  ") || paraText.hasPrefix("○ ") || paraText.hasPrefix("☐ ") || (textStorage.attribute(.noteChecklistState, at: paraRange.location, effectiveRange: nil) as? String == ChecklistState.unchecked.rawValue)
            let isChecked = paraText.hasPrefix("●  ") || paraText.hasPrefix("● ") || paraText.hasPrefix("☑︎ ") || (textStorage.attribute(.noteChecklistState, at: paraRange.location, effectiveRange: nil) as? String == ChecklistState.checked.rawValue)
            
            if isUnchecked || isChecked {
                let firstGlyph = layoutManager.glyphIndexForCharacter(at: paraRange.location)
                if firstGlyph < layoutManager.numberOfGlyphs {
                    let lineRect = layoutManager.lineFragmentRect(forGlyphAt: firstGlyph, effectiveRange: nil)
                    
                    let circleSize: CGFloat = 18.5
                    let circleX: CGFloat = origin.x + 6.5
                    let circleY: CGFloat = origin.y + lineRect.origin.y + (lineRect.height - circleSize) / 2
                    let circleRect = NSRect(x: circleX, y: circleY, width: circleSize, height: circleSize)
                    
                    NSGraphicsContext.saveGraphicsState()
                    let circlePath = NSBezierPath(ovalIn: circleRect)
                    
                    if isChecked {
                        // Amber Gold Checkbox Badge
                        let amberGold = NSColor(red: 0.96, green: 0.76, blue: 0.28, alpha: 1.0)
                        amberGold.setFill()
                        circlePath.fill()
                        
                        // Crisp Checkmark ✓ Path inside circle
                        let checkmark = NSBezierPath()
                        checkmark.lineWidth = 2.0
                        checkmark.lineCapStyle = .round
                        checkmark.lineJoinStyle = .round
                        NSColor.black.withAlphaComponent(0.85).setStroke()
                        
                        let cx = circleRect.origin.x
                        let cy = circleRect.origin.y
                        checkmark.move(to: NSPoint(x: cx + 4.5, y: cy + 9.0))
                        checkmark.line(to: NSPoint(x: cx + 7.5, y: cy + 5.2))
                        checkmark.line(to: NSPoint(x: cx + 13.6, y: cy + 13.0))
                        checkmark.stroke()
                    } else {
                        let isHovered = hoveredCheckboxParaRange?.location == paraRange.location
                        let strokeColor = isHovered
                            ? NSColor(red: 0.96, green: 0.76, blue: 0.28, alpha: 0.95)
                            : NSColor.white.withAlphaComponent(0.38)
                        strokeColor.setStroke()
                        circlePath.lineWidth = isHovered ? 1.9 : 1.5
                        circlePath.stroke()
                        
                        if isHovered {
                            NSColor(red: 0.96, green: 0.76, blue: 0.28, alpha: 0.14).setFill()
                            circlePath.fill()
                        }
                    }
                    NSGraphicsContext.restoreGraphicsState()
                }
            }
            paraLoc = paraRange.location + paraRange.length
        }
    }
    
    // MARK: - Interactive Checkbox Click Detection (Pixel-Perfect Gutter Hit Testing)
    
    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let layoutManager = self.layoutManager, let textContainer = self.textContainer, let textStorage = self.textStorage else {
            super.mouseDown(with: event)
            return
        }
        
        let string = textStorage.string as NSString
        let glyphRange = layoutManager.glyphRange(for: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        var paraLoc = charRange.location
        
        while paraLoc < charRange.location + charRange.length && paraLoc < string.length {
            let paragraphRange = string.paragraphRange(for: NSRange(location: paraLoc, length: 0))
            let paragraphText = string.substring(with: paragraphRange)
            
            let isUnchecked = paragraphText.hasPrefix("○  ") || paragraphText.hasPrefix("○ ") || paragraphText.hasPrefix("☐ ") || (textStorage.attribute(.noteChecklistState, at: paragraphRange.location, effectiveRange: nil) as? String == ChecklistState.unchecked.rawValue)
            let isChecked = paragraphText.hasPrefix("●  ") || paragraphText.hasPrefix("● ") || paragraphText.hasPrefix("☑︎ ") || (textStorage.attribute(.noteChecklistState, at: paragraphRange.location, effectiveRange: nil) as? String == ChecklistState.checked.rawValue)
            
            if isUnchecked || isChecked {
                let firstGlyph = layoutManager.glyphIndexForCharacter(at: paragraphRange.location)
                if firstGlyph < layoutManager.numberOfGlyphs {
                    let lineRect = layoutManager.lineFragmentRect(forGlyphAt: firstGlyph, effectiveRange: nil)
                    let hitRect = NSRect(x: 0, y: lineRect.origin.y, width: 38, height: lineRect.height)
                    
                    if hitRect.contains(point) {
                        // Clicked exactly on the checklist gutter widget!
                        if isUnchecked {
                            // Toggle Unchecked -> Checked
                            textStorage.beginEditing()
                            let oldPrefix = paragraphText.hasPrefix("○  ") ? "○  " : (paragraphText.hasPrefix("○ ") ? "○ " : "☐ ")
                            let glyphRange = NSRange(location: paragraphRange.location, length: (oldPrefix as NSString).length)
                            textStorage.replaceCharacters(in: glyphRange, with: RichTextTypography.checklistCheckedGlyph)
                            
                            let updatedParaRange = (textStorage.string as NSString).paragraphRange(for: NSRange(location: paragraphRange.location, length: 0))
                            let prefixLen = (RichTextTypography.checklistCheckedGlyph as NSString).length
                            let textLen = updatedParaRange.length - prefixLen
                            
                            textStorage.addAttribute(.noteChecklistState, value: ChecklistState.checked.rawValue, range: updatedParaRange)
                            textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: NSRange(location: updatedParaRange.location, length: prefixLen))
                            textStorage.removeAttribute(.strikethroughStyle, range: updatedParaRange)
                            
                            let textSnippet = (textStorage.string as NSString).substring(with: NSRange(location: updatedParaRange.location + prefixLen, length: max(0, textLen))).trimmingCharacters(in: .whitespacesAndNewlines)
                            if !textSnippet.isEmpty && textLen > 0 {
                                let strikeRange = NSRange(location: updatedParaRange.location + prefixLen, length: textLen)
                                textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: strikeRange)
                                textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: strikeRange)
                            }
                            textStorage.endEditing()
                            self.setNeedsDisplay(self.bounds)
                            self.didChangeText()
                            Haptics.impact(.light)
                            return
                        } else if isChecked {
                            // Toggle Checked -> Unchecked
                            textStorage.beginEditing()
                            let oldPrefix = paragraphText.hasPrefix("●  ") ? "●  " : (paragraphText.hasPrefix("● ") ? "● " : "☑︎ ")
                            let glyphRange = NSRange(location: paragraphRange.location, length: (oldPrefix as NSString).length)
                            textStorage.replaceCharacters(in: glyphRange, with: RichTextTypography.checklistUncheckedGlyph)
                            
                            let updatedParaRange = (textStorage.string as NSString).paragraphRange(for: NSRange(location: paragraphRange.location, length: 0))
                            let prefixLen = (RichTextTypography.checklistUncheckedGlyph as NSString).length
                            let textLen = updatedParaRange.length - prefixLen
                            
                            textStorage.addAttribute(.noteChecklistState, value: ChecklistState.unchecked.rawValue, range: updatedParaRange)
                            textStorage.removeAttribute(.strikethroughStyle, range: updatedParaRange)
                            textStorage.addAttribute(.foregroundColor, value: NSColor.textColor, range: NSRange(location: updatedParaRange.location + prefixLen, length: max(0, textLen)))
                            textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: NSRange(location: updatedParaRange.location, length: prefixLen))
                            textStorage.endEditing()
                            self.setNeedsDisplay(self.bounds)
                            self.didChangeText()
                            Haptics.impact(.light)
                            return
                        }
                    }
                }
            }
            paraLoc = paragraphRange.location + paragraphRange.length
        }
        
        super.mouseDown(with: event)
    }
}
