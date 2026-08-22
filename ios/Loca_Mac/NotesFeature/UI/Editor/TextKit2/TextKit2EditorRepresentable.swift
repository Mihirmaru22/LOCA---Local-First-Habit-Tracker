// MARK: - Architecture Decision Record (ADR)
// - SHIPPING TEXT SYSTEM: AppKit NSTextStorage (TextKit 1 compatible pipeline).
// - REASON: Hand-wired pure TextKit 2 stack produced a detached textStorage accessor, silently aborting insertText.
//   The AppKit NSTextStorage pipeline is proven, rock-solid, and zero-latency across all macOS versions.
// - The CRDT document model, block-attribute typography, and CRDT bridge are completely storage-agnostic.
// - TextKit 2 migration is deferred to Phase 5 (Polish) as a non-breaking optimization, not a correctness requirement.
//
// MARK: - Editing Contract: Option A (Native Apply + Observe)
// 1. textView(_:shouldChangeTextIn:replacementString:) updates the CRDT model and returns true for standard typing.
// 2. AppKit text engine natively commits glyphs to the backing store at 120fps with zero latency.
// 3. Return key triggers a custom block split and synchronous re-render with cursor placement.
// 4. Remote CRDT merges update textStorage only on remote deltas, preventing local render loops.
// 5. Checklist and bullet glyphs are drawn exclusively in the margin via custom draw(_:); storage string is untouched.

import Foundation
import Combine
import SwiftUI
import AppKit

/// Subclassed NSTextView supporting interactive margin-drawn glyphs, gutter clicks, and text engine integration.
public final class NoteCanvasTextView: NSTextView {
    
    public weak var bridge: TextKitCRDTBridge?
    public var onGutterClicked: ((NSPoint) -> Bool)?
    public var onToggleBold: (() -> Void)?
    public var onToggleItalic: (() -> Void)?
    
    public override var acceptsFirstResponder: Bool { true }
    public override var canBecomeKeyView: Bool { true }
    public override var needsPanelToBecomeKey: Bool { true }
    
    public override func becomeFirstResponder() -> Bool {
        return super.becomeFirstResponder()
    }
    
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == .command {
            if let chars = event.charactersIgnoringModifiers?.lowercased() {
                if chars == "b" {
                    if let toggleBold = onToggleBold {
                        toggleBold()
                        return true
                    }
                } else if chars == "i" {
                    if let toggleItalic = onToggleItalic {
                        toggleItalic()
                        return true
                    }
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
    
    public override func mouseDown(with event: NSEvent) {
        if window?.firstResponder != self {
            window?.makeFirstResponder(self)
        }
        
        let point = convert(event.locationInWindow, from: nil)
        if let handler = onGutterClicked, handler(point) {
            return
        }
        super.mouseDown(with: event)
    }
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let bridge = bridge,
              let layoutManager = self.layoutManager,
              let textContainer = self.textContainer,
              let storage = self.textStorage else { return }
        
        let activeBlocks = bridge.doc.blocks.filter { !$0.isDeleted }
        let origin = self.textContainerOrigin
        
        for block in activeBlocks {
            guard block.type == "checklistItem" || block.type == "bullet" else { continue }
            guard let range = bridge.blockRanges[block.id] else { continue }
            guard range.location <= storage.length else { continue }
            
            let charIndex = min(range.location, max(0, storage.length - 1))
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: charIndex)
            guard glyphIndex < layoutManager.numberOfGlyphs || storage.length == 0 else { continue }
            
            var lineRange = NSRange(location: 0, length: 0)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineRange)
            
            let viewLineRect = NSRect(
                x: origin.x + lineRect.origin.x,
                y: origin.y + lineRect.origin.y,
                width: lineRect.width,
                height: lineRect.height
            )
            
            if block.type == "checklistItem" {
                let isChecked = block.attributes["isChecked"] == "true"
                let symbolName = isChecked ? "checkmark.square.fill" : "square"
                let tintColor = isChecked ? NSColor.controlAccentColor : NSColor.secondaryLabelColor
                
                let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
                if let symbolImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Checkbox")?.withSymbolConfiguration(config) {
                    let tinted = symbolImage.copy() as! NSImage
                    tinted.lockFocus()
                    tintColor.set()
                    let imageRect = NSRect(origin: .zero, size: tinted.size)
                    imageRect.fill(using: .sourceAtop)
                    tinted.unlockFocus()
                    
                    let boxSize: CGFloat = 14
                    let boxX: CGFloat = origin.x + 4
                    let boxY: CGFloat = viewLineRect.origin.y + max(0, (viewLineRect.height - boxSize) / 2)
                    let targetRect = NSRect(x: boxX, y: boxY, width: boxSize, height: boxSize)
                    
                    tinted.draw(in: targetRect, from: .zero, operation: .sourceOver, fraction: 1.0)
                }
            } else if block.type == "bullet" {
                let bulletStr = "•" as NSString
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 14, weight: .bold),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
                let bulletSize = bulletStr.size(withAttributes: attrs)
                let bulletX: CGFloat = origin.x + 6
                let bulletY: CGFloat = viewLineRect.origin.y + max(0, (viewLineRect.height - bulletSize.height) / 2)
                bulletStr.draw(at: NSPoint(x: bulletX, y: bulletY), withAttributes: attrs)
            }
        }
    }
}

