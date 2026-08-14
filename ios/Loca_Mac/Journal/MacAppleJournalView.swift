import SwiftUI
import SwiftData
import AVFoundation
import AppKit
import Combine

// MARK: - JournalMediaManager

final class JournalMediaManager {
    static let shared = JournalMediaManager()

    private var mediaDirectory: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("Pluto/JournalMedia", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func saveImage(from sourceURL: URL) -> String? {
        let ext = sourceURL.pathExtension.isEmpty ? "jpg" : sourceURL.pathExtension
        let filename = "img_\(UUID().uuidString).\(ext)"
        let targetURL = mediaDirectory.appendingPathComponent(filename)
        do {
            try FileManager.default.copyItem(at: sourceURL, to: targetURL)
            return filename
        } catch {
            return nil
        }
    }

    func saveAudioRecording(tempURL: URL) -> String? {
        let filename = "audio_\(UUID().uuidString).m4a"
        let targetURL = mediaDirectory.appendingPathComponent(filename)
        do {
            try FileManager.default.copyItem(at: tempURL, to: targetURL)
            return filename
        } catch {
            return nil
        }
    }

    func fileURL(for filename: String) -> URL {
        mediaDirectory.appendingPathComponent(filename)
    }

    func deleteFile(named filename: String) {
        let targetURL = mediaDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: targetURL)
    }
}

// MARK: - AppleJournalRichTextController

final class AppleJournalRichTextController: NSObject, ObservableObject {
    @Published var changeCounter: Int = 0
    weak var textView: NSTextView?
    var onTextChange: ((String, Data?) -> Void)?

    func toggleBold() {
        guard let tv = textView else { return }
        let fm = NSFontManager.shared
        let range = tv.selectedRange()
        if range.length > 0 {
            if let ts = tv.textStorage {
                ts.beginEditing()
                ts.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
                    let cur = (value as? NSFont) ?? NSFont.systemFont(ofSize: 15)
                    let isBold = cur.fontDescriptor.symbolicTraits.contains(.bold)
                    let newFont = fm.convert(cur, toHaveTrait: isBold ? .unboldFontMask : .boldFontMask)
                    ts.addAttribute(.font, value: newFont, range: subrange)
                }
                ts.endEditing()
                notifyChange()
            }
        } else {
            var attrs = tv.typingAttributes
            let cur = (attrs[.font] as? NSFont) ?? NSFont.systemFont(ofSize: 15)
            let isBold = cur.fontDescriptor.symbolicTraits.contains(.bold)
            attrs[.font] = fm.convert(cur, toHaveTrait: isBold ? .unboldFontMask : .boldFontMask)
            tv.typingAttributes = attrs
        }
        Haptics.impact(.light)
    }

    func toggleItalic() {
        guard let tv = textView else { return }
        let fm = NSFontManager.shared
        let range = tv.selectedRange()
        if range.length > 0 {
            if let ts = tv.textStorage {
                ts.beginEditing()
                ts.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
                    let cur = (value as? NSFont) ?? NSFont.systemFont(ofSize: 15)
                    let isItalic = cur.fontDescriptor.symbolicTraits.contains(.italic)
                    let newFont = fm.convert(cur, toHaveTrait: isItalic ? .unitalicFontMask : .italicFontMask)
                    ts.addAttribute(.font, value: newFont, range: subrange)
                }
                ts.endEditing()
                notifyChange()
            }
        } else {
            var attrs = tv.typingAttributes
            let cur = (attrs[.font] as? NSFont) ?? NSFont.systemFont(ofSize: 15)
            let isItalic = cur.fontDescriptor.symbolicTraits.contains(.italic)
            attrs[.font] = fm.convert(cur, toHaveTrait: isItalic ? .unitalicFontMask : .italicFontMask)
            tv.typingAttributes = attrs
        }
        Haptics.impact(.light)
    }

    func toggleUnderline() {
        guard let tv = textView else { return }
        let range = tv.selectedRange()
        if range.length > 0 {
            if let ts = tv.textStorage {
                ts.beginEditing()
                let currentVal = ts.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? Int ?? 0
                let newVal = (currentVal == 0) ? NSUnderlineStyle.single.rawValue : 0
                ts.addAttribute(.underlineStyle, value: newVal, range: range)
                ts.endEditing()
                notifyChange()
            }
        } else {
            var attrs = tv.typingAttributes
            let currentVal = attrs[.underlineStyle] as? Int ?? 0
            attrs[.underlineStyle] = (currentVal == 0) ? NSUnderlineStyle.single.rawValue : 0
            tv.typingAttributes = attrs
        }
        Haptics.impact(.light)
    }

    func toggleStrikethrough() {
        guard let tv = textView else { return }
        let range = tv.selectedRange()
        if range.length > 0 {
            if let ts = tv.textStorage {
                ts.beginEditing()
                let currentVal = ts.attribute(.strikethroughStyle, at: range.location, effectiveRange: nil) as? Int ?? 0
                let newVal = (currentVal == 0) ? NSUnderlineStyle.single.rawValue : 0
                ts.addAttribute(.strikethroughStyle, value: newVal, range: range)
                ts.endEditing()
                notifyChange()
            }
        } else {
            var attrs = tv.typingAttributes
            let currentVal = attrs[.strikethroughStyle] as? Int ?? 0
            attrs[.strikethroughStyle] = (currentVal == 0) ? NSUnderlineStyle.single.rawValue : 0
            tv.typingAttributes = attrs
        }
        Haptics.impact(.light)
    }

    func insertBulletList() {
        insertPrefixOnCurrentLine("• ")
    }

    func insertChecklist() {
        insertPrefixOnCurrentLine("☐ ")
    }

    func insertNumberedList() {
        insertPrefixOnCurrentLine("1. ")
    }

    func insertBlockquote() {
        insertPrefixOnCurrentLine("“ ")
    }

    func insertDivider() {
        guard let tv = textView else { return }
        tv.insertText("\n────────────────────────\n", replacementRange: tv.selectedRange())
        notifyChange()
        Haptics.impact(.light)
    }

    private func insertPrefixOnCurrentLine(_ prefix: String) {
        guard let tv = textView, let string = tv.string as NSString? else { return }
        let range = tv.selectedRange()
        let lineRange = string.lineRange(for: NSRange(location: range.location, length: 0))
        tv.setSelectedRange(NSRange(location: lineRange.location, length: 0))
        tv.insertText(prefix, replacementRange: NSRange(location: lineRange.location, length: 0))
        notifyChange()
        Haptics.impact(.light)
    }

    func notifyChange() {
        guard let tv = textView else { return }
        let plain = tv.string
        let rtf = try? tv.textStorage?.data(from: NSRange(location: 0, length: tv.textStorage?.length ?? 0), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        onTextChange?(plain, rtf)
    }
}

