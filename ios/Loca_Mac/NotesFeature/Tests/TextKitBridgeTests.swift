#if canImport(Testing)
import Foundation
import Testing

@Suite("Notes Feature - TextKit 2 CRDT Bridge Tests")
struct TextKitBridgeTests {
    
    @Test func testTypingGeneratesCRDTCheracterOperations() {
        let noteID = NoteID()
        let blockID = UUID()
        
        var doc = CRDTDoc(id: noteID, deviceID: "test-device")
        let initialBlock = CRDTBlock(id: blockID, type: "paragraph", text: CRDTText(string: "Hello", deviceID: "test-device"))
        doc.addBlock(initialBlock)
        
        let bridge = TextKitCRDTBridge(doc: doc, deviceID: "test-device")
        
        // Type " World" at index 5
        bridge.insertText(" World", at: 5)
        
        let rendered = bridge.renderAttributedString().string
        #expect(rendered == "Hello World")
        
        // Assert CRDT block text is updated
        let activeBlocks = bridge.doc.blocks.filter { !$0.isDeleted }
        #expect(activeBlocks.count == 1)
        #expect(activeBlocks.first?.text.string == "Hello World")
    }
    
    @Test func testBlockSplittingOnReturn() {
        let noteID = NoteID()
        let blockID = UUID()
        
        var doc = CRDTDoc(id: noteID, deviceID: "test-device")
        let initialBlock = CRDTBlock(id: blockID, type: "paragraph", text: CRDTText(string: "FirstLineSecondLine", deviceID: "test-device"))
        doc.addBlock(initialBlock)
        
        let bridge = TextKitCRDTBridge(doc: doc, deviceID: "test-device")
        
        // Split at index 9 ("FirstLine" | "SecondLine")
        let newBlockID = bridge.splitBlock(at: 9)
        #expect(newBlockID != nil)
        
        let activeBlocks = bridge.doc.blocks.filter { !$0.isDeleted }
        #expect(activeBlocks.count == 2)
        #expect(activeBlocks[0].text.string == "FirstLine")
        #expect(activeBlocks[1].text.string == "SecondLine")
        #expect(activeBlocks[0].sortKey < activeBlocks[1].sortKey)
    }
    
    @Test func testBlockMergeOnBackspace() {
        let noteID = NoteID()
        let b1ID = UUID()
        let b2ID = UUID()
        
        var doc = CRDTDoc(id: noteID, deviceID: "test-device")
        let b1 = CRDTBlock(id: b1ID, type: "paragraph", text: CRDTText(string: "Alpha", deviceID: "test-device"))
        let b2 = CRDTBlock(id: b2ID, type: "paragraph", text: CRDTText(string: "Beta", deviceID: "test-device"))
        doc.addBlock(b1)
        doc.addBlock(b2)
        
        let bridge = TextKitCRDTBridge(doc: doc, deviceID: "test-device")
        
        // Global length of "Alpha\n" is 6. Deleting at index 6 (start of "Beta") merges with "Alpha"
        bridge.deleteText(at: 6, length: 1)
        
        let activeBlocks = bridge.doc.blocks.filter { !$0.isDeleted }
        #expect(activeBlocks.count == 1)
        #expect(activeBlocks.first?.text.string == "AlphaBeta")
    }
    
    @Test func testBlockTypeConversion() {
        let noteID = NoteID()
        let blockID = UUID()
        
        var doc = CRDTDoc(id: noteID, deviceID: "test-device")
        let b = CRDTBlock(id: blockID, type: "paragraph", text: CRDTText(string: "Architecture", deviceID: "test-device"))
        doc.addBlock(b)
        
        let bridge = TextKitCRDTBridge(doc: doc, deviceID: "test-device")
        
        // Convert to Heading 1
        bridge.setBlockType("heading", at: 5, attributes: ["level": "1"])
        #expect(bridge.doc.blocks.first?.type == "heading")
        #expect(bridge.doc.blocks.first?.attributes["level"] == "1")
        
        // Convert to Checklist
        bridge.setBlockType("checklistItem", at: 5, attributes: ["isChecked": "false"])
        #expect(bridge.doc.blocks.first?.type == "checklistItem")
        
        // Toggle checklist
        bridge.toggleChecklist(at: 5)
        #expect(bridge.doc.blocks.first?.attributes["isChecked"] == "true")
    }
    
    // MARK: - Fix 1 Tests: Gutter Click Interactive Toggling
    
    @Test func testGutterClickTogglesChecklist() {
        let noteID = NoteID()
        let blockID = UUID()
        
        var doc = CRDTDoc(id: noteID, deviceID: "test-device")
        let item = CRDTBlock(id: blockID, type: "checklistItem", text: CRDTText(string: "Review Architecture", deviceID: "test-device"), attributes: ["isChecked": "false"])
        doc.addBlock(item)
        
        let bridge = TextKitCRDTBridge(doc: doc, deviceID: "test-device")
        
        // Target block resolved at location 0
        let target = bridge.resolveLocation(0)
        #expect(target?.block.type == "checklistItem")
        
        // Gutter click toggles checklist state
        bridge.toggleChecklist(blockID: blockID)
        #expect(bridge.block(for: blockID)?.attributes["isChecked"] == "true")
        
        // Click again toggles off
        bridge.toggleChecklist(blockID: blockID)
        #expect(bridge.block(for: blockID)?.attributes["isChecked"] == "false")
    }
    
