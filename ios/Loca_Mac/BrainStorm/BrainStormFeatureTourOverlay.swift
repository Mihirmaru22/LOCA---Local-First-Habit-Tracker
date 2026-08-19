import SwiftUI

// MARK: - StudioFeatureTourStep

enum StudioFeatureTourStep: Int, CaseIterable, Identifiable {
    case foldersAndTags       = 0
    case noteListAndPreviews  = 1
    case typographyStudio     = 2
    case interactiveChecklist = 3
    case structuredTables     = 4
    case mediaAttachments     = 5
    case universalLinks       = 6
    case privacyAndExport     = 7

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .foldersAndTags:       return "Taxonomy & Folders"
        case .noteListAndPreviews:  return "Notes Engine & Previews"
        case .typographyStudio:     return "Rich Typography (Aa)"
        case .interactiveChecklist: return "Interactive Checklists"
        case .structuredTables:     return "Structured Tables"
        case .mediaAttachments:     return "Media & Attachments"
        case .universalLinks:       return "Deep Linking & Bridges"
        case .privacyAndExport:     return "Privacy, Lock & Export"
        }
    }

    var icon: String {
        switch self {
        case .foldersAndTags:       return "folder.badge.gearshape"
        case .noteListAndPreviews:  return "doc.text.magnifyingglass"
        case .typographyStudio:     return "textformat.size"
        case .interactiveChecklist: return "checklist.checked"
        case .structuredTables:     return "tablecells.badge.ellipsis"
        case .mediaAttachments:     return "paperclip.badge.ellipsis"
        case .universalLinks:       return "link.badge.plus"
        case .privacyAndExport:     return "lock.shield.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .foldersAndTags:       return Color(red: 0.95, green: 0.65, blue: 0.25)
        case .noteListAndPreviews:  return Color(red: 0.25, green: 0.75, blue: 0.95)
        case .typographyStudio:     return Color(red: 0.95, green: 0.75, blue: 0.25)
        case .interactiveChecklist: return Color(red: 0.25, green: 0.85, blue: 0.55)
        case .structuredTables:     return Color(red: 0.75, green: 0.45, blue: 0.95)
        case .mediaAttachments:     return Color(red: 0.95, green: 0.45, blue: 0.65)
        case .universalLinks:       return Color(red: 0.35, green: 0.65, blue: 0.95)
        case .privacyAndExport:     return Color(red: 0.95, green: 0.55, blue: 0.25)
        }
    }

    var detailedSummary: String {
        switch self {
        case .foldersAndTags:
            return "Organize all your thinking across System Folders (All Notes, Quick Notes, Favorites, Locked, and Recently Deleted) or create custom folders. Every `#tag` typed inside your notes is automatically indexed for instant taxonomic filtering."
        case .noteListAndPreviews:
            return "The notes column gives you generous multi-line previews of your actual note contents so you can scan ideas at a glance. Toggle between compact List and Gallery view, sort by Date Edited, Created, or Title, and fuzzy-search across all notes in real time."
        case .typographyStudio:
            return "A full-scale native typography engine. Switch between Title, Heading, Subheading, Body, Monostyle code blocks, Block Quotes, Bulleted, Dashed, and Numbered lists. Apply Bold (⌘B), Italic (⌘I), Underline (⌘U), Strikethrough, and Highlighter marks."
        case .interactiveChecklist:
            return "Turn any line into an interactive todo checkbox with one click or ⌘⇧C. Checkboxes seamlessly toggle state and update the note's checklist telemetry icon in your sidebar list."
        case .structuredTables:
            return "Insert formatted data tables (⊞) with custom columns and rows. Perfect for tracking project requirements, comparison matrixes, financial tallies, and structured specifications."
        case .mediaAttachments:
            return "Embed photos, video references, and arbitrary document attachments directly into your note canvas. All files are securely referenced and stored with local-first persistence."
        case .universalLinks:
            return "Hyperlink external websites (⌘K) or utilize LOCA's Inter-Pillar Bridges in the (...) menu to instantly turn notes into actionable Work Projects or Daily Journal entries."
        case .privacyAndExport:
            return "Lock sensitive notes with vault security, pin critical notes to the top (📌), and export cleanly to PDF, Markdown (.md), or Plain Text (.txt) with zero cloud lock-in."
        }
    }

    var shortcutHint: String? {
        switch self {
        case .foldersAndTags:       return "Toggle Folders: Click ◨"
        case .noteListAndPreviews:  return "New Note: ⌘N · Search: ⌘F"
        case .typographyStudio:     return "Format: ⌘B / ⌘I / ⌘U"
        case .interactiveChecklist: return "Checklist: ⌘⇧C"
        case .structuredTables:     return "Insert Table: Click ⊞"
        case .mediaAttachments:     return "Attach: Click 📎"
        case .universalLinks:       return "Add Link: ⌘K"
        case .privacyAndExport:     return "Zen View: ⌘⌃F"
        }
    }
}