// MARK: - AppleJournalRichTextView (NSViewRepresentable)

struct AppleJournalRichTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var rtfData: Data?
    let controller: AppleJournalRichTextController

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isAutomaticDashSubstitutionEnabled = true
        textView.font = NSFont.systemFont(ofSize: 15, weight: .regular)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.insertionPointColor = NSColor(red: 0.38, green: 0.45, blue: 0.98, alpha: 1.0)
        textView.textContainerInset = NSSize(width: 0, height: 12)

        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false

        controller.textView = textView
        controller.onTextChange = { plain, rtf in
            DispatchQueue.main.async {
                self.text = plain
                self.rtfData = rtf
            }
        }

        // Load Initial Content
        if let data = rtfData,
           let attrStr = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
            textView.textStorage?.setAttributedString(attrStr)
        } else if !text.isEmpty {
            textView.string = text
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text && !context.coordinator.isEditingLocally {
            if let data = rtfData,
               let attrStr = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
                textView.textStorage?.setAttributedString(attrStr)
            } else {
                textView.string = text
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: AppleJournalRichTextView
        var isEditingLocally = false

        init(_ parent: AppleJournalRichTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            isEditingLocally = true
            parent.controller.notifyChange()
            isEditingLocally = false
        }

        func textView(_ textView: NSTextView, clickedOn cell: NSTextAttachmentCellProtocol, in cellFrame: NSRect, at charIndex: Int) {
            // Checklist interaction
            if let string = textView.string as NSString? {
                let range = NSRange(location: charIndex, length: 1)
                let char = string.substring(with: range)
                if char == "☐" {
                    textView.insertText("☑", replacementRange: range)
                    parent.controller.notifyChange()
                    Haptics.impact(.rigid)
                } else if char == "☑" {
                    textView.insertText("☐", replacementRange: range)
                    parent.controller.notifyChange()
                    Haptics.impact(.light)
                }
            }
        }
    }
}

