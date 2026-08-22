import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct PlutoFastButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.05), value: configuration.isPressed)
    }
}

// MARK: - BrainStormEditorView (Authentic Apple Notes Sovereign Engine)

struct BrainStormEditorView: View {

    @Environment(\.modelContext) private var modelContext
    @Bindable var note: BrainStormNote
    @Binding var isZenMode: Bool
    var onOpenTour: (() -> Void)? = nil

    @StateObject private var editorController = RichTextEditorController()

    @State private var typographyPreset: TypographyPreset = .standard
    @State private var showWordCountHUD: Bool = true
    
    // Popovers & Sheets
    @State private var isShowingAaPopover: Bool = false
    @State private var isShowingAttachPopover: Bool = false
    @State private var isShowingLinkModal: Bool = false
    @State private var linkURLString: String = ""
    @State private var linkDisplayText: String = ""
    
    // In-Note Find Bar State (⌘F)
    @State private var showFindBar: Bool = false
    @State private var findQuery: String = ""

    // Local Attributed String Mirror
    @State private var localAttributedText: NSAttributedString = NSAttributedString()
    @State private var localPlainText: String = ""

    // Debounce Timer for Auto-Save
    @State private var saveWorkItem: DispatchWorkItem? = nil

    private var findMatchesCount: Int {
        guard !findQuery.isEmpty else { return 0 }
        let pattern = NSRegularExpression.escapedPattern(for: findQuery)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return 0 }
        let nsString = localPlainText as NSString
        return regex.numberOfMatches(in: localPlainText, options: [], range: NSRange(location: 0, length: nsString.length))
    }

    var body: some View {
        VStack(spacing: 0) {

            // 1. APPLE NOTES TOP WINDOW GLASS TOOLBAR
            appleNotesTopToolbar
            Divider().opacity(0.18)

            // 2. IN-NOTE FIND BAR (⌘F)
            if showFindBar {
                findInNoteBar
                Divider().opacity(0.18)
            }

            // 3. APPLE NOTES CANVAS
            VStack(alignment: .leading, spacing: 0) {
                // Centered Date Timestamp (Exact Apple Notes Layout)
                HStack {
                    Spacer()
                    Text(formatHeaderDate(note.updatedAt))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.35))
                    Spacer()
                }
                .padding(.top, 14)
                .padding(.bottom, 6)

                // The True AppKit Rich Text Surface (120Hz Decoupled Zero-Lag Pipeline)
                MacRichTextEditor(
                    initialAttributedText: note.attributedBody,
                    initialPlainText: note.bodyText,
                    preset: typographyPreset,
                    isEditable: !note.isLocked,
                    controller: editorController,
                    onTextChangeDebounced: { updatedAttr, updatedPlain in
                        handleTextChange(updatedAttr: updatedAttr, updatedPlain: updatedPlain)
                    }
                )
                .id(note.id)
                .padding(.horizontal, isZenMode ? 70 : 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Inline Tag Pills
                if !note.tags.isEmpty {
                    Divider().opacity(0.10)
                        .padding(.horizontal, isZenMode ? 70 : 24)

                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.accentColor.opacity(0.8))

                        ForEach(note.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.accentColor)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.12), in: Capsule())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, isZenMode ? 70 : 24)
                    .padding(.vertical, 8)
                }
            }
            .background(
                Color(nsColor: NSColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0))
            )

            // 4. BOTTOM METADATA HUD
            if showWordCountHUD {
                Divider().opacity(0.15)
                bottomStatusBar
            }
        }
        .sheet(isPresented: $isShowingLinkModal) {
            linkModalView
        }
        .onAppear {
            loadNoteContent()
        }
        .onChange(of: note.id) { _, _ in
            loadNoteContent()
        }
    }

    @State private var hoveredTool: String? = nil

    // MARK: - Apple Notes Unified Top Toolbar

    private var appleNotesTopToolbar: some View {
        HStack(spacing: 12) {
            
            // Left Group: Segmented Formatting Pill (Aa | ☑︎ | ⊞ | 📎 | 🔗)
            HStack(spacing: 0) {
                
                // 1. Aa Popover Button
                Button {
                    isShowingAaPopover.toggle()
                } label: {
                    Text("Aa")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(isShowingAaPopover ? Color.black : Color.white.opacity(0.9))
                        .frame(width: 34, height: 26)
                        .background(
                            isShowingAaPopover
                                ? Color(red: 0.95, green: 0.75, blue: 0.25)
                                : (hoveredTool == "Aa" ? Color.white.opacity(0.12) : Color.clear),
                            in: RoundedRectangle(cornerRadius: 5)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlutoFastButtonStyle())
                .onHover { h in hoveredTool = h ? "Aa" : nil }
                .help("Formatting (Aa)")
                .popover(isPresented: $isShowingAaPopover, arrowEdge: .bottom) {
                    aaFormattingPopover
                }

                Divider().frame(height: 14).opacity(0.25)

                // 2. Checklist Toggle
                Button {
                    editorController.toggleChecklist(preset: typographyPreset)
                } label: {
                    Image(systemName: "checklist")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .frame(width: 32, height: 26)
                        .background(hoveredTool == "checklist" ? Color.white.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 5))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlutoFastButtonStyle())
                .onHover { h in hoveredTool = h ? "checklist" : nil }
                .help("Checklist (⌘⇧C)")
                .keyboardShortcut("c", modifiers: [.command, .shift])

                Divider().frame(height: 14).opacity(0.25)

                // 3. Table Insertion
                Button {
                    editorController.insertTable(rows: 2, cols: 2, preset: typographyPreset)
                } label: {
                    Image(systemName: "tablecells")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .frame(width: 32, height: 26)
                        .background(hoveredTool == "table" ? Color.white.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 5))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlutoFastButtonStyle())
                .onHover { h in hoveredTool = h ? "table" : nil }
                .help("Insert Table Grid (⊞)")

                Divider().frame(height: 14).opacity(0.25)

                // 4. Attachments & Media Popover
                Button {
                    isShowingAttachPopover.toggle()
                } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .frame(width: 32, height: 26)
                        .background(
                            isShowingAttachPopover
                                ? Color.white.opacity(0.18)
                                : (hoveredTool == "attach" ? Color.white.opacity(0.12) : Color.clear),
                            in: RoundedRectangle(cornerRadius: 5)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlutoFastButtonStyle())
                .onHover { h in hoveredTool = h ? "attach" : nil }
                .help("Attach File or Media (📎)")
                .popover(isPresented: $isShowingAttachPopover, arrowEdge: .bottom) {
                    attachmentPopover
                }

                Divider().frame(height: 14).opacity(0.25)

                // 5. Link Insert (⌘K)
                Button {
                    linkURLString = ""
                    linkDisplayText = ""
                    isShowingLinkModal = true
                } label: {
                    Image(systemName: "link")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .frame(width: 32, height: 26)
                        .background(hoveredTool == "link" ? Color.white.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 5))
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlutoFastButtonStyle())
                .onHover { h in hoveredTool = h ? "link" : nil }
                .help("Add Link (⌘K)")
                .keyboardShortcut("k", modifiers: .command)
            }
            .padding(2)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.white.opacity(0.10), lineWidth: 1))

            Spacer()

            // Right Group: Share | More Actions (...) | Search | Fullscreen
            HStack(spacing: 8) {
                
                // Share & Export Menu
                Menu {
                    Button {
                        DocumentExportService.shared.exportPDF(title: note.title, attributedText: localAttributedText)
                    } label: {
                        Label("Export as PDF", systemImage: "arrow.down.doc")
                    }

                    Button {
                        DocumentExportService.shared.exportMarkdown(title: note.title, attributedText: localAttributedText)
                    } label: {
                        Label("Export as Markdown (.md)", systemImage: "doc.text")
                    }

                    Button {
                        DocumentExportService.shared.exportPlainText(title: note.title, text: localPlainText)
                    } label: {
                        Label("Export as Plain Text (.txt)", systemImage: "doc.plaintext")
                    }

                    Divider()

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(localPlainText, forType: .string)
                        Haptics.notify(.success)
                    } label: {
                        Label("Copy Note Text", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Share & Export Note")

                // More Actions Menu (...)
                Menu {
                    if let onOpenTour = onOpenTour {
                        Button {
                            onOpenTour()
                        } label: {
                            Label("Interactive Feature Guide & Tour ✦", systemImage: "sparkles")
                        }

                        Divider()
                    }

                    Button {
                        note.isPinned.toggle()
                        note.updatedAt = Date()
                        try? modelContext.save()
                    } label: {
                        Label(note.isPinned ? "Unpin Note" : "Pin Note", systemImage: note.isPinned ? "pin.slash.fill" : "pin.fill")
                    }

                    Button {
                        note.isLocked.toggle()
                        note.updatedAt = Date()
                        try? modelContext.save()
                    } label: {
                        Label(note.isLocked ? "Unlock Note" : "Lock Note", systemImage: note.isLocked ? "lock.open.fill" : "lock.fill")
                    }

                    Divider()

                    // Inter-Pillar Bridges
                    Button {
                        PillarBridgeController.shared.sendNoteToWork(note: note, context: modelContext, archiveOriginal: false)
                    } label: {
                        Label("Create Project in Work", systemImage: "briefcase.fill")
                    }

                    Button {
                        PillarBridgeController.shared.sendNoteToJournal(note: note, context: modelContext, archiveOriginal: true)
                    } label: {
                        Label("Send to Today's Journal", systemImage: "book.pages.fill")
                    }

                    Divider()

                    Button(role: .destructive) {
                        note.deletedAt = Date()
                        try? modelContext.save()
                    } label: {
                        Label("Delete Note", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .help("More Options")

                // In-Note Search Trigger
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showFindBar.toggle()
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundStyle(showFindBar ? Color.accentColor : Color.white.opacity(0.7))
                        .frame(width: 26, height: 26)
                        .background(showFindBar ? Color.accentColor.opacity(0.18) : Color.white.opacity(0.06), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Find in Note (⌘F)")
                .keyboardShortcut("f", modifiers: .command)

                // Feature Guide & Interactive Tour
                if let onOpenTour = onOpenTour {
                    Button {
                        onOpenTour()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10.5, weight: .bold))
                            Text("Guide")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.25))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.95, green: 0.75, blue: 0.25).opacity(0.14), in: RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(red: 0.95, green: 0.75, blue: 0.25).opacity(0.35), lineWidth: 1))
                    }
                    .buttonStyle(PlutoFastButtonStyle())
                    .help("Interactive Studio Feature Tour & Guide")
                }

                // Zen Distraction-Free Fullscreen
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isZenMode.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isZenMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 11))
                        if isZenMode {
                            Text("Exit Fullscreen")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                    .foregroundStyle(isZenMode ? Color.accentColor : Color.white.opacity(0.8))
                    .padding(.horizontal, isZenMode ? 8 : 6)
                    .padding(.vertical, 4)
                    .background(isZenMode ? Color.accentColor.opacity(0.18) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Zen Distraction-Free Fullscreen View (⌘⌃F / Esc)")
                .keyboardShortcut("f", modifiers: [.command, .control])
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.35))
    }

    // MARK: - The Signature "Aa" Typography Popover (Exact Apple Notes UI)

    private var aaFormattingPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // 1. Top Row of Inline Marks (B | I | U | S | Highlight | Color)
            HStack(spacing: 6) {
                markButton(label: "B", isBoldFont: true, isActive: editorController.isBold) {
                    editorController.toggleBold(preset: typographyPreset)
                }
                .keyboardShortcut("b", modifiers: .command)

                markButton(label: "I", isItalicFont: true, isActive: editorController.isItalic) {
                    editorController.toggleItalic(preset: typographyPreset)
                }
                .keyboardShortcut("i", modifiers: .command)

                markButton(label: "U", isUnderlinedText: true, isActive: editorController.isUnderlined) {
                    editorController.toggleUnderline()
                }
                .keyboardShortcut("u", modifiers: .command)

                markButton(label: "S", isStrikethroughText: true, isActive: editorController.isStrikethrough) {
                    editorController.toggleStrikethrough()
                }

                markButton(icon: "pencil.tip", isActive: editorController.isHighlighted) {
                    editorController.toggleHighlight()
                }

                ColorPicker("", selection: Binding(
                    get: { Color.white },
                    set: { color in
                        if let nsColor = NSColor(color).usingColorSpace(.sRGB) {
                            editorController.applyTextColor(nsColor)
                        }
                    }
                ))
                .labelsHidden()
                .frame(width: 22, height: 22)
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)

            Divider().opacity(0.25)

            // 2. Paragraph Style List (Title, Heading, Subheading, Body, Monostyled, Lists)
            VStack(spacing: 2) {
                styleRow(style: .title, title: "Title", fontSize: 17, weight: .bold)
                styleRow(style: .heading, title: "Heading", fontSize: 15, weight: .bold)
                styleRow(style: .subheading, title: "Subheading", fontSize: 13.5, weight: .semibold)
                styleRow(style: .body, title: "Body", fontSize: 13, weight: .regular)
                styleRow(style: .monostyled, title: "Monostyled", fontSize: 12.5, weight: .regular, isMonospaced: true)
                
                styleRow(style: .bulletedList, title: "• Bulleted List", fontSize: 13, weight: .regular)
                styleRow(style: .dashedList, title: "– Dashed List", fontSize: 13, weight: .regular)
                styleRow(style: .numberedList, title: "1. Numbered List", fontSize: 13, weight: .regular)
            }

            Divider().opacity(0.25)

            // 3. Block Quote
            styleRow(style: .quote, title: "│ Block Quote", fontSize: 13, weight: .medium)
        }
        .padding(10)
        .frame(width: 220)
        .background(Color(nsColor: NSColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1.0)))
    }

    private func markButton(label: String? = nil, icon: String? = nil, isBoldFont: Bool = false, isItalicFont: Bool = false, isUnderlinedText: Bool = false, isStrikethroughText: Bool = false, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if let label = label {
                    Text(label)
                        .font(.system(size: 13, weight: isBoldFont ? .black : .semibold))
                        .italic(isItalicFont)
                        .underline(isUnderlinedText)
                        .strikethrough(isStrikethroughText)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11.5, weight: .bold))
                }
            }
            .foregroundStyle(isActive ? Color.black : Color.white)
            .frame(width: 28, height: 26)
            .background(
                isActive
                    ? Color(red: 0.95, green: 0.75, blue: 0.25)
                    : Color.white.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlutoFastButtonStyle())
    }

    private func styleRow(style: NoteParagraphStyle, title: String, fontSize: CGFloat, weight: Font.Weight, isMonospaced: Bool = false) -> some View {
        let isSelected = editorController.activeParagraphStyle == style
        let isBodySelected = isSelected && style == .body

        return Button {
            editorController.applyParagraphStyle(style, preset: typographyPreset)
            isShowingAaPopover = false
        } label: {
            HStack(spacing: 8) {
                if isSelected && style != .body {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.25))
                        .frame(width: 12)
                } else {
                    Spacer().frame(width: 12)
                }

                Text(title)
                    .font(isMonospaced ? .system(size: fontSize, design: .monospaced) : .system(size: fontSize, weight: weight))
                    .foregroundStyle(isBodySelected ? Color.black : Color.white)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                isBodySelected
                    ? Color(red: 0.95, green: 0.75, blue: 0.25)
                    : (isSelected ? Color.white.opacity(0.08) : Color.clear),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlutoFastButtonStyle())
    }

    // MARK: - Attachments Popover

    private var attachmentPopover: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                isShowingAttachPopover = false
                choosePhotoOrVideo()
            } label: {
                Label("Choose Photo or Video...", systemImage: "photo.on.rectangle")
                    .font(.system(size: 12.5))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Button {
                isShowingAttachPopover = false
                attachGeneralFile()
            } label: {
                Label("Attach File...", systemImage: "doc")
                    .font(.system(size: 12.5))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .padding(8)
        .frame(width: 200)
        .background(Color(nsColor: NSColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1.0)))
    }

    private func choosePhotoOrVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .movie]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            let noteAttachment = "\n[Photo: \(url.lastPathComponent)]\n"
            let attr = NSAttributedString(string: noteAttachment, attributes: RichTextTypography.defaultAttributes(for: .body, preset: typographyPreset))
            let mutable = NSMutableAttributedString(attributedString: localAttributedText)
            mutable.append(attr)
            localAttributedText = mutable
            handleTextChange(updatedAttr: mutable, updatedPlain: mutable.string)
        }
    }

    private func attachGeneralFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            let noteAttachment = "\n📎 Attachment: \(url.lastPathComponent)\n"
            let attr = NSAttributedString(string: noteAttachment, attributes: RichTextTypography.defaultAttributes(for: .body, preset: typographyPreset))
            let mutable = NSMutableAttributedString(attributedString: localAttributedText)
            mutable.append(attr)
            localAttributedText = mutable
            handleTextChange(updatedAttr: mutable, updatedPlain: mutable.string)
        }
    }

    // MARK: - In-Note Find Bar (⌘F)

    private var findInNoteBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.4))

            TextField("Find in note...", text: $findQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(Color.white)
                .frame(width: 160)

            if !findQuery.isEmpty {
                Text(findMatchesCount > 0 ? "\(findMatchesCount) match\(findMatchesCount > 1 ? "es" : "")" : "No matches")
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundStyle(findMatchesCount > 0 ? Color.accentColor : Color.red.opacity(0.8))
            }

            Spacer()

            Button {
                showFindBar = false
                findQuery = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.45))
    }

    // MARK: - Bottom Status Bar

    private var bottomStatusBar: some View {
        HStack {
            let words = localPlainText.split { $0.isWhitespace }.count
            let chars = localPlainText.count
            let readTime = max(1, Int(ceil(Double(words) / 200.0)))

            Text("\(words) words   \(chars) characters   \(readTime) min read")
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.4))

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 5, height: 5)
                Text("Saved locally")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.30))
    }

    // MARK: - Link Modal View

    private var linkModalView: some View {
        VStack(spacing: 14) {
            Text("Add Link")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white)

            TextField("Display Text", text: $linkDisplayText)
                .textFieldStyle(.roundedBorder)

            TextField("URL (e.g. https://apple.com)", text: $linkURLString)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                Button("Cancel") {
                    isShowingLinkModal = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Insert") {
                    var urlString = linkURLString.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
                        urlString = "https://" + urlString
                    }
                    if let url = URL(string: urlString) {
                        editorController.insertLink(url: url, title: linkDisplayText, preset: typographyPreset)
                    }
                    isShowingLinkModal = false
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(18)
        .frame(width: 300, height: 180)
        .background(Color.black.opacity(0.85).background(.ultraThinMaterial))
    }

    // MARK: - Auto-Save & Debounce Pipeline

    private func handleTextChange(updatedAttr: NSAttributedString, updatedPlain: String) {
        localAttributedText = updatedAttr
        localPlainText = updatedPlain

        saveWorkItem?.cancel()
        let noteRef = self.note
        let work = DispatchWorkItem { [weak modelContext] in
            noteRef.bodyText = updatedPlain
            noteRef.bodyRTFData = RichTextTypography.serializeToRTFD(attributedString: updatedAttr)
            noteRef.updateTitleFromContent()
            noteRef.updatedAt = Date()
            try? modelContext?.save()
        }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60, execute: work)
    }

    private func flushSaveNow() {
        saveWorkItem?.cancel()
        note.bodyText = localPlainText
        note.bodyRTFData = RichTextTypography.serializeToRTFD(attributedString: localAttributedText)
        note.updateTitleFromContent()
        note.updatedAt = Date()
        try? modelContext.save()
    }

    private func loadNoteContent() {
        localAttributedText = note.attributedBody
        localPlainText = note.bodyText
        if note.fontDesign == "serif" {
            typographyPreset = .warmJournal
        } else if note.fontDesign == "monospaced" {
            typographyPreset = .monospaced
        } else {
            typographyPreset = .standard
        }
    }

    private func formatHeaderDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "d MMMM yyyy 'at' h:mm a"
        return df.string(from: date)
    }
}
