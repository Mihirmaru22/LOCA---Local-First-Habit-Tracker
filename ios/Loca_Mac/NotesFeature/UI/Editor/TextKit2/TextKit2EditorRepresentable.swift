// Editing Contract: Option A (Native Apply + Observe)
// 1. textView(_:shouldChangeTextIn:replacementString:) updates the CRDT model and returns true for standard typing.
// 2. AppKit text engine natively commits glyphs to the backing store at 120fps with zero latency.
// 3. Return key triggers a custom block split and synchronous re-render with cursor placement.
// 4. Remote CRDT merges update textStorage only on remote deltas, preventing local render loops.

import Foundation
import Combine
import SwiftUI
import AppKit

/// Subclassed NSTextView supporting interactive checkbox gutter clicks, first responder handling, and text engine integration.
public final class NoteCanvasTextView: NSTextView {
    
    public var onGutterClicked: ((NSPoint) -> Bool)?
    
    public override var acceptsFirstResponder: Bool { true }
    public override var canBecomeKeyView: Bool { true }
    public override var needsPanelToBecomeKey: Bool { true }
    
    public override func becomeFirstResponder() -> Bool {
        return super.becomeFirstResponder()
    }
    
    public func stackAudit(_ tag: String) {
        print("🧭 [\(tag)] textStorageNil=\(self.textStorage == nil) layoutManagerNil=\(self.layoutManager == nil) length=\(self.textStorage?.length ?? -1)")
    }
    
    public override func keyDown(with event: NSEvent) {
        print("🔴 KEYDOWN REACHED APPKIT: \(event.characters ?? "")")
        super.keyDown(with: event)
    }
    
    public override func insertText(_ string: Any, replacementRange: NSRange) {
        stackAudit("insertText")
        print("🟣 INSERT TEXT CALLED: string=\(string), range=\(replacementRange)")
        print("🧪 textStorage is nil: \(self.textStorage == nil)")
        print("🧪 textStorage.length: \(self.textStorage?.length ?? -1)")
        print("🧪 selectedRange: \(self.selectedRange())")
        print("🧪 container.size: \(self.textContainer?.containerSize ?? .zero)")
        super.insertText(string, replacementRange: replacementRange)
    }
    
    public override func shouldChangeText(in affectedCharRange: NSRange, replacementString: String?) -> Bool {
        let result = super.shouldChangeText(in: affectedCharRange, replacementString: replacementString)
        print("🔥 NSTEXTVIEW.shouldChangeText range=\(affectedCharRange) repl=\(replacementString ?? "") handled=\(result)")
        return result
    }
    
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let result = super.performKeyEquivalent(with: event)
        print("🟠 PERFORM KEY EQUIVALENT: \(event.characters ?? ""), handled=\(result)")
        return result
    }
    
    public override func doCommand(by commandSelector: Selector) {
        print("🟤 DO COMMAND: \(commandSelector)")
        super.doCommand(by: commandSelector)
    }
    
    public override func mouseDown(with event: NSEvent) {
        stackAudit("mouseDown")
        // Ensure text view claims first responder status on click
        if window?.firstResponder != self {
            window?.makeFirstResponder(self)
        }
        print("📍 MOUSE DOWN: window.firstResponder is \(String(describing: window?.firstResponder))")
        print("📍 TYPING ATTRIBUTES: \(self.typingAttributes)")
        
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
        print("🔵 MAKE NSVIEW CALLED")
        
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
            
            self.onKeystroke(self.state.bridge.doc)
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
        textView.stackAudit("makeNSView.end")
        
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        textView.stackAudit("updateNSView.start")
        print("🟡 updateNSView CALLED: needsRemoteRefresh=\(state.needsRemoteRefresh)")
        
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
        textView.stackAudit("updateNSView.end")
    }
    
    public final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextKit2EditorRepresentable
        weak var textView: NoteCanvasTextView?
        
        init(_ parent: TextKit2EditorRepresentable) {
            self.parent = parent
        }
        
        public func textViewDidChangeSelection(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.state.currentSelection = tv.selectedRange()
            parent.onSelectionChanged(tv.selectedRange())
        }
        
        public func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            let replacement = replacementString ?? ""
            print("🔍 shouldChangeTextIn CALLED: range=\(affectedCharRange), replacement='\(replacement)'")
            
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
                    print("🔴 DELEGATE RETURNING: false (Block Split Handled)")
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
            
            // 3. Return true to let AppKit apply edit to backing store natively with 0ms latency
            print("🟢 DELEGATE RETURNING: true (Native Apply)")
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
    @Published public var needsRemoteRefresh: Bool = false
    public var currentSelection: NSRange = NSRange(location: 0, length: 0)
    
    public init(bridge: TextKitCRDTBridge) {
        self.bridge = bridge
    }
    
    public func updateDocFromRemote(_ newDoc: CRDTDoc) {
        bridge.doc = newDoc
        needsRemoteRefresh = true
    }
    
    public func requestFormatRefresh() {
        needsRemoteRefresh = true
    }
}