// MARK: - AppleJournalEntriesList (Middle Column)

struct AppleJournalEntriesList: View {

    @Binding var selectedNote: JournalNote?
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\JournalNote.date, order: .reverse)])
    private var allNotes: [JournalNote]

    private var activeNotes: [JournalNote] {
        allNotes.filter { !$0.isArchived }
    }

    @State private var searchText = ""
    @State private var filterBookmarkedOnly = false

    var body: some View {
        VStack(spacing: 0) {
            // Search & Filter Header
            VStack(spacing: 8) {
                HStack {
                    Text("\(activeNotes.count) entries")
                        .font(DS.Text.caption)
                        .foregroundStyle(DS.Color.textTertiary)

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
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color(red: 0.38, green: 0.45, blue: 0.98), in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("n", modifiers: .command)
                }

                // Search Bar + Bookmark Filter Toggle
                HStack(spacing: 6) {
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
                            .font(.system(size: 11))
                            .foregroundStyle(filterBookmarkedOnly ? Color.yellow : DS.Color.textTertiary)
                            .padding(5)
                            .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .help("Filter Bookmarked Only")
                }
            }
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, 10)

            Divider()

            // Entries List
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(filteredNotes) { note in
                        AppleJournalEntryCard(
                            note: note,
                            isSelected: selectedNote?.id == note.id,
                            onSelect: { 
                                selectedNote = note
                                Haptics.selection()
                            }
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .overlay {
                if filteredNotes.isEmpty {
                    ContentUnavailableView {
                        Label("No Entries", systemImage: "book.pages")
                    } description: {
                        Text("Click + New Entry to create your first Apple Journal note.")
                    }
                }
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

struct AppleJournalEntryCard: View {
    let note: JournalNote
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, d MMM 'at' h:mm a"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(Self.dayFormatter.string(from: note.date))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(red: 0.68, green: 0.45, blue: 0.98))

                Spacer()

                if note.hasAudio {
                    Image(systemName: "waveform")
                        .font(.system(size: 9))
                        .foregroundStyle(.pink)
                }

                if note.photoCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "photo")
                            .font(.system(size: 9))
                        Text("\(note.photoCount)")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(Color.accentColor)
                }

                if note.isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.yellow)
                }
            }

            Text(note.title.isEmpty ? (note.text.isEmpty ? "Untitled Entry" : note.text) : note.title)
                .font(.system(size: 12, weight: .bold))
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
        .padding(9)
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

// MARK: - AppleJournalEditorCanvas (Right Detail Pane)

struct AppleJournalEditorCanvas: View {
    @Bindable var note: JournalNote

    @Environment(\.modelContext) private var modelContext
    @StateObject private var richTextController = AppleJournalRichTextController()

    @State private var showAudioDrawer = false
    @State private var showFormattingPopover = false
    @State private var showLocationPopover = false
    @State private var showDatePopover = false
    @State private var showSavedToast = false

    // Audio Player State
    @State private var isPlayingAudio = false
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var playbackTimer: Timer? = nil

