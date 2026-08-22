import Foundation
import AppKit

/// Bidirectional bridging engine translating TextKit 2 layout offsets to granular CRDT operations.
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
        
        let activeBlocks = doc.blocks.filter { !$0.isDeleted }
        guard !activeBlocks.isEmpty else { return nil }
        
        var runningOffset = 0
        for (idx, block) in activeBlocks.enumerated() {
            let blockLen = block.text.string.count
            // If location is within block or at end of this block (before newline)
            if globalIndex >= runningOffset && globalIndex <= runningOffset + blockLen {
                let relative = globalIndex - runningOffset
                return (block, idx, relative)
            }
            runningOffset += blockLen + 1 // +1 for trailing newline
        }
        
        // Fallback: Return last active block
        if let last = activeBlocks.last {
            return (last, activeBlocks.count - 1, last.text.string.count)
        }
        return nil
    }
    
    // MARK: - Keystroke to CRDT Translation
    
    /// Inserts text at a global character location.
    public func insertText(_ text: String, at globalLocation: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let target = resolveLocationInternal(globalLocation) else {
            // Document has no active blocks: add initial block
            let newBlock = CRDTBlock(id: UUID(), type: "paragraph", text: CRDTText(string: text, deviceID: deviceID))
            doc.addBlock(newBlock)
            return
        }
        
        doc.insertText(text, at: target.relativeIndex, in: target.block.id)
    }
    
    /// Deletes text at a global character location.
    public func deleteText(at globalLocation: Int, length: Int = 1) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let target = resolveLocationInternal(globalLocation) else { return }
        
        if target.relativeIndex == 0 && target.blockIndex > 0 && length == 1 {
            // Backspace at start of block -> Merge with preceding block
            mergeBlockWithPreceding(targetBlockIndex: target.blockIndex)
        } else {
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
        
        // Truncate current block
        if target.relativeIndex < currentString.count {
            doc.deleteText(at: target.relativeIndex, length: currentString.count - target.relativeIndex, in: target.block.id)
        }
        
        // Insert new block after current block
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
    
    /// Merges the block at `targetBlockIndex` into the preceding block.
    private func mergeBlockWithPreceding(targetBlockIndex: Int) {
        let active = doc.blocks.filter { !$0.isDeleted }
        guard targetBlockIndex > 0, targetBlockIndex < active.count else { return }
        
        let prevBlock = active[targetBlockIndex - 1]
        let currentBlock = active[targetBlockIndex]
        
        let currentText = currentBlock.text.string
        if !currentText.isEmpty {
            doc.insertText(currentText, at: prevBlock.text.string.count, in: prevBlock.id)
        }
        
        // Remove current block
        doc.removeBlock(blockID: currentBlock.id)
    }
    
    /// Converts the enclosing block type at global location.
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
    
    /// Toggles the checklist state for the enclosing block at global location.
    public func toggleChecklist(at globalLocation: Int) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let target = resolveLocationInternal(globalLocation) else { return }
        doc.toggleChecklist(blockID: target.block.id)
    }
    
    // MARK: - Attributed String Generation & Range Tracking
    
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
            
            let attributedBlock = NSAttributedString(string: blockText, attributes: blockAttrs)
            result.append(attributedBlock)
            
            let endLocation = result.length
            blockRanges[block.id] = NSRange(location: startLocation, length: endLocation - startLocation)
            
            // Append trailing newline between blocks (except last)
            if index < activeBlocks.count - 1 {
                result.append(NSAttributedString(string: "\n", attributes: blockAttrs))
            }
        }
        
        return result
    }
    
    // Internal helper without lock
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
