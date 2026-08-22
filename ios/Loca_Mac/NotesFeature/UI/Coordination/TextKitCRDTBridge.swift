import Foundation
import AppKit

/// Bidirectional bridging engine translating TextKit 2 layout offsets and mouse events to granular CRDT operations.
public final class TextKitCRDTBridge: @unchecked Sendable {
    
    public var doc: CRDTDoc
    public let deviceID: String
    private let lock = NSLock()
    
    // Cached map of block ID to its global NSRange in the rendered attributed string
    public private(set) var blockRanges: [UUID: NSRange] = [:]
    
    public init(doc: CRDTDoc, deviceID: String = "local-device") {
        self.doc = doc
        self.deviceID = deviceID
    }
    
    // MARK: - Block Range Resolution
    
    /// Resolves a global character index to an enclosing CRDT block and relative index within that block.
    public func resolveLocation(_ globalIndex: Int) -> (block: CRDTBlock, blockIndex: Int, relativeIndex: Int)? {
        lock.lock()
        defer { lock.unlock() }
        return resolveLocationInternal(globalIndex)
    }
    
    public func block(for blockID: UUID) -> CRDTBlock? {
        lock.lock()
        defer { lock.unlock() }
        return doc.blocks.first(where: { $0.id == blockID && !$0.isDeleted })
    }
    
    // MARK: - Keystroke to CRDT Translation
    
    /// Inserts text at a global character location.
    public func insertText(_ text: String, at globalLocation: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let target = resolveLocationInternal(globalLocation) else {
            let newBlock = CRDTBlock(id: UUID(), type: "paragraph", text: CRDTText(string: text, deviceID: deviceID))
            doc.addBlock(newBlock)
            return
        }
        
        if let idx = doc.blocks.firstIndex(where: { $0.id == target.block.id }) {
            doc.blocks[idx].adjustMarksForInsertion(at: target.relativeIndex, length: text.count)
        }
        doc.insertText(text, at: target.relativeIndex, in: target.block.id)
    }
    
    /// Deletes text at a global character location.
    public func deleteText(at globalLocation: Int, length: Int = 1) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let target = resolveLocationInternal(globalLocation) else { return }
        