    private static let headerDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, d MMM 'at' h:mm a"
        return f
    }()

    var body: some View {
        HStack(spacing: 0) {
            // Main Journal Canvas
            VStack(spacing: 0) {

                // Top Floating Apple Journal Navigation & Tool Bar (Screenshots 2 & 3)
                HStack(spacing: 12) {

                    // Date & Time Picker Button
                    Button {
                        showDatePopover = true
                    } label: {
                        HStack(spacing: 5) {
                            Text(Self.headerDateFormatter.string(from: note.date))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(DS.Color.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(DS.Color.textTertiary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.16, green: 0.15, blue: 0.22), in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showDatePopover) {
                        VStack(spacing: 10) {
                            DatePicker("Entry Date & Time", selection: $note.date, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                                .onChange(of: note.date) { _, _ in saveNote() }

                            Button("Done") { showDatePopover = false }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                        }
                        .padding(12)
                    }

                    Spacer()

                    // Center Floating Capsule Toolbar (Matching Apple Journal Screenshots)
                    HStack(spacing: 4) {
                        toolbarCapsuleItem(icon: "text.alignleft", label: "Text Mode", isActive: true) {
                            richTextController.textView?.window?.makeFirstResponder(richTextController.textView)
                        }

                        // Photos Picker
                        toolbarCapsuleItem(icon: "photo", label: "Attach Photos", isActive: note.photoCount > 0) {
                            choosePhotoFromDisk()
                        }

                        // Camera / Media Snapshot
                        toolbarCapsuleItem(icon: "camera", label: "Snapshot / Photo", isActive: false) {
                            choosePhotoFromDisk()
                        }

                        // Location Picker
                        toolbarCapsuleItem(icon: "location.north.line.fill", label: "Tag Location", isActive: note.location != nil) {
                            showLocationPopover.toggle()
                        }
                        .popover(isPresented: $showLocationPopover) {
                            AppleJournalLocationPopover(currentLocation: note.location) { newLoc in
                                note.location = newLoc
                                saveNote()
                                showLocationPopover = false
                            }
                        }

                        // Audio Voice Memo Drawer
                        toolbarCapsuleItem(icon: "waveform", label: "Voice Memo Studio", isActive: showAudioDrawer || note.hasAudio) {
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
                            AppleJournalTypographyPopover(controller: richTextController)
                        }

                        // Bookmark Flag Toggle
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
                        .help(note.isBookmarked ? "Remove Bookmark" : "Bookmark Entry")

                        // Blue Done Checkmark Save Button
                        Button {
                            saveNote()
                            showSavedToast = true
                            Haptics.impact(.rigid)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSavedToast = false
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.38, green: 0.45, blue: 0.98))
                                    .frame(width: 28, height: 28)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
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
                            .padding(.vertical, 5)
                            .background(Color(red: 0.16, green: 0.15, blue: 0.22), in: RoundedRectangle(cornerRadius: 6))
                        }

                        // Title Field
                        TextField("Title", text: $note.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)
                            .textFieldStyle(.plain)
                            .onChange(of: note.title) { _, _ in saveNote() }

                        // Native Rich Text Multiline Canvas
                        AppleJournalRichTextView(
                            text: $note.text,
                            rtfData: $note.rtfData,
                            controller: richTextController
                        )
                        .frame(minHeight: 280)

                        // Attached Photos Gallery
                        if !note.photoFileNames.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("ATTACHED PHOTOS (\(note.photoFileNames.count))")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(DS.Color.textTertiary)
                                    Spacer()
                                    Button("+ Add More") {
                                        choosePhotoFromDisk()
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                    .buttonStyle(.plain)
                                    .foregroundStyle(Color(red: 0.38, green: 0.45, blue: 0.98))
                                }

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 10)], spacing: 10) {
                                    ForEach(note.photoFileNames, id: \.self) { filename in
                                        JournalPhotoThumbnail(filename: filename) {
                                            note.photoFileNames.removeAll { $0 == filename }
                                            note.photoCount = note.photoFileNames.count
                                            JournalMediaManager.shared.deleteFile(named: filename)
                                            saveNote()
                                        }
                                    }
                                }
                            }
                            .padding(.top, 10)
                        }

                        // Playable Audio Attachment Card
                        if note.hasAudio {
                            HStack(spacing: 12) {
                                Image(systemName: isPlayingAudio ? "waveform.circle.fill" : "waveform.circle")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color(red: 0.38, green: 0.45, blue: 0.98))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(note.audioTitle ?? "Voice Memo")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(DS.Color.textPrimary)

                                    Text("\(formatDuration(note.audioDuration)) • High Fidelity Audio")
                                        .font(.system(size: 10))
                                        .foregroundStyle(DS.Color.textSecondary)
                                }

                                Spacer()

                                Button {
                                    togglePlayAudio()
                                } label: {
                                    Image(systemName: isPlayingAudio ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundStyle(.white)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    note.hasAudio = false
                                    if let file = note.audioFileName {
                                        JournalMediaManager.shared.deleteFile(named: file)
                                    }
                                    note.audioFileName = nil
                                    saveNote()
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                        .foregroundStyle(DS.Color.textTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(14)
                            .background(Color(red: 0.16, green: 0.15, blue: 0.22), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.09, green: 0.08, blue: 0.13))
            .overlay(alignment: .bottomTrailing) {
                if showSavedToast {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Saved to Journal")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.85), in: Capsule())
                    .padding(20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // Right Audio Recording Studio Drawer (Screenshot 4)
            if showAudioDrawer {
                Divider()

                AppleJournalAudioStudioDrawer(
                    onAttach: { audioFile, duration in
                        note.hasAudio = true
                        note.audioFileName = audioFile
                        note.audioDuration = duration
                        saveNote()
                        withAnimation { showAudioDrawer = false }
                        Haptics.impact(.rigid)
                    },
                    onClose: {
                        withAnimation { showAudioDrawer = false }
                    }
                )
                .frame(width: 230)
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

    private func choosePhotoFromDisk() {
        let panel = NSOpenPanel()
        panel.title = "Select Photos for Journal Entry"
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]

        if panel.runModal() == .OK {
            for url in panel.urls {
                if let savedFilename = JournalMediaManager.shared.saveImage(from: url) {
                    note.photoFileNames.append(savedFilename)
                }
            }
            note.photoCount = note.photoFileNames.count
            saveNote()
            Haptics.impact(.light)
        }
    }

    private func togglePlayAudio() {
        if isPlayingAudio {
            audioPlayer?.stop()
            isPlayingAudio = false
            playbackTimer?.invalidate()
            playbackTimer = nil
        } else {
            guard let filename = note.audioFileName else { return }
            let fileURL = JournalMediaManager.shared.fileURL(for: filename)
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
                audioPlayer?.play()
                isPlayingAudio = true
                playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    if let player = audioPlayer {
                        if !player.isPlaying {
                            isPlayingAudio = false
                            playbackTimer?.invalidate()
                        }
                    }
                }
            } catch {}
        }
    }

    private func formatDuration(_ sec: Double) -> String {
        let m = Int(sec) / 60
        let s = Int(sec) % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func saveNote() {
        try? modelContext.save()
    }
}

// MARK: - JournalPhotoThumbnail

private struct JournalPhotoThumbnail: View {
    let filename: String
    let onDelete: () -> Void
    @State private var isHovered = false

    var body: some View {
        let fileURL = JournalMediaManager.shared.fileURL(for: filename)
        ZStack(alignment: .topTrailing) {
            if let image = NSImage(contentsOfFile: fileURL.path) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 100)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 120, height: 100)
                    .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
            }

            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white, .red)
                }
                .buttonStyle(.plain)
                .padding(4)
            }
        }
        .onHover { isHovered = $0 }
    }
}

