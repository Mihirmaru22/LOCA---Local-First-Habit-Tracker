import Foundation
import SwiftData
import SwiftUI

// MARK: - EmptyStateSeeder (First-Launch Guided Onboarding & Sample Data)

@MainActor
public final class EmptyStateSeeder {
    
    public static let shared = EmptyStateSeeder()
    private init() {}
    
    public func seedInitialDataIfNeeded(context: ModelContext) {
        let hasSeeded = UserDefaults.standard.bool(forKey: "has_seeded_initial_loca_workspace_v2")
        guard !hasSeeded else { return }
        
        // 1. Seed Welcome BrainStorm Note (With Real Formatted Content)
        seedWelcomeNote(context: context)
        
        // 2. Seed Sample Work Project
        seedSampleProject(context: context)
        
        UserDefaults.standard.set(true, forKey: "has_seeded_initial_loca_workspace_v2")
        try? context.save()
    }
    
    private func seedWelcomeNote(context: ModelContext) {
        let welcomeText = """
# Welcome to BrainStorm 🧠

This is your frictionless capture zone. Dump anything here: thoughts, meeting minutes, pasted project briefs, or voice transcripts.

## Quick Start
\(RichTextTypography.checklistCheckedGlyph)Experience true rich text formatting
\(RichTextTypography.checklistUncheckedGlyph)Try clicking this checklist box to toggle it
\(RichTextTypography.checklistUncheckedGlyph)Press ⌘B for **bold**, ⌘I for *italic*, ⌘U for underline
\(RichTextTypography.checklistUncheckedGlyph)Press ⌘⇧C on any line to toggle checklist mode

> "The external brain lets your mind relax and focus on creating rather than remembering."

### Inter-Pillar Flow
When you are ready to process this note:
- Click the **...** menu in the top toolbar.
- Choose **Create Project in Work** to convert this into a tracked project with tasks.
- Or choose **Send to Today's Journal** to log it in your daily reflection.
"""
        let welcomeAttr = RichTextTypography.convertMarkdownToAttributedString(markdown: welcomeText)
        let note = BrainStormNote(
            title: "Welcome to BrainStorm 🧠",
            bodyText: welcomeText,
            bodyRTFData: RichTextTypography.serializeToRTFD(attributedString: welcomeAttr),
            isPinned: true
        )
        context.insert(note)
    }
    
    private func seedSampleProject(context: ModelContext) {
        let briefText = """
# Project Goal & Overview

Build a focused, distraction-free environment to achieve peak productivity and calm consistency.

## Deliverables
- Clear task milestones
- Daily progress tracking
- Seamless reflection
"""
        let briefAttr = RichTextTypography.convertMarkdownToAttributedString(markdown: briefText)
        let project = WorkProject(
            title: "🚀 Launching My First Project",
            icon: "paperplane.fill",
            colorHex: "#8B5CF6",
            briefPlainText: briefText,
            briefRTFData: RichTextTypography.serializeToRTFD(attributedString: briefAttr),
            isPinned: true
        )
        context.insert(project)
        
        let sec1 = WorkSection(projectID: project.id, title: "Phase 1: Planning", sortOrder: 0)
        let sec2 = WorkSection(projectID: project.id, title: "Phase 2: Execution", sortOrder: 1)
        context.insert(sec1)
        context.insert(sec2)
        
        let t1 = TodoItem(title: "Define core project milestones", projectID: project.id, sectionID: sec1.id, completedAt: Date())
        let t2 = TodoItem(title: "Paste specification into project brief", projectID: project.id, sectionID: sec1.id, completedAt: Date())
        let t3 = TodoItem(title: "Check off your first task in execution", projectID: project.id, sectionID: sec2.id)
        
        context.insert(t1)
        context.insert(t2)
        context.insert(t3)
    }
}
