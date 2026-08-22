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
}