/// SwiftUI Representable wrapping AppKit NoteCanvasTextView wired to TextKitCRDTBridge.
public struct TextKit2EditorRepresentable: NSViewRepresentable {
    
    @ObservedObject public var state: EditorBridgeState
    public let onKeystroke: (CRDTDoc) -> Void
    public let onSelectionChanged: (NSRange) -> Void
    
    public init(
        state: EditorBridgeState,
        onKeystroke: @escaping (CRDTDoc) -> Void,
        onSelectionChanged: @escaping (NSRange) -> Void = { _ in }
    ) {
        self.state = state
        self.onKeystroke = onKeystroke
        self.onSelectionChanged = onSelectionChanged
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NoteCanvasTextView(frame: .zero)
        
        textView.bridge = state.bridge
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.drawsBackground = false
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textColor = NSColor.labelColor
        textView.insertionPointColor = NSColor.controlAccentColor
        textView.textContainerInset = NSSize(width: 24, height: 16)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 676, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.lineFragmentPadding = 0
        
        textView.typingAttributes = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: NSParagraphStyle.default
        ]
        
        // Wire in-place format updates directly to textStorage with Programmatic-Edit Guard
        state.onInPlaceFormatUpdate = { [weak textView, weak state, weak coordinator = context.coordinator] in
            guard let tv = textView, let storage = tv.textStorage, let state = state else { return }
            let intendedCursor = state.bridge.lastKnownSelection
            coordinator?.isProgrammaticEdit = true
            let rendered = state.bridge.renderAttributedString()
            storage.setAttributedString(rendered)
            tv.setSelectedRange(intendedCursor)
            state.bridge.updateLastKnownSelection(intendedCursor)
            coordinator?.isProgrammaticEdit = false
            tv.setNeedsDisplay(tv.bounds)
            self.onKeystroke(state.bridge.doc)
        }
        
        // Wire Keyboard Shortcuts (⌘B / ⌘I)
        textView.onToggleBold = { [weak state] in
            guard let state = state else { return }
            DispatchQueue.main.async {
                state.toggleBold()
            }
        }
        
        textView.onToggleItalic = { [weak state] in
            guard let state = state else { return }
            DispatchQueue.main.async {
                state.toggleItalic()
            }
        }
        
        // Gutter Click Handler (x < 24 over checklist margin)
        textView.onGutterClicked = { [weak textView, weak coordinator = context.coordinator] clickPoint in
            guard let tv = textView, let storage = tv.textStorage else { return false }
            
            let relativeX = clickPoint.x - tv.textContainerOrigin.x
            guard relativeX >= 0 && relativeX < 24 else { return false }
            
            let charIndex = tv.characterIndexForInsertion(at: clickPoint)
            guard let target = self.state.bridge.resolveLocation(charIndex),
                  target.block.type == "checklistItem" else {
                return false
            }
            
            // Toggle checklist state
            self.state.bridge.toggleChecklist(blockID: target.block.id)
            let intendedCursor = self.state.bridge.lastKnownSelection
            coordinator?.isProgrammaticEdit = true
            let updatedAttributed = self.state.bridge.renderAttributedString()
            storage.setAttributedString(updatedAttributed)
            tv.setSelectedRange(intendedCursor)
            self.state.bridge.updateLastKnownSelection(intendedCursor)
            coordinator?.isProgrammaticEdit = false
            
            tv.setNeedsDisplay(tv.bounds)
            
            DispatchQueue.main.async {
                self.state.refreshFormattingState()
                self.onKeystroke(self.state.bridge.doc)
            }
            return true
        }
        
        // Initial render directly into textStorage
        let initialAttributed = state.bridge.renderAttributedString()
        textView.textStorage?.setAttributedString(initialAttributed)
        
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        
        context.coordinator.textView = textView
        
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        textView.bridge = state.bridge
        
        // Strictly guard against touching textStorage for local edits
        guard state.needsRemoteRefresh else {
            return
        }
        
        state.needsRemoteRefresh = false
        
        guard let storage = textView.textStorage else { return }
        let oldLength = storage.length
        let currentSelection = textView.selectedRange()
        
        context.coordinator.isProgrammaticEdit = true
        let newAttributed = state.bridge.renderAttributedString()
        storage.setAttributedString(newAttributed)
        
