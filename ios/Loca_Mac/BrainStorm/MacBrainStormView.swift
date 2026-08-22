import SwiftUI
import SwiftData

// MARK: - MacBrainStormView (Full Apple Notes Sovereign Experience)

struct MacBrainStormView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BrainStormNote.updatedAt, order: .reverse) private var allNotes: [BrainStormNote]
    @Query private var allFolders: [BrainStormFolder]

    // Navigation & Selection States
    @State private var selectedSystemFolder: SystemFolderType? = .allNotes
    @State private var selectedFolderID: UUID? = nil
    @State private var selectedTag: String? = nil
    @State private var selectedNoteID: UUID? = nil
    @State private var isZenMode: Bool = false
    @AppStorage("notes_show_notes_list") private var showNotesList: Bool = true

    // Modal & Toast States
    @State private var isShowingSettings: Bool = false
    @State private var isShowingShortcutsHUD: Bool = false
    @State private var isShowingFeatureTour: Bool = false
    @State private var deletedNoteForToast: BrainStormNote? = nil
    @State private var showDeleteToast: Bool = false
    
    private var selectedNote: BrainStormNote? {
        if let id = selectedNoteID {
            return allNotes.first { $0.id == id && $0.deletedAt == nil }
        }
        return allNotes.first { $0.deletedAt == nil }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Clean Native macOS Split View (Collapsible Notes List ↔ Large Full Note Canvas)
            HSplitView {

                // 1. NOTES LIST / GALLERY (Collapsible via burger button or ⌘\)
                if showNotesList && !isZenMode {
                    BrainStormNotesListColumn(
                        onToggleSidebar: {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                showNotesList.toggle()
                            }
                        },
                        selectedSystemFolder: selectedSystemFolder,
                        selectedFolderID: selectedFolderID,
                        selectedTag: selectedTag,
                        selectedNote: Binding(
                            get: { selectedNote },
                            set: { newNote in
                                selectedNoteID = newNote?.id
                            }
                        ),
                        onOpenTour: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                isShowingFeatureTour = true
                            }
                        }
                    )
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 440)
                    .background(Color(nsColor: NSColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)))
                }

                // 2. FULL APPLE NOTES CANVAS (Expands to 100% full width when list is closed)
                Group {
                    if let note = selectedNote {
                        BrainStormEditorView(
                            note: note,
                            isZenMode: $isZenMode,
                            onToggleSidebar: {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    showNotesList.toggle()
                                }
                            },
                            isSidebarVisible: showNotesList && !isZenMode,
                            onOpenTour: {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    isShowingFeatureTour = true
                                }
                            }
                        )
                    } else {
                        noNoteSelectedPlaceholder
                    }
                }
                .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: NSColor(red: 0.13, green: 0.13, blue: 0.14, alpha: 1.0)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 4. FLOATING INTERACTIVE FEATURE TOUR OVERLAY
            if isShowingFeatureTour {
                BrainStormFeatureTourOverlay(isPresented: $isShowingFeatureTour)
            }

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
        .onAppear {
            if selectedNoteID == nil, let first = allNotes.first(where: { $0.deletedAt == nil }) {
                selectedNoteID = first.id
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            BrainStormSettingsView(isPresented: $isShowingSettings)
        }
        .sheet(isPresented: $isShowingShortcutsHUD) {
            BrainStormShortcutCheatSheet(isPresented: $isShowingShortcutsHUD)
        }
    }

    // MARK: - Empty Selection Placeholder

    private var noNoteSelectedPlaceholder: some View {
        VStack(spacing: 14) {
            Image(systemName: "note.text")
                .font(.system(size: 44))
                .foregroundStyle(Color.white.opacity(0.15))

            Text("No Note Selected")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))

            Text("Choose a note from the list, or create a new note with ⌘N.")
                .font(.system(size: 12.5))
                .foregroundStyle(Color.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            Button {
                createNewNote()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("New Note")
                        .font(.system(size: 12.5, weight: .semibold))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func createNewNote() {
        let note = BrainStormNote(
            title: "New Note",
            bodyText: "",
            folderID: selectedFolderID
        )
        modelContext.insert(note)
        try? modelContext.save()
        selectedNoteID = note.id
        Haptics.impact(.light)
    }
}
