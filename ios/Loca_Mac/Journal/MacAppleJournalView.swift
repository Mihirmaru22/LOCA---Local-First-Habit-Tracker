import SwiftUI
import SwiftData
import AVFoundation

// MARK: - MacAppleJournalView (Apple Journal Native Canvas Clone)

/// 1:1 Apple Journal Experience for macOS with floating toolbar capsule,
/// typography popover, rich attachments, and side Audio Recording Studio.
struct MacAppleJournalView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\JournalNote.date, order: .reverse)])
    private var allNotes: [JournalNote]

    private var activeNotes: [JournalNote] {
        allNotes.filter { !$0.isArchived }
    }

    @State private var selectedNote: JournalNote? = nil
    @State private var isCreatingNew = false
    @State private var searchText = ""
    @State private var filterBookmarkedOnly = false

    var body: some View {
        HStack(spacing: 0) {
            // Left List: Past Journal Entries Stream
            VStack(spacing: 0) {
                // Header & Search
                VStack(spacing: 8) {
                    HStack {
                        Text("Journal Entries")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)

                        Spacer()

                        Button {
                            createNewEntry()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("New Entry")
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(red: 0.38, green: 0.45, blue: 0.98), in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }

                    // Search & Filter
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 11))
                                .foregroundStyle(DS.Color.textTertiary)
                            TextField("Search entries…", text: $searchText)
                                .font(.system(size: 11))
                                .textFieldStyle(.plain)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))

                        Button {
                            filterBookmarkedOnly.toggle()
                        } label: {
                            Image(systemName: filterBookmarkedOnly ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 12))
                                .foregroundStyle(filterBookmarkedOnly ? Color.yellow : DS.Color.textTertiary)
                                .padding(5)
                                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .help("Filter Bookmarked")
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                Divider()

                // Entries Stream
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredNotes) { note in
                            AppleJournalEntryCard(
                                note: note,
                                isSelected: selectedNote?.id == note.id,
                                onSelect: { selectedNote = note }
                            )
                        }
                    }
                    .padding(12)
                }
                .overlay {
                    if filteredNotes.isEmpty {
                        ContentUnavailableView {
                            Label("No Entries", systemImage: "book.pages")
                        } description: {
                            Text("Click + New Entry to write your first Apple Journal note.")
                        }
                    }
                }
            }
            .frame(width: 280)
            .background(DS.Color.surface)

            Divider()

            // Right Canvas: Apple Journal Editor
            if let note = selectedNote {
                AppleJournalEditorCanvas(
                    note: note,
                    onClose: {
                        selectedNote = nil
                    }
                )
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 38))
                        .foregroundStyle(DS.Color.textTertiary.opacity(0.6))
                    Text("Select a journal entry or click New Entry to start writing")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.08, green: 0.07, blue: 0.12))
            }
        }
        .onAppear {
            if selectedNote == nil, let first = activeNotes.first {
                selectedNote = first
            }
        }
    }

    private var filteredNotes: [JournalNote] {
        activeNotes.filter { note in
            let matchesSearch = searchText.isEmpty || note.title.localizedCaseInsensitiveContains(searchText) || note.text.localizedCaseInsensitiveContains(searchText)
            let matchesBookmark = !filterBookmarkedOnly || note.isBookmarked
            return matchesSearch && matchesBookmark
        }
    }

    private func createNewEntry() {
        let newNote = JournalNote(
            date: Date(),
            title: "",
            text: "",
            kind: .dailyNote
        )
        modelContext.insert(newNote)
        try? modelContext.save()
        selectedNote = newNote
        Haptics.impact(.rigid)
    }
}

// MARK: - AppleJournalEntryCard

private struct AppleJournalEntryCard: View {
    let note: JournalNote
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, d MMM"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(Self.dayFormatter.string(from: note.date))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(red: 0.68, green: 0.45, blue: 0.98))

                Spacer()