        if target.relativeIndex == 0 && target.blockIndex > 0 && length == 1 {
            mergeBlockWithPreceding(targetBlockIndex: target.blockIndex)
        } else {
            if let idx = doc.blocks.firstIndex(where: { $0.id == target.block.id }) {
                doc.blocks[idx].adjustMarksForDeletion(at: target.relativeIndex, length: length)
            }
            doc.deleteText(at: target.relativeIndex, length: length, in: target.block.id)
        }
    }
    
    /// Splits the current block on Return keypress.
    @discardableResult
    public func splitBlock(at globalLocation: Int) -> UUID? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let target = resolveLocationInternal(globalLocation) else { return nil }
        
        let currentString = target.block.text.string
        let textAfter = String(currentString.dropFirst(target.relativeIndex))
        
        if target.relativeIndex < currentString.count {
            if let idx = doc.blocks.firstIndex(where: { $0.id == target.block.id }) {
                doc.blocks[idx].adjustMarksForDeletion(at: target.relativeIndex, length: currentString.count - target.relativeIndex)
            }
            doc.deleteText(at: target.relativeIndex, length: currentString.count - target.relativeIndex, in: target.block.id)
        }
        
        let newBlockID = UUID()
        let newType = (target.block.type == "checklistItem") ? "checklistItem" : "paragraph"
        let newAttributes = (target.block.type == "checklistItem") ? ["isChecked": "false"] : [:]
        
        let newBlock = CRDTBlock(
            id: newBlockID,
            type: newType,
            text: CRDTText(string: textAfter, deviceID: deviceID),
            attributes: newAttributes,
            lastModified: Date().timeIntervalSince1970
        )
        
        doc.insertBlock(newBlock, afterBlockID: target.block.id)
        return newBlockID
    }
    
    private func mergeBlockWithPreceding(targetBlockIndex: Int) {
        let active = doc.blocks.filter { !$0.isDeleted }
        guard targetBlockIndex > 0, targetBlockIndex < active.count else { return }
        
        let prevBlock = active[targetBlockIndex - 1]
        let currentBlock = active[targetBlockIndex]
        
        let currentText = currentBlock.text.string
        if !currentText.isEmpty {
            let offset = prevBlock.text.string.count
            if let prevIdx = doc.blocks.firstIndex(where: { $0.id == prevBlock.id }) {
                for mark in currentBlock.marks {
                    doc.blocks[prevIdx].marks.append(
                        CRDTTextMark(
                            type: mark.type,
                            startIndex: mark.startIndex + offset,
                            endIndex: mark.endIndex + offset
                        )
                    )
                }
            }
            doc.insertText(currentText, at: prevBlock.text.string.count, in: prevBlock.id)
        }
        
        doc.removeBlock(blockID: currentBlock.id)
    }
    
    // MARK: - Formatting & Inline Marks
    
    public func applyInlineMark(type: String, in globalRange: NSRange) {
        lock.lock()
        defer { lock.unlock() }
        
        let activeBlocks = doc.blocks.filter { !$0.isDeleted }
        var runningOffset = 0
        
        for block in activeBlocks {
            let blockLen = block.text.string.count
            let blockRange = NSRange(location: runningOffset, length: blockLen)
            
            let intersection = NSIntersectionRange(globalRange, blockRange)
            if intersection.length > 0 {
                let startRel = intersection.location - runningOffset
                let endRel = startRel + intersection.length
                
                if let idx = doc.blocks.firstIndex(where: { $0.id == block.id }) {
                    doc.blocks[idx].applyMark(type: type, startIndex: startRel, endIndex: endRel)
                    _ = doc.vectorClock.increment(for: deviceID)
                }
            }
            runningOffset += blockLen + 1
        }
    }
    
    public func setBlockType(_ type: String, at globalLocation: Int, attributes: [String: String] = [:]) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let target = resolveLocationInternal(globalLocation) else { return }
        if let idx = doc.blocks.firstIndex(where: { $0.id == target.block.id }) {
            doc.blocks[idx].type = type
            for (k, v) in attributes {
                doc.blocks[idx].attributes[k] = v
            }
            doc.blocks[idx].lastModified = Date().timeIntervalSince1970
            _ = doc.vectorClock.increment(for: deviceID)
        }
    }
    
    public func toggleChecklist(at globalLocation: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let target = resolveLocationInternal(globalLocation) else { return }
        doc.toggleChecklist(blockID: target.block.id)
    }
    
    public func toggleChecklist(blockID: UUID) {
        lock.lock()
        defer { lock.unlock() }
        doc.toggleChecklist(blockID: blockID)
    }
    
    // MARK: - Attributed String Generation & Inline Mark Rendering
    
    public func renderAttributedString() -> NSAttributedString {
        lock.lock()
        defer { lock.unlock() }
        
        let result = NSMutableAttributedString()
        blockRanges.removeAll()
        
        let activeBlocks = doc.blocks.filter { !$0.isDeleted }
        if activeBlocks.isEmpty {
            let emptyAttrs = TextKit2BlockAttributes.attributes(for: "paragraph")
            return NSAttributedString(string: "", attributes: emptyAttrs)
        }
        
        for (index, block) in activeBlocks.enumerated() {
            let startLocation = result.length
            let blockAttrs = TextKit2BlockAttributes.attributes(for: block.type, attributes: block.attributes)
            let blockText = block.text.string
            
            let mutableBlock = NSMutableAttributedString(string: blockText, attributes: blockAttrs)
            
            // Apply inline marks (Bold / Italic)
            for mark in block.marks {
                let clampedStart = max(0, min(mark.startIndex, blockText.count))
                let clampedEnd = max(clampedStart, min(mark.endIndex, blockText.count))
                let markRange = NSRange(location: clampedStart, length: clampedEnd - clampedStart)
                
                if markRange.length > 0 {
                    if mark.type == "bold" {
                        let baseFont = (blockAttrs[.font] as? NSFont) ?? NSFont.systemFont(ofSize: 14)
                        let boldFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
                        mutableBlock.addAttribute(.font, value: boldFont, range: markRange)
                    } else if mark.type == "italic" {
                        let baseFont = (blockAttrs[.font] as? NSFont) ?? NSFont.systemFont(ofSize: 14)
                        let italicFont = NSFontManager.shared.convert(baseFont, toHaveTrait: .italicFontMask)
                        mutableBlock.addAttribute(.font, value: italicFont, range: markRange)
                    }
                }
            }
            
            result.append(mutableBlock)
            
            let endLocation = result.length
            blockRanges[block.id] = NSRange(location: startLocation, length: endLocation - startLocation)
            
            // Trailing newline between blocks
            if index < activeBlocks.count - 1 {
                result.append(NSAttributedString(string: "\n", attributes: blockAttrs))
            }
        }
        
        return result
    }
    
    private func resolveLocationInternal(_ globalIndex: Int) -> (block: CRDTBlock, blockIndex: Int, relativeIndex: Int)? {
        let activeBlocks = doc.blocks.filter { !$0.isDeleted }
        guard !activeBlocks.isEmpty else { return nil }
        
        var runningOffset = 0
        for (idx, block) in activeBlocks.enumerated() {
            let blockLen = block.text.string.count
            if globalIndex >= runningOffset && globalIndex <= runningOffset + blockLen {
                let relative = globalIndex - runningOffset
                return (block, idx, relative)
            }
            runningOffset += blockLen + 1
        }
        
        if let last = activeBlocks.last {
            return (last, activeBlocks.count - 1, last.text.string.count)
        }
        return nil
    }
}