// MARK: - BrainStormFeatureTourOverlay

struct BrainStormFeatureTourOverlay: View {
    @Binding var isPresented: Bool
    @State private var currentStep: StudioFeatureTourStep = .foldersAndTags

    var body: some View {
        ZStack {
            // Subtle darkened backdrop
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPresented = false
                    }
                }

            // Floating Interactive Spotlight Card
            VStack(alignment: .leading, spacing: 14) {

                // Top Header Row
                HStack(alignment: .center, spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(currentStep.accentColor.opacity(0.18))
                            .frame(width: 36, height: 36)
                        Image(systemName: currentStep.icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(currentStep.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("STUDIO FEATURE TOUR · \(currentStep.rawValue + 1) OF \(StudioFeatureTourStep.allCases.count)")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(currentStep.accentColor)

                        Text(currentStep.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.white)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                }

                Divider().opacity(0.15)

                // Detailed In-Depth Description
                Text(currentStep.detailedSummary)
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                // Keyboard Shortcut & Telemetry Pill
                if let hint = currentStep.shortcutHint {
                    HStack(spacing: 6) {
                        Image(systemName: "command")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(currentStep.accentColor)

                        Text(hint)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.75))

                        Spacer()

                        Text("Real-Time Native Engine")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.40))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }

                Divider().opacity(0.15)

                // Bottom Action Bar: Step Dots, Prev, Next
                HStack(alignment: .center) {
                    
                    // Step Dots
                    HStack(spacing: 5) {
                        ForEach(StudioFeatureTourStep.allCases) { step in
                            Circle()
                                .fill(step == currentStep ? currentStep.accentColor : Color.white.opacity(0.20))
                                .frame(width: step == currentStep ? 8 : 5, height: step == currentStep ? 8 : 5)
                                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: currentStep)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        currentStep = step
                                    }
                                }
                        }
                    }

                    Spacer()

                    // Previous Button
                    if currentStep.rawValue > 0 {
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                if let prev = StudioFeatureTourStep(rawValue: currentStep.rawValue - 1) {
                                    currentStep = prev
                                }
                            }
                            Haptics.impact(.light)
                        } label: {
                            Text("← Back")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.75))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(PlutoFastButtonStyle())
                    }

                    // Next / Finish Button
                    Button {
                        if currentStep.rawValue < StudioFeatureTourStep.allCases.count - 1 {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                if let next = StudioFeatureTourStep(rawValue: currentStep.rawValue + 1) {
                                    currentStep = next
                                }
                            }
                            Haptics.impact(.light)
                        } else {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isPresented = false
                            }
                            Haptics.notify(.success)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(currentStep.rawValue < StudioFeatureTourStep.allCases.count - 1 ? "Next Feature →" : "Done Exploring ✦")
                                .font(.system(size: 12, weight: .bold))
                            if currentStep.rawValue == StudioFeatureTourStep.allCases.count - 1 {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                            }
                        }
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(currentStep.accentColor, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(PlutoFastButtonStyle())
                }
            }
            .padding(18)
            .frame(width: 440)
            .background(
                Color(nsColor: NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 0.98)),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(currentStep.accentColor.opacity(0.40), lineWidth: 1.2)
            )
            .shadow(color: Color.black.opacity(0.60), radius: 24, x: 0, y: 12)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
    }
}
