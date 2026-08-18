import SwiftUI
import SwiftData

// MARK: - MacBrainStormView (3-Column Pure Apple Notes Surface)

struct MacBrainStormView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrainStormNote.updatedAt, order: .reverse) private var allNotes: [BrainStormNote]
    @Query private var allFolders: [BrainStormFolder]

    // Navigation & Selection States
    @State private var selectedSystemFolder: SystemFolderType? = .allNotes
    @State private var selectedFolderID: UUID? = nil
    @State private var selectedTag: String? = nil
    @State private var selectedNote: BrainStormNote? = nil

    // Column Visibility Control
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    // Modal & Toast States
    @State private var isShowingSettings: Bool = false
    @State private var isShowingShortcutsHUD: Bool = false
    @State private var deletedNoteForToast: BrainStormNote? = nil
    @State private var showDeleteToast: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                // 1. FOLDERS & TAGS SIDEBAR (Left Column)
                BrainStormFolderSidebar(
                    selectedSystemFolder: $selectedSystemFolder,
                    selectedFolderID: $selectedFolderID,
                    selectedTag: $selectedTag
                )
                .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 280)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            isShowingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 11))
                        }
                        .help("BrainStorm Preferences")
                    }

                    ToolbarItem(placement: .automatic) {
                        Button {
                            isShowingShortcutsHUD = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 11))
                        }
                        .help("Keyboard Shortcuts (⌘/)")
                        .keyboardShortcut("/", modifiers: .command)
                    }
                }
            } content: {
                // 2. NOTES LIST / GALLERY COLUMN (Middle Column)
                BrainStormNotesListColumn(
                    selectedSystemFolder: selectedSystemFolder,
                    selectedFolderID: selectedFolderID,
                    selectedTag: selectedTag,
                    selectedNote: $selectedNote
                )
                .navigationSplitViewColumnWidth(min: 240, ideal: 290, max: 380)
            } detail: {
                // 3. APPLE NOTES CANVAS EDITOR (Right Detail Column)
                if let note = selectedNote {
                    BrainStormEditorView(note: note)
                } else {
                    noNoteSelectedPlaceholder
                }
            }
            .navigationTitle("BrainStorm")

            // Floating Delete Restore Toast (6s auto-dismiss)
            if showDeleteToast, let deleted = deletedNoteForToast {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.7))

                    Text("Note moved to Recently Deleted")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white)

                    Spacer()

                    Button("Undo") {
                        deleted.deletedAt = nil
                        deleted.updatedAt = Date()
                        try? modelContext.save()
                        withAnimation {
                            showDeleteToast = false
                        }
                        Haptics.notify(.success)
                    }
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(width: 340)
                .background(Color.black.opacity(0.90).background(.ultraThinMaterial))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            BrainStormSettingsView(isPresented: $isShowingSettings)
        }
        .sheet(isPresented: $isShowingShortcutsHUD) {
            BrainStormShortcutCheatSheet(isPresented: $isShowingShortcutsHUD)
        }
        .onAppear {
            seedWelcomeNoteIfNeeded()
            if selectedNote == nil, let first = allNotes.first(where: { $0.isLive }) {
                selectedNote = first
            }
        }
    }

    // MARK: - Welcome Note Seeder (First Launch Only)

    private func seedWelcomeNoteIfNeeded() {
        let hasSeededKey = "brainstorm_has_seeded_welcome_note"
        guard !UserDefaults.standard.bool(forKey: hasSeededKey) else { return }

        if allNotes.isEmpty {
            let welcomeNote = BrainStormNote(
                title: "Welcome to BrainStorm 🧠",
                bodyText: """
                # Welcome to BrainStorm 🧠

                BrainStorm is your high-speed, local-first Apple Notes workspace designed for deep thinking, instant capture, and uninterrupted flow.

                ## Quick Start Guide
                - Press **⌘N** to create a new note anytime.
                - The first typed line automatically becomes your note title.
                - Type `#ideas` or `#project` anywhere to create tags automatically.

                ### Focus Checklist
                - [x] Launch BrainStorm on Mac
                - [ ] Try creating your first folder with **⌘⇧N**
                - [ ] Switch to Gallery View using the top-right grid button
                - [ ] Enter Zen Mode with **⌘⌃F** for distraction-free focus

                ---
                Enjoy your sovereign, offline note-taking sanctuary!
                """,
                isPinned: true,
                tags: ["welcome", "guide", "productivity"],
                hasChecklist: true
            )
            modelContext.insert(welcomeNote)
            try? modelContext.save()
            selectedNote = welcomeNote
        }
        UserDefaults.standard.set(true, forKey: hasSeededKey)
    }

    private var noNoteSelectedPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 40))
                .foregroundStyle(Color.white.opacity(0.15))

            Text("No Note Selected")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.4))

            Text("Choose a note from the list or press ⌘N to create a new one.")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.25))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: NSColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)))
    }
}