                if note.hasAudio {
                    Image(systemName: "waveform")
                        .font(.system(size: 10))
                        .foregroundStyle(.pink)
                }

                if note.isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                }
            }

            Text(note.title.isEmpty ? (note.text.isEmpty ? "Untitled Entry" : note.text) : note.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(DS.Color.textPrimary)
                .lineLimit(1)

            if !note.text.isEmpty {
                Text(note.text)
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Color.textSecondary)
                    .lineLimit(2)
            }

            if let loc = note.location {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 8))
                    Text(loc)
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(DS.Color.textTertiary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isSelected
                ? Color(red: 0.38, green: 0.45, blue: 0.98).opacity(0.18)
                : (isHovered ? DS.Color.surfaceRecessed : DS.Color.surfaceRecessed.opacity(0.5)),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color(red: 0.38, green: 0.45, blue: 0.98).opacity(0.6) : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .onHover { isHovered = $0 }
    }
}

// MARK: - AppleJournalEditorCanvas

private struct AppleJournalEditorCanvas: View {
    @Bindable var note: JournalNote
    let onClose: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var showAudioDrawer = false
    @State private var showFormattingPopover = false
    @State private var showPhotoPicker = false
    @State private var isRecording = false
    @State private var recordTime: Double = 0
    @State private var timer: Timer? = nil

