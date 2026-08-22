import Foundation
import AppKit

/// Supported rich-text block types for formatting controls and typography mapping.
public enum EditorBlockType: String, Equatable, CaseIterable, Sendable {
    case h1
    case h2
    case h3
    case checklist
    case bullet
    case paragraph
    
    public var rawBlockType: (type: String, attributes: [String: String]) {
        switch self {
        case .h1: return ("heading", ["level": "1"])
        case .h2: return ("heading", ["level": "2"])
        case .h3: return ("heading", ["level": "3"])
        case .checklist: return ("checklistItem", ["isChecked": "false"])
        case .bullet: return ("bullet", [:])
        case .paragraph: return ("paragraph", [:])
        }
    }
}

/// Equatable formatting state derived from CRDT document truth for stateful toolbar buttons.
public struct FormattingState: Equatable, Sendable {
    public var isBold: Bool
    public var isItalic: Bool
    public var blockType: EditorBlockType
    
    public init(isBold: Bool = false, isItalic: Bool = false, blockType: EditorBlockType = .paragraph) {
        self.isBold = isBold
        self.isItalic = isItalic
        self.blockType = blockType
    }
}

/// Bidirectional bridging engine translating TextKit layout offsets and mouse events to granular CRDT operations.
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
        applyInlineMarkInternal(type: type, in: globalRange)
    }
    
    public func removeInlineMark(type: String, in globalRange: NSRange) {
        lock.lock()
        defer { lock.unlock() }
        removeInlineMarkInternal(type: type, in: globalRange)
    }
    
    public func toggleInlineMark(type: String, in globalRange: NSRange) {
        print("🎨 BRIDGE TOGGLE: \(type) range=\(globalRange)")
        lock.lock()
        defer { lock.unlock() }
        
        if globalRange.length > 0 {
            let active = activeInlineMarksInternal(at: globalRange)
            if active.contains(type) {
                removeInlineMarkInternal(type: type, in: globalRange)
            } else {
                applyInlineMarkInternal(type: type, in: globalRange)
            }
        }
    }
    
    private func applyInlineMarkInternal(type: String, in globalRange: NSRange) {
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
    
    private func removeInlineMarkInternal(type: String, in globalRange: NSRange) {
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
                    doc.blocks[idx].removeMark(type: type, startIndex: startRel, endIndex: endRel)
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
    
    /// Converts current block to the requested block type, or reverts to .paragraph if already active.
    public func toggleBlockType(_ targetType: EditorBlockType, at globalLocation: Int) {
        print("🎨 BRIDGE TOGGLE BLOCK: \(targetType) loc=\(globalLocation)")
        lock.lock()
        defer { lock.unlock() }
        
        guard let target = resolveLocationInternal(globalLocation) else { return }
        let currentType = blockType(for: target.block)
        
        let destination: EditorBlockType = (currentType == targetType) ? .paragraph : targetType
        let raw = destination.rawBlockType
        
        if let idx = doc.blocks.firstIndex(where: { $0.id == target.block.id }) {
            doc.blocks[idx].type = raw.type
            doc.blocks[idx].attributes = raw.attributes
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
    
    // MARK: - Formatting State Derivation (Source of Truth = CRDT)
    
    public func activeInlineMarks(at selection: NSRange) -> Set<String> {
        lock.lock()
        defer { lock.unlock() }
        return activeInlineMarksInternal(at: selection)
    }
    
    public func blockType(at location: Int) -> EditorBlockType {
        lock.lock()
        defer { lock.unlock() }
        guard let target = resolveLocationInternal(location) else { return .paragraph }
        return blockType(for: target.block)
    }
    
    public func currentFormattingState(at selection: NSRange, stickyBold: Bool = false, stickyItalic: Bool = false) -> FormattingState {
        lock.lock()
        defer { lock.unlock() }
        
        let marks = activeInlineMarksInternal(at: selection)
        let isBold = stickyBold || marks.contains("bold")
        let isItalic = stickyItalic || marks.contains("italic")
        
        let bType: EditorBlockType
        if let target = resolveLocationInternal(selection.location) {
            bType = blockType(for: target.block)
        } else {
            bType = .paragraph
        }
        
        return FormattingState(isBold: isBold, isItalic: isItalic, blockType: bType)
    }
    
    private func blockType(for block: CRDTBlock) -> EditorBlockType {
        if block.type == "heading" {
            let level = block.attributes["level"] ?? "1"
            if level == "1" { return .h1 }
            if level == "2" { return .h2 }
            if level == "3" { return .h3 }
            return .h1
        } else if block.type == "checklistItem" {
            return .checklist
        } else if block.type == "bullet" {
            return .bullet
        } else {
            return .paragraph
        }
    }
    
    private func activeInlineMarksInternal(at selection: NSRange) -> Set<String> {
        let activeBlocks = doc.blocks.filter { !$0.isDeleted }
        guard !activeBlocks.isEmpty else { return [] }
        
        if selection.length == 0 {
            let checkPos = max(0, selection.location > 0 ? selection.location - 1 : 0)
            guard let target = resolveLocationInternal(checkPos) else { return [] }
            
            var result = Set<String>()
            for mark in target.block.marks {
                if target.relativeIndex >= mark.startIndex && target.relativeIndex < mark.endIndex {
                    result.insert(mark.type)
                }
            }
            return result
        } else {
            var boldCovered = true
            var italicCovered = true
            var foundAnyBlock = false
            
            var runningOffset = 0
            for block in activeBlocks {
                let blockLen = block.text.string.count
                let blockRange = NSRange(location: runningOffset, length: blockLen)
                let intersection = NSIntersectionRange(selection, blockRange)
                
                if intersection.length > 0 {
                    foundAnyBlock = true
                    let startRel = intersection.location - runningOffset
                    let endRel = startRel + intersection.length
                    
                    let hasBold = block.marks.contains { $0.type == "bold" && $0.startIndex <= startRel && $0.endIndex >= endRel }
                    if !hasBold { boldCovered = false }
                    
                    let hasItalic = block.marks.contains { $0.type == "italic" && $0.startIndex <= startRel && $0.endIndex >= endRel }
                    if !hasItalic { italicCovered = false }
                }
                runningOffset += blockLen + 1
            }
            
            guard foundAnyBlock else { return [] }
            var result = Set<String>()
            if boldCovered { result.insert("bold") }
            if italicCovered { result.insert("italic") }
            return result
        }
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
