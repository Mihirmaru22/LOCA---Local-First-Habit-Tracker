import SwiftUI
import AppKit

/// SwiftUI Representable wrapping AppKit NSTextView backed by TextKit 2 and wired to TextKitCRDTBridge.
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
        textLayoutManager.textContainer = textContainer
        
        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.drawsBackground = false
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textContainerInset = NSSize(width: 24, height: 16)
        
        // Initial render
        let initialAttributed = state.bridge.renderAttributedString()
        textContentStorage.attributedString = initialAttributed
        
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView
        
        context.coordinator.textView = textView
        context.coordinator.textContentStorage = textContentStorage
        
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView,
              let textContentStorage = context.coordinator.textContentStorage else { return }
        
        if state.needsRemoteRefresh {
            state.needsRemoteRefresh = false
            
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
        }
    }
    
    public final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TextKit2EditorRepresentable
        weak var textView: NSTextView?
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
                // Return key: Split block
                parent.state.bridge.splitBlock(at: affectedCharRange.location)
            } else if replacement.isEmpty && affectedCharRange.length > 0 {
                // Delete / Backspace
                parent.state.bridge.deleteText(at: affectedCharRange.location, length: affectedCharRange.length)
            } else if !replacement.isEmpty {
                // Character Insertion
                parent.state.bridge.insertText(replacement, at: affectedCharRange.location)
            }
            
            // Re-render attributed string to maintain typography
            if let storage = textContentStorage {
                let updatedAttributed = parent.state.bridge.renderAttributedString()
                storage.attributedString = updatedAttributed
            }
            
            // Notify parent
            parent.onKeystroke(parent.state.bridge.doc)
            return false // Intercepted and handled via CRDT bridge
        }
    }
}

/// Observable state container synchronizing the SwiftUI shell with the active TextKitCRDTBridge.
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
