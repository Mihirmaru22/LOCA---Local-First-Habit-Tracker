import Foundation
import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - DocumentExportService (Sovereign Local-First Export Engine)

public final class DocumentExportService {
    
    public static let shared = DocumentExportService()
    private init() {}
    
    public func exportMarkdown(title: String, attributedText: NSAttributedString) {
        let markdown = RichTextTypography.convertAttributedStringToMarkdown(attributedString: attributedText)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(title).md"
        panel.allowedContentTypes = [.plainText]
        
        if panel.runModal() == .OK, let url = panel.url {
            try? markdown.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    public func exportPlainText(title: String, text: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(title).txt"
        panel.allowedContentTypes = [.plainText]
        
        if panel.runModal() == .OK, let url = panel.url {
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }
    
    public func exportPDF(title: String, attributedText: NSAttributedString) {
        let printInfo = NSPrintInfo.shared
        printInfo.paperSize = NSSize(width: 595.2, height: 841.8) // A4
        printInfo.topMargin = 40
        printInfo.bottomMargin = 40
        printInfo.leftMargin = 40
        printInfo.rightMargin = 40
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered = false
        
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 515.2, height: 761.8))
        textView.textStorage?.setAttributedString(attributedText)
        
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(title).pdf"
        panel.allowedContentTypes = [.pdf]
        
        if panel.runModal() == .OK, let url = panel.url {
            let data = textView.dataWithPDF(inside: textView.bounds)
            try? data.write(to: url)
        }
    }
}
