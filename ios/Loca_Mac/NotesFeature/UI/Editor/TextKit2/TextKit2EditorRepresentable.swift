// Editing Contract: Option A (Native Apply + Observe)
// 1. textView(_:shouldChangeTextIn:replacementString:) updates the CRDT model and returns true for standard typing.
// 2. TextKit 2 natively commits glyphs to the backing store at 120fps with zero latency.
// 3. Return key triggers a custom block split and synchronous re-render with cursor placement.
// 4. Remote CRDT merges update NSTextContentStorage only on remote deltas, preventing local render loops.

import Foundation
import Combine
import SwiftUI
import AppKit

/// Subclassed NSTextView supporting interactive checkbox gutter clicks, first responder handling, and TextKit 2 integration.
public final class NoteCanvasTextView: NSTextView {
    
    public var onGutterClicked: ((NSPoint) -> Bool)?
    
    public override var acceptsFirstResponder: Bool { true }
    public override var canBecomeKeyView: Bool { true }
    
    public override func becomeFirstResponder() -> Bool {
        return super.becomeFirstResponder()
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

/// SwiftUI Representable wrapping AppKit NoteCanvasTextView backed by TextKit 2 and wired to TextKitCRDTBridge.
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
        let textContentStorage = NSTextContentStorage()
        let textLayoutManager = NSTextLayoutManager()
        textContentStorage.addTextLayoutManager(textLayoutManager)
        
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textContainer.lineFragmentPadding = 0
        textContainer.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textLayoutManager.textContainer = textContainer
        
        let textView = NoteCanvasTextView(frame: .zero, textContainer: textContainer)
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.drawsBackground = false
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textContainerInset = NSSize(width: 24, height: 16)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.typingAttributes = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.labelColor
        ]
        
        // Gutter Click Handler
        textView.onGutterClicked = { [weak textView, weak textContentStorage] clickPoint in
            guard let tv = textView, let storage = textContentStorage else { return false }
            
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
            storage.attributedString = updatedAttributed
            
            self.onKeystroke(self.state.bridge.doc)
            return true
        }
        
        // Initial render
        let initialAttributed = state.bridge.renderAttributedString()
        textContentStorage.attributedString = initialAttributed
        
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView
        
        context.coordinator.textView = textView
        context.coordinator.textContentStorage = textContentStorage
        
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView,
              let textContentStorage = context.coordinator.textContentStorage else { return }
        
        if state.needsRemoteRefresh {
            DispatchQueue.main.async {
                self.state.needsRemoteRefresh = false
            }
            
            let oldLength = textContentStorage.attributedString?.length ?? 0
            let currentSelection = textView.selectedRange()
            
            let newAttributed = state.bridge.renderAttributedString()
            textContentStorage.attributedString = newAttributed
            
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
    }
    
    public final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextKit2EditorRepresentable
        weak var textView: NoteCanvasTextView?
        weak var textContentStorage: NSTextContentStorage?
        
        init(_ parent: TextKit2EditorRepresentable) {
            self.parent = parent
        }
        
        public func textViewDidChangeSelection(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.onSelectionChanged(tv.selectedRange())
        }
        
        public func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            let replacement = replacementString ?? ""
            
            if replacement == "\n" {
                // Return key: Split block into two distinct blocks with new UUIDs
                if let _ = parent.state.bridge.splitBlock(at: affectedCharRange.location) {
                    if let storage = textContentStorage {
                        let updatedAttributed = parent.state.bridge.renderAttributedString()
                        storage.attributedString = updatedAttributed
                        let newCursorPos = min(affectedCharRange.location + 1, updatedAttributed.length)
                        textView.setSelectedRange(NSRange(location: newCursorPos, length: 0))
                        textView.scrollRangeToVisible(NSRange(location: newCursorPos, length: 0))
                    }
                    parent.onKeystroke(parent.state.bridge.doc)
                    return false
                }
            }
            
            // Standard Typing / Deletion / Replacement:
            // 1. Update CRDT model synchronously
            if replacement.isEmpty && affectedCharRange.length > 0 {
                parent.state.bridge.deleteText(at: affectedCharRange.location, length: affectedCharRange.length)
            } else if !replacement.isEmpty {
                parent.state.bridge.insertText(replacement, at: affectedCharRange.location)
            }
            
            // 2. Notify parent onKeystroke for debounced autosave
            parent.onKeystroke(parent.state.bridge.doc)
            
            // 3. Return true to let TextKit 2 apply edit to backing store natively with 0ms latency
            return true
        }
        
        public func textDidChange(_ notification: Notification) {
            guard let tv = textView else { return }
            tv.typingAttributes = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.labelColor
            ]
        }
    }
}

/// Observable state container synchronizing the SwiftUI shell with the active TextKitCRDTBridge.
@MainActor
public final class EditorBridgeState: ObservableObject {
    @Published public var bridge: TextKitCRDTBridge
    @Published public var needsRemoteRefresh: Bool = false
    
    public init(bridge: TextKitCRDTBridge) {
        self.bridge = bridge
    }
    
    public func updateDocFromRemote(_ newDoc: CRDTDoc) {
        bridge.doc = newDoc
        needsRemoteRefresh = true
    }
}
