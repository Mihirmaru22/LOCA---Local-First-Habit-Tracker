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

import Foundation
import Combine
import SwiftUI
import AppKit

/// Subclassed NSTextView supporting interactive checkbox gutter clicks, keyboard shortcuts, and text engine integration.
public final class NoteCanvasTextView: NSTextView {
    
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
        // Ensure text view claims first responder status on click
        if window?.firstResponder != self {
            window?.makeFirstResponder(self)
        }
        
        let point = convert(event.locationInWindow, from: nil)
        if let handler = onGutterClicked, handler(point) {
            // Handled by gutter click (e.g. checkbox toggled)
            return
        }
        super.mouseDown(with: event)
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
        
        // Wire in-place format updates directly to textStorage
        state.onInPlaceFormatUpdate = { [weak textView, weak state] in
            guard let tv = textView, let storage = tv.textStorage, let state = state else { return }
            let currentSel = tv.selectedRange()
            let rendered = state.bridge.renderAttributedString()
            storage.setAttributedString(rendered)
            tv.setSelectedRange(currentSel)
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
        
        // Gutter Click Handler
        textView.onGutterClicked = { [weak textView] clickPoint in
            guard let tv = textView, let storage = tv.textStorage else { return false }
            
            // Check if click X is in left gutter margin (< 30pt)
            let relativeX = clickPoint.x - tv.textContainerOrigin.x
            guard relativeX >= 0 && relativeX < 30 else { return false }
            
            // Find character index at this Y coordinate
            let charIndex = tv.characterIndexForInsertion(at: clickPoint)
            guard let target = self.state.bridge.resolveLocation(charIndex),
                  target.block.type == "checklistItem" else {
                return false
            }
            
            // Toggle checklist state
            self.state.bridge.toggleChecklist(blockID: target.block.id)
            let updatedAttributed = self.state.bridge.renderAttributedString()
            storage.setAttributedString(updatedAttributed)
            
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
        print("🟡 updateNSView CALLED: needsRemoteRefresh=\(state.needsRemoteRefresh)")
        guard let textView = context.coordinator.textView else { return }
        
        // Strictly guard against touching textStorage for local edits
        guard state.needsRemoteRefresh else {
            return
        }
        
        state.needsRemoteRefresh = false
        
        guard let storage = textView.textStorage else { return }
        let oldLength = storage.length
        let currentSelection = textView.selectedRange()
        
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
        textView.scrollRangeToVisible(newSelection)
    }
    
    public final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextKit2EditorRepresentable
        weak var textView: NoteCanvasTextView?
        
        init(_ parent: TextKit2EditorRepresentable) {
            self.parent = parent
        }
        
        public func textViewDidChangeSelection(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            let sel = tv.selectedRange()
            print("🎨 SELECTION CHANGED: \(sel)")
            DispatchQueue.main.async {
                self.parent.state.updateSelection(sel)
                self.parent.onSelectionChanged(sel)
            }
        }
        
        public func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            let replacement = replacementString ?? ""
            print("🔍 shouldChangeTextIn: range=\(affectedCharRange) repl='\(replacement)'")
            
            if replacement == "\n" {
                // Return key: Split block into two distinct blocks with new UUIDs
                if let _ = parent.state.bridge.splitBlock(at: affectedCharRange.location) {
                    if let storage = textView.textStorage {
                        let updatedAttributed = parent.state.bridge.renderAttributedString()
                        storage.setAttributedString(updatedAttributed)
                        let newCursorPos = min(affectedCharRange.location + 1, updatedAttributed.length)
                        textView.setSelectedRange(NSRange(location: newCursorPos, length: 0))
                        textView.scrollRangeToVisible(NSRange(location: newCursorPos, length: 0))
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
                print("🔍 CRDT INSERTED: '\(replacement)' at \(affectedCharRange.location)")
                print("🔍 STICKY MARKS: \(parent.state.bridge.getStickyMarks())")
            }
            
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
        self.formattingState = bridge.currentFormattingState(at: currentSelection)
    }
    
    public func updateSelection(_ newRange: NSRange) {
        self.currentSelection = newRange
        bridge.selectionDidChange(to: newRange)
        refreshFormattingState()
    }
    
    public func refreshFormattingState() {
        let newState = bridge.currentFormattingState(at: currentSelection)
        if formattingState != newState {
            print("🎨 PUBLISHING STATE: bold=\(newState.isBold) italic=\(newState.isItalic) block=\(newState.blockType)")
            formattingState = newState
        }
    }
    
    public func toggleBold() {
        bridge.toggleInlineMark(type: "bold", in: currentSelection)
        if currentSelection.length > 0 {
            onInPlaceFormatUpdate?()
        }
        refreshFormattingState()
    }
    
    public func toggleItalic() {
        bridge.toggleInlineMark(type: "italic", in: currentSelection)
        if currentSelection.length > 0 {
            onInPlaceFormatUpdate?()
        }
        refreshFormattingState()
    }
    
    public func toggleBlockType(_ type: EditorBlockType) {
        bridge.toggleBlockType(type, at: currentSelection.location)
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