        // Hard Snap Cursor position based on length delta
        let delta = newAttributed.length - oldLength
        let newSelection = CursorSnapper.snapCursor(
            currentRange: currentSelection,
            remoteChangeLocation: currentSelection.location,
            deltaLength: delta,
            totalNewLength: newAttributed.length
        )
        textView.setSelectedRange(newSelection)
        state.bridge.updateLastKnownSelection(newSelection)
        textView.scrollRangeToVisible(newSelection)
        context.coordinator.isProgrammaticEdit = false
        textView.setNeedsDisplay(textView.bounds)
    }
    
    public final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextKit2EditorRepresentable
        weak var textView: NoteCanvasTextView?
        public var isProgrammaticEdit = false
        
        init(_ parent: TextKit2EditorRepresentable) {
            self.parent = parent
        }
        
        public func textViewDidChangeSelection(_ notification: Notification) {
            guard !isProgrammaticEdit else { return }
            guard let tv = notification.object as? NSTextView else { return }
            let sel = tv.selectedRange()
            parent.state.bridge.updateLastKnownSelection(sel)
            parent.state.bridge.selectionDidChange(to: sel)
            DispatchQueue.main.async {
                self.parent.state.refreshFormattingState()
                self.parent.onSelectionChanged(sel)
            }
        }
        
        public func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            let replacement = replacementString ?? ""
            parent.state.bridge.updateLastKnownSelection(affectedCharRange)
            
            if replacement == "\n" {
                // Return key: Split block in-place with Apple Notes semantics & Programmatic Guard
                if let split = parent.state.bridge.splitBlock(at: affectedCharRange.location) {
                    if let storage = textView.textStorage {
                        isProgrammaticEdit = true
                        let updatedAttributed = parent.state.bridge.renderAttributedString()
                        storage.setAttributedString(updatedAttributed)
                        let newCursorPos = min(split.newCursor, updatedAttributed.length)
                        let intendedCursor = NSRange(location: newCursorPos, length: 0)
                        textView.setSelectedRange(intendedCursor)
                        parent.state.bridge.updateLastKnownSelection(intendedCursor)
                        textView.scrollRangeToVisible(intendedCursor)
                        isProgrammaticEdit = false
                        textView.setNeedsDisplay(textView.bounds)
                    }
                    parent.onKeystroke(parent.state.bridge.doc)
                    DispatchQueue.main.async {
                        self.parent.state.refreshFormattingState()
                    }
                    return false
                }
            }
            
            // Standard Typing / Deletion / Replacement:
            if replacement.isEmpty && affectedCharRange.length > 0 {
                parent.state.bridge.deleteText(at: affectedCharRange.location, length: affectedCharRange.length)
            } else if !replacement.isEmpty {
                parent.state.bridge.insertText(replacement, at: affectedCharRange.location)
            }
            
            textView.setNeedsDisplay(textView.bounds)
            parent.onKeystroke(parent.state.bridge.doc)
            DispatchQueue.main.async {
                self.parent.state.refreshFormattingState()
            }
            return true
        }
        
        public func textDidChange(_ notification: Notification) {
            guard let tv = textView else { return }
            tv.typingAttributes = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: NSParagraphStyle.default
            ]
        }
    }
}

/// Observable state container synchronizing the SwiftUI shell with the active TextKitCRDTBridge.
@MainActor
public final class EditorBridgeState: ObservableObject {
    public var bridge: TextKitCRDTBridge
    @Published public var formattingState: FormattingState = FormattingState()
    public var needsRemoteRefresh: Bool = false
    public var currentSelection: NSRange = NSRange(location: 0, length: 0)
    
    // Callback to apply in-place text storage changes without triggering updateNSView
    public var onInPlaceFormatUpdate: (() -> Void)?
    
    public init(bridge: TextKitCRDTBridge) {
        self.bridge = bridge
        self.formattingState = bridge.currentFormattingState(at: bridge.lastKnownSelection)
    }
    
    public func updateSelection(_ newRange: NSRange) {
        self.currentSelection = newRange
        bridge.updateLastKnownSelection(newRange)
        bridge.selectionDidChange(to: newRange)
        refreshFormattingState()
    }
    
    public func refreshFormattingState() {
        let sel = bridge.lastKnownSelection
        let newState = bridge.currentFormattingState(at: sel)
        if formattingState != newState {
            formattingState = newState
        }
    }
    
    public func toggleBold() {
        let sel = bridge.lastKnownSelection
        bridge.toggleInlineMark(type: "bold", in: sel)
        if sel.length > 0 {
            onInPlaceFormatUpdate?()
        }
        refreshFormattingState()
    }
    
    public func toggleItalic() {
        let sel = bridge.lastKnownSelection
        bridge.toggleInlineMark(type: "italic", in: sel)
        if sel.length > 0 {
            onInPlaceFormatUpdate?()
        }
        refreshFormattingState()
    }
    
    public func toggleBlockType(_ type: EditorBlockType) {
        let sel = bridge.lastKnownSelection
        bridge.toggleBlockType(type, at: sel.location)
        onInPlaceFormatUpdate?()
        refreshFormattingState()
    }
    
    public func updateDocFromRemote(_ newDoc: CRDTDoc) {
        bridge.doc = newDoc
        needsRemoteRefresh = true
        refreshFormattingState()
    }
    
    public func requestFormatRefresh() {
        onInPlaceFormatUpdate?()
        refreshFormattingState()
    }
}