    private static let headerDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, d MMM 'at' h:mm a"
        return f
    }()

    var body: some View {
        HStack(spacing: 0) {
            // Main Journal Sheet
            VStack(spacing: 0) {

                // Top Floating Apple Journal Navigation & Tool Bar
                HStack(spacing: 12) {
                    // Back Button
                    Button {
                        saveNote()
                        onClose()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(DS.Color.textSecondary)
                            .padding(6)
                            .background(DS.Color.surfaceRecessed, in: Circle())
                    }
                    .buttonStyle(.plain)

                    // Header Timestamp
                    Text(Self.headerDateFormatter.string(from: note.date))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Spacer()

                    // Center Floating Capsule Toolbar (Matching Apple Journal Screenshot 2)
                    HStack(spacing: 4) {
                        toolbarCapsuleItem(icon: "text.alignleft", label: "Text", isActive: true) {}
                        toolbarCapsuleItem(icon: "photo", label: "Photos", isActive: note.photoCount > 0) {
                            note.photoCount += 1
                            saveNote()
                            Haptics.impact(.light)
                        }
                        toolbarCapsuleItem(icon: "camera", label: "Camera", isActive: false) {
                            note.photoCount += 1
                            saveNote()
                            Haptics.impact(.light)
                        }
                        toolbarCapsuleItem(icon: "location.north.line.fill", label: "Location", isActive: note.location != nil) {
                            if note.location == nil {
                                note.location = "San Francisco, CA"
                            } else {
                                note.location = nil
                            }
                            saveNote()
                            Haptics.impact(.light)
                        }
                        toolbarCapsuleItem(icon: "waveform", label: "Audio", isActive: showAudioDrawer || note.hasAudio) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                showAudioDrawer.toggle()
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.16, green: 0.15, blue: 0.22), in: Capsule())
                    .overlay(Capsule().stroke(DS.Color.border.opacity(0.3), lineWidth: 1))

                    Spacer()

                    // Right Actions (Aa Typography + Bookmark + Done Button)
                    HStack(spacing: 8) {
                        // Typography Aa Popover Button (Screenshot 3)
                        Button {
                            showFormattingPopover.toggle()
                        } label: {
                            HStack(spacing: 2) {
                                Text("Aa").font(.system(size: 13, weight: .bold))
                                Image(systemName: "pencil.and.outline").font(.system(size: 10))
                            }
                            .foregroundStyle(DS.Color.textPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(red: 0.16, green: 0.15, blue: 0.22), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showFormattingPopover) {
                            AppleJournalTypographyPopover()
                        }

                        // Bookmark Flag
                        Button {
                            note.isBookmarked.toggle()
                            saveNote()
                            Haptics.impact(.light)
                        } label: {
                            Image(systemName: note.isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 13))
                                .foregroundStyle(note.isBookmarked ? Color.yellow : DS.Color.textSecondary)
                                .padding(7)
                                .background(Color(red: 0.16, green: 0.15, blue: 0.22), in: Circle())
                        }
                        .buttonStyle(.plain)

                        // Blue Done Checkmark Button
                        Button {
                            saveNote()
                            Haptics.impact(.rigid)
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Color(red: 0.38, green: 0.45, blue: 0.98), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .help("Save Journal Entry")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(red: 0.10, green: 0.09, blue: 0.14))

                Divider()

                // Editor Content Body
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {

                        // Attached Location Pill
                        if let loc = note.location {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color(red: 0.38, green: 0.45, blue: 0.98))
                                Text(loc)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(DS.Color.textSecondary)

                                Spacer()

                                Button {
                                    note.location = nil
                                    saveNote()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9))
                                        .foregroundStyle(DS.Color.textTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.16, green: 0.15, blue: 0.22), in: RoundedRectangle(cornerRadius: 6))
                        }

                        // Title Field
                        TextField("Title", text: $note.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)
                            .textFieldStyle(.plain)
                            .onChange(of: note.title) { _, _ in saveNote() }

                        // Body Multiline Note
                        TextEditor(text: $note.text)
                            .font(.system(size: 15))
                            .lineSpacing(6)
                            .foregroundStyle(DS.Color.textPrimary)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(minHeight: 380)
                            .onChange(of: note.text) { _, _ in saveNote() }

                        // Photo Attachment Mockup
                        if note.photoCount > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ATTACHED PHOTOS (\(note.photoCount))")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(DS.Color.textTertiary)

                                HStack(spacing: 10) {
                                    ForEach(0..<note.photoCount, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color(red: 0.38, green: 0.45, blue: 0.98), Color(red: 0.68, green: 0.45, blue: 0.98)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 90, height: 90)
                                            .overlay(
                                                Image(systemName: "photo.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(.white.opacity(0.8))
                                            )
                                    }
                                }
                            }
                            .padding(.top, 10)
                        }

                        // Audio Attachment Card
                        if note.hasAudio {
                            HStack(spacing: 12) {
                                Image(systemName: "waveform.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(Color(red: 0.38, green: 0.45, blue: 0.98))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Voice Memo")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(DS.Color.textPrimary)
                                    Text("00:42 • High Fidelity Audio")
                                        .font(.system(size: 10))
                                        .foregroundStyle(DS.Color.textSecondary)
                                }

                                Spacer()

                                Button {
                                    showAudioDrawer = true
                                } label: {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(12)
                            .background(Color(red: 0.16, green: 0.15, blue: 0.22), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.09, green: 0.08, blue: 0.13))

            // Right Audio Recording Studio Drawer (Screenshot 4)
            if showAudioDrawer {
                Divider()

                VStack(spacing: 20) {
                    // Drawer Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Audio Recording")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)
                            Text("Live Session")
                                .font(.system(size: 10))
                                .foregroundStyle(DS.Color.textTertiary)
                        }

                        Spacer()

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showAudioDrawer = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    Spacer()

                    // Waveform Scrub Track with Red Playhead (Matching Screenshot 4)
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.18, green: 0.17, blue: 0.25))
                            .frame(width: 140, height: 260)

                        // Vertical Audio Playhead Needle
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 2, height: 260)
                            .overlay(
                                Circle().fill(Color.red).frame(width: 8, height: 8),
                                alignment: .top
                            )
                    }

                    // Digital Timer (00:00.00)
                    Text(formatRecordTime(recordTime))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(DS.Color.textPrimary)

                    // Skip & Playback Controls (-15s, Play/Pause, +15s)
                    HStack(spacing: 28) {
                        Button {
                            if recordTime > 15 { recordTime -= 15 }
                        } label: {
                            Image(systemName: "gobackward.15")
                                .font(.system(size: 16))
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            toggleRecording()
                        } label: {
                            Image(systemName: isRecording ? "pause.fill" : "play.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(DS.Color.textPrimary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            recordTime += 15
                        } label: {
                            Image(systemName: "goforward.15")
                                .font(.system(size: 16))
                                .foregroundStyle(DS.Color.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    // Bottom Bar (Transcript, Record Button, Checkmark Done)
                    HStack(spacing: 20) {
                        Button {
                            Haptics.impact(.light)
                        } label: {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 14))
                                .foregroundStyle(DS.Color.textSecondary)
                                .padding(8)
                                .background(Color(red: 0.18, green: 0.17, blue: 0.25), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .help("Transcribe Audio")

                        // Big Red Record / Stop Button
                        Button {
                            toggleRecording()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.95, green: 0.35, blue: 0.45))
                                    .frame(width: 38, height: 38)
                                if isRecording {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.white)
                                        .frame(width: 14, height: 14)
                                } else {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 16, height: 16)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        // Save / Attach Audio Checkmark
                        Button {
                            note.hasAudio = true
                            note.audioDuration = recordTime
                            saveNote()
                            withAnimation { showAudioDrawer = false }
                            Haptics.impact(.rigid)
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(DS.Color.textSecondary)
                                .padding(8)
                                .background(Color(red: 0.18, green: 0.17, blue: 0.25), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .help("Attach to Journal Note")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .frame(width: 220)
                .background(Color(red: 0.12, green: 0.11, blue: 0.17))
            }
        }
    }

    private func toolbarCapsuleItem(icon: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: isActive ? .bold : .medium))
                .foregroundStyle(isActive ? Color.white : DS.Color.textSecondary)
                .frame(width: 28, height: 26)
                .background(isActive ? Color.white.opacity(0.18) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help(label)
    }

    private func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                recordTime += 0.1
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
        Haptics.impact(.medium)
    }

    private func formatRecordTime(_ sec: Double) -> String {
        let mins = Int(sec) / 60
        let s = Int(sec) % 60
        let ms = Int((sec.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", mins, s, ms)
    }

    private func saveNote() {
        try? modelContext.save()
    }
}

// MARK: - AppleJournalTypographyPopover (Screenshot 3 Matching)

private struct AppleJournalTypographyPopover: View {
    @State private var isBold = false
    @State private var isItalic = false
    @State private var isUnderline = false
    @State private var isStrikethrough = false

    var body: some View {
        VStack(spacing: 8) {
            // Row 1: B, I, U, S (Matching Screenshot 3)
            HStack(spacing: 2) {
                formatBtn("B", isActive: isBold) { isBold.toggle() }
                formatBtn("I", isActive: isItalic) { isItalic.toggle() }
                formatBtn("U", isActive: isUnderline) { isUnderline.toggle() }
                formatBtn("S", isActive: isStrikethrough) { isStrikethrough.toggle() }
            }
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))

            // Row 2: List Formats (Bullets, Checklist, Numbered, Blockquote, Toggle)
            HStack(spacing: 2) {
                formatIconBtn("list.bullet") {}
                formatIconBtn("checklist") {}
                formatIconBtn("list.number") {}
                formatIconBtn("quote.opening") {}
                formatIconBtn("switch.2") {}
            }
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(8)
        .background(Color(red: 0.16, green: 0.15, blue: 0.22))
    }

    private func formatBtn(_ text: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 12, weight: text == "B" ? .bold : (text == "I" ? .medium : .regular)))
                .italic(text == "I")
                .underline(text == "U")
                .strikethrough(text == "S")
                .foregroundStyle(isActive ? Color.white : DS.Color.textSecondary)
                .frame(width: 36, height: 26)
                .background(isActive ? Color.white.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }

    private func formatIconBtn(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(DS.Color.textSecondary)
                .frame(width: 28, height: 26)
        }
        .buttonStyle(.plain)
    }
}