    @Test func testGutterClickIgnoresParagraphs() {
        let noteID = NoteID()
        let blockID = UUID()
        
        var doc = CRDTDoc(id: noteID, deviceID: "test-device")
        let paragraph = CRDTBlock(id: blockID, type: "paragraph", text: CRDTText(string: "Regular text", deviceID: "test-device"))
        doc.addBlock(paragraph)
        
        let bridge = TextKitCRDTBridge(doc: doc, deviceID: "test-device")
        let target = bridge.resolveLocation(0)
        
        // Assert block is not checklistItem
        #expect(target?.block.type == "paragraph")
        #expect(target?.block.attributes["isChecked"] == nil)
    }
    
    // MARK: - Fix 2 Tests: Inline Formatting Spans
    
    @Test func testInlineBoldMarkGeneration() {
        let noteID = NoteID()
        let blockID = UUID()
        
        var doc = CRDTDoc(id: noteID, deviceID: "test-device")
        let paragraph = CRDTBlock(id: blockID, type: "paragraph", text: CRDTText(string: "I ate an apple today", deviceID: "test-device"))
        doc.addBlock(paragraph)
        
        let bridge = TextKitCRDTBridge(doc: doc, deviceID: "test-device")
        
        // Select "apple" (range location: 9, length: 5)
        bridge.applyInlineMark(type: "bold", in: NSRange(location: 9, length: 5))
        
        let targetBlock = bridge.block(for: blockID)
        #expect(targetBlock?.marks.count == 1)
        #expect(targetBlock?.marks.first?.type == "bold")
        #expect(targetBlock?.marks.first?.startIndex == 9)
        #expect(targetBlock?.marks.first?.endIndex == 14)
    }
    
    @Test func testInlineMarkRendering() {
        let noteID = NoteID()
        let blockID = UUID()
        
        var doc = CRDTDoc(id: noteID, deviceID: "test-device")
        var paragraph = CRDTBlock(id: blockID, type: "paragraph", text: CRDTText(string: "ItalicText NormalText", deviceID: "test-device"))
        paragraph.applyMark(type: "italic", startIndex: 0, endIndex: 10)
        doc.addBlock(paragraph)
        
        let bridge = TextKitCRDTBridge(doc: doc, deviceID: "test-device")
        let attributed = bridge.renderAttributedString()
        
        #expect(attributed.string == "ItalicText NormalText")
        #expect(bridge.block(for: blockID)?.marks.first?.type == "italic")
    }
    
    @Test func testTypingInsideMarkInheritsFormat() {
        let noteID = NoteID()
        let blockID = UUID()
        
        var doc = CRDTDoc(id: noteID, deviceID: "test-device")
        var paragraph = CRDTBlock(id: blockID, type: "paragraph", text: CRDTText(string: "Swift Concurrency", deviceID: "test-device"))
        // Mark "Swift" as bold (0...5)
        paragraph.applyMark(type: "bold", startIndex: 0, endIndex: 5)
        doc.addBlock(paragraph)
        
        let bridge = TextKitCRDTBridge(doc: doc, deviceID: "test-device")
        
        // Type "UI" at index 5 (inside bold mark)
        bridge.insertText("UI", at: 5)
        
        let targetBlock = bridge.block(for: blockID)
        #expect(targetBlock?.text.string == "SwiftUI Concurrency")
        // Bold mark expands from 0...5 to 0...7
        #expect(targetBlock?.marks.first?.startIndex == 0)
        #expect(targetBlock?.marks.first?.endIndex == 7)
    }
    
    // MARK: - Typing Pipeline Regression Tests (Option A Contract)
    
    @Test func testLocalTypingRendersAndReachesCRDT() {
        let noteID = NoteID()
        let blockID = UUID()
        
        var doc = CRDTDoc(id: noteID, deviceID: "test-device")
        doc.addBlock(CRDTBlock(id: blockID, type: "paragraph", text: CRDTText(string: "", deviceID: "test-device")))
        
        let bridge = TextKitCRDTBridge(doc: doc, deviceID: "test-device")
        let state = EditorBridgeState(bridge: bridge)
        
        // Simulate typing "H", "e", "y"
        bridge.insertText("H", at: 0)
        bridge.insertText("e", at: 1)
        bridge.insertText("y", at: 2)
        
        // Assert CRDT model has "Hey"
        #expect(bridge.doc.blocks.first?.text.string == "Hey")
        
        // Assert rendered attributed string matches
        let rendered = bridge.renderAttributedString().string
        #expect(rendered == "Hey")
    }
    
    @Test func testLocalEditDoesNotTriggerRemoteRenderLoop() {
        let noteID = NoteID()
        var doc = CRDTDoc(id: noteID, deviceID: "test-device")
        doc.addBlock(CRDTBlock(id: UUID(), type: "paragraph", text: CRDTText(string: "Initial", deviceID: "test-device")))
        
        let bridge = TextKitCRDTBridge(doc: doc, deviceID: "test-device")
        let state = EditorBridgeState(bridge: bridge)
        
        // Local edit does not flag needsRemoteRefresh
        bridge.insertText(" Text", at: 7)
        #expect(state.needsRemoteRefresh == false)
        
        // Remote update explicitly sets needsRemoteRefresh
        var remoteDoc = bridge.doc
        remoteDoc.insertText(" Remote", at: 12, in: remoteDoc.blocks.first!.id)
        state.updateDocFromRemote(remoteDoc)
        #expect(state.needsRemoteRefresh == true)
    }
}
#endif
