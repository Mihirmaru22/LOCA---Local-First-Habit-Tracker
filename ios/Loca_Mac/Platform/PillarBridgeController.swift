import Foundation
import SwiftData
import SwiftUI
import AppKit

// MARK: - PillarBridgeController (Inter-Pillar Flow Engine)

@MainActor
final class PillarBridgeController {
    
    static let shared = PillarBridgeController()
    private init() {}
    
    // MARK: - Bridge 1: BrainStorm Note -> Work Project
    
    @discardableResult
    func sendNoteToWork(
        note: BrainStormNote,
        context: ModelContext,
        archiveOriginal: Bool = false
    ) -> WorkProject {
        let project = WorkProject(
            title: note.title.isEmpty ? "New Project" : note.title,
            icon: "folder.fill",
            colorHex: "#3B82F6",
            briefPlainText: note.bodyText,
            briefRTFData: note.bodyRTFData
        )
        context.insert(project)
        
        // Extract checklist lines as initial project tasks
        let lines = note.bodyText.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            var taskTitle = ""
            var isCompleted = false
            
            if trimmed.hasPrefix(RichTextTypography.checklistUncheckedGlyph) {
                taskTitle = String(trimmed.dropFirst(RichTextTypography.checklistUncheckedGlyph.count))
            } else if trimmed.hasPrefix(RichTextTypography.checklistCheckedGlyph) {
                taskTitle = String(trimmed.dropFirst(RichTextTypography.checklistCheckedGlyph.count))
                isCompleted = true
            } else if trimmed.hasPrefix("- [ ] ") {
                taskTitle = String(trimmed.dropFirst(6))
            } else if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
                taskTitle = String(trimmed.dropFirst(6))
                isCompleted = true
            }
            
            if !taskTitle.isEmpty {
                let task = TodoItem(
                    title: taskTitle,
                    parentID: nil,
                    projectID: project.id,
                    sectionID: nil,
                    noteRTFData: nil,
                    completedAt: isCompleted ? Date() : nil
                )
                context.insert(task)
            }
        }
        
        if archiveOriginal {
            note.isArchived = true
            note.updatedAt = Date()
        }
        
        try? context.save()
        Haptics.impact(.medium)
        return project
    }
    
    // MARK: - Bridge 2: BrainStorm Note -> Journal Entry
    
    @discardableResult
    func sendNoteToJournal(
        note: BrainStormNote,
        context: ModelContext,
        targetDate: Date = Date(),
        archiveOriginal: Bool = true
    ) -> JournalNote {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: targetDate)
        
        // Fetch or create daily journal entry for targetDate
        let fetchDescriptor = FetchDescriptor<JournalNote>(
            predicate: #Predicate { $0.date == startOfDay && $0.archivedAt == nil }
        )
        
        let existingNotes = (try? context.fetch(fetchDescriptor)) ?? []
        let journalNote: JournalNote
        
        if let existing = existingNotes.first {
            journalNote = existing
            let divider = journalNote.text.isEmpty ? "" : "\n\n---\n\n"
            let noteContent = "### \(note.title)\n\n\(note.bodyText)"
            journalNote.text += divider + noteContent
        } else {
            journalNote = JournalNote(
                date: targetDate,
                title: note.title,
                text: note.bodyText,
                kind: .dailyNote
            )
            context.insert(journalNote)
        }
        
        if archiveOriginal {
            note.isArchived = true
            note.updatedAt = Date()
        }
        
        try? context.save()
        Haptics.impact(.medium)
        return journalNote
    }
}