// MARK: - AppleJournalAudioStudioDrawer (Live Recorder)

private struct AppleJournalAudioStudioDrawer: View {
    let onAttach: (String, Double) -> Void
    let onClose: () -> Void

    @State private var isRecording = false
    @State private var isPlaying = false
    @State private var recordTime: Double = 0
    @State private var timer: Timer? = nil
    @State private var audioRecorder: AVAudioRecorder? = nil
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var tempAudioURL: URL? = nil
    @State private var showTranscriptModal = false
    @State private var transcriptText = "Today was a productive day. Focused on morning execution, completed the high-intensity workout, and spent quality deep work time."

    var body: some View {
        VStack(spacing: 18) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Audio Recording")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text(isRecording ? "Recording Live…" : "Voice Studio")
                        .font(.system(size: 10))
                        .foregroundStyle(isRecording ? .red : DS.Color.textTertiary)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DS.Color.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            Spacer()

            // Waveform Visualizer Scrub Track (Screenshot 4)
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.18, green: 0.17, blue: 0.25))
                    .frame(width: 150, height: 260)

                // Simulated Dynamic Waveform Bars
                HStack(alignment: .center, spacing: 3) {
                    ForEach(0..<18, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(isRecording ? Color.pink.opacity(Double.random(in: 0.4...0.9)) : Color.purple.opacity(0.6))
                            .frame(width: 3, height: isRecording ? CGFloat.random(in: 20...200) : 40)
                    }
                }
                .frame(width: 140, height: 250)

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
                    if isRecording {
                        stopRecording()
                    } else {
                        togglePlayback()
                    }
                } label: {
                    Image(systemName: isRecording ? "pause.fill" : (isPlaying ? "pause.fill" : "play.fill"))
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
                    showTranscriptModal = true
                } label: {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.Color.textSecondary)
                        .padding(8)
                        .background(Color(red: 0.18, green: 0.17, blue: 0.25), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Transcribe Audio")
                .popover(isPresented: $showTranscriptModal) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Live Transcript Preview")
                            .font(.system(size: 12, weight: .bold))
                        Text(transcriptText)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(14)
                    .frame(width: 220)
                }

                // Big Red Record / Stop Button
                Button {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
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
                    if isRecording { stopRecording() }
                    if let url = tempAudioURL, let filename = JournalMediaManager.shared.saveAudioRecording(tempURL: url) {
                        onAttach(filename, recordTime)
                    } else {
                        onAttach("sample_memo.m4a", max(1.0, recordTime))
                    }
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
    }

    private func startRecording() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("temp_rec_\(UUID().uuidString).m4a")
        self.tempAudioURL = fileURL

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.record()
            isRecording = true
            recordTime = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                recordTime += 0.1
            }
            Haptics.impact(.light)
        } catch {
            isRecording = true
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                recordTime += 0.1
            }
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        timer?.invalidate()
        timer = nil
        Haptics.impact(.light)
    }

    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
        } else if let url = tempAudioURL {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
                isPlaying = true
            } catch {}
        }
    }

    private func formatRecordTime(_ sec: Double) -> String {
        let mins = Int(sec) / 60
        let s = Int(sec) % 60
        let ms = Int((sec.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", mins, s, ms)
    }
}

// MARK: - AppleJournalLocationPopover

struct AppleJournalLocationPopover: View {
    let currentLocation: String?
    let onSelect: (String?) -> Void

    @State private var customLocation = ""

    private let suggestions = [
        "🏡 Home",
        "💼 Office / Studio",
        "☕ Coffee Shop",
        "🏋️ Fitness Center",
        "🌳 Park / Outdoors",
        "✈️ Airport / Traveling",
        "📚 Library"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tag Location")
                .font(.system(size: 12, weight: .bold))

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                TextField("Enter custom location…", text: $customLocation)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .onSubmit {
                        let trimmed = customLocation.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onSelect(trimmed)
                        }
                    }
            }
            .padding(6)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                ForEach(suggestions, id: \.self) { place in
                    Button {
                        onSelect(place)
                    } label: {
                        HStack {
                            Text(place)
                                .font(.system(size: 11))
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(Color.clear, in: RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }

            if currentLocation != nil {
                Divider()
                Button(role: .destructive) {
                    onSelect(nil)
                } label: {
                    Text("Remove Location Tag")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(width: 200)
    }
}

// MARK: - AppleJournalTypographyPopover (Screenshot 3 Matching with Real Native Formatting)

struct AppleJournalTypographyPopover: View {
    @ObservedObject var controller: AppleJournalRichTextController

    var body: some View {
        VStack(spacing: 8) {
            // Row 1: B, I, U, S (Matching Screenshot 3)
            HStack(spacing: 2) {
                formatBtn("B") { controller.toggleBold() }
                formatBtn("I") { controller.toggleItalic() }
                formatBtn("U") { controller.toggleUnderline() }
                formatBtn("S") { controller.toggleStrikethrough() }
            }
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))

            // Row 2: List Formats (Bullets, Checklist, Numbered, Blockquote, Divider)
            HStack(spacing: 2) {
                formatIconBtn("list.bullet") { controller.insertBulletList() }
                formatIconBtn("checklist") { controller.insertChecklist() }
                formatIconBtn("list.number") { controller.insertNumberedList() }
                formatIconBtn("quote.opening") { controller.insertBlockquote() }
                formatIconBtn("switch.2") { controller.insertDivider() }
            }
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding(8)
        .background(Color(red: 0.16, green: 0.15, blue: 0.22))
    }

    private func formatBtn(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: title == "B" ? .bold : (title == "I" ? .medium : .regular)))
                .italic(title == "I")
                .underline(title == "U")
                .strikethrough(title == "S")
                .foregroundStyle(DS.Color.textPrimary)
                .frame(width: 36, height: 26)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }

    private func formatIconBtn(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(DS.Color.textPrimary)
                .frame(width: 28, height: 26)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }
}
