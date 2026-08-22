import SwiftUI
import AppKit

/// Pure NSTextView wrapped in NSViewRepresentable for diagnostic isolation.
public struct BareMetalEditor: NSViewRepresentable {
    public init() {}
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.allowsUndo = true
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.string = "Type here to test."
        return scrollView
    }
    
    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        // DO NOTHING. Never overwrite.
    }
}
