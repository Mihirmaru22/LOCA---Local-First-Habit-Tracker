import SwiftUI
import SwiftData
import AppKit

// MARK: - BrainStormEditorView (Pure Apple Notes Editor Surface)

enum NoteParagraphStyle: String, CaseIterable {
    case title = "Title"
    case heading = "Heading"
    case subheading = "Subheading"
    case body = "Body"
    case monospaced = "Monospaced"
}

struct BrainStormEditorView: View {

    @Environment(\.modelContext) private var modelContext
    @Bindable var note: BrainStormNote

    @State private var isZenMode: Bool = false
    @State private var isShowingTableEditor: Bool = false
    @State private var currentTable: BrainStormTable = BrainStormTable.makeDefault()
    @State private var checklistItems: [BrainStormChecklistItem] = []
    @State private var attachments: [BrainStormAttachment] = []
    @State private var isChecklistActive: Bool = false
    @State private var activeStyle: NoteParagraphStyle = .title
    @State private var showWordCountHUD: Bool = true
    @State private var isShowingAttachmentPicker: Bool = false
    @State private var isShowingExportSheet: Bool = false
    @State private var isShowingLinkModal: Bool = false
    @State private var linkURLString: String = ""
    @State private var linkDisplayText: String = ""
    
    // In-Note Find Bar State (⌘F)
    @State private var showFindBar: Bool = false
    @State private var findQuery: String = ""
    @State private var currentFindIndex: Int = 0

    @AppStorage("brainstorm_checklist_auto_bottom") private var autoMoveCheckedToBottom: Bool = false
    @Environment(\.undoManager) private var undoManager

    // Computed Find Matches
    private var findMatchesCount: Int {
        guard !findQuery.isEmpty else { return 0 }
        let pattern = NSRegularExpression.escapedPattern(for: findQuery)
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return 0 }
        let nsString = note.bodyText as NSString
        return regex.numberOfMatches(in: note.bodyText, options: [], range: NSRange(location: 0, length: nsString.length))
    }

    var body: some View {
        VStack(spacing: 0) {

            // 1. APPLE NOTES TOP FORMATTING TOOLBAR
            if !isZenMode {
                editorToolbar
                Divider().opacity(0.18)
            }

            // 2. IN-NOTE FLOATING FIND BAR (⌘F)
            if showFindBar {
                findInNoteBar
                Divider().opacity(0.18)
            }

            // 3. SCROLLABLE NOTES CANVAS
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Date & Time Stamp Subtitle
                    HStack {
                        Spacer()
                        Text(formatHeaderDate(note.updatedAt))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.35))
                        Spacer()
                    }
                    .padding(.top, 8)

                    // Primary Note Text Editor
                    TextEditor(text: Binding(
                        get: { note.bodyText },
                        set: { newText in
                            note.bodyText = newText
                            note.updateTitleFromContent()
                            try? modelContext.save()
                        }
                    ))
                    .font(canvasFont)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 220)
                    .padding(.horizontal, isZenMode ? 60 : 20)

                    // 4. INTERACTIVE CHECKLIST SECTION (If enabled)
                    if isChecklistActive || !checklistItems.isEmpty {
                        checklistSectionView
                            .padding(.horizontal, isZenMode ? 60 : 20)
                    }

                    // 5. INTERACTIVE TABLE SECTION (If present)
                    if note.hasTable || isShowingTableEditor {
                        tableSectionView
                            .padding(.horizontal, isZenMode ? 60 : 20)
                    }

                    // 6. ATTACHMENTS & MEDIA SECTION
                    if !attachments.isEmpty {
                        attachmentsSectionView
                            .padding(.horizontal, isZenMode ? 60 : 20)
                    }

                    // 7. BOTTOM TAG BAR
                    if !note.tags.isEmpty {
                        Divider().opacity(0.15)
                            .padding(.horizontal, isZenMode ? 60 : 20)

                        HStack(spacing: 6) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.accentColor.opacity(0.8))

                            ForEach(note.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.accentColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                            }
                            Spacer()
                        }
                        .padding(.horizontal, isZenMode ? 60 : 20)
                        .padding(.bottom, 12)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(
                // Classic Apple Notes Subtle Dark Paper Hue
                Color(nsColor: NSColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0))
            )

            // 8. BOTTOM METADATA STATUS BAR
            if showWordCountHUD && !isZenMode {
                Divider().opacity(0.15)
                bottomStatusBar
            }
        }
        .sheet(isPresented: $isShowingLinkModal) {
            linkModalView
        }
        .onAppear {
            loadPayloads()
        }
        .onChange(of: note.id) { _, _ in
            loadPayloads()
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

    // MARK: - Editor Toolbar

    private var editorToolbar: some View {
        HStack(spacing: 8) {
            // Paragraph Style Menu (Title, Heading, Body, Monospaced)
            Menu {
                ForEach(NoteParagraphStyle.allCases, id: \.self) { style in
                    Button {
                        if activeStyle == style && style != .body {
                            activeStyle = .body
                            applyParagraphStyle(.body)
                        } else {
                            activeStyle = style
                            applyParagraphStyle(style)
                        }
                    } label: {
                        HStack {
                            Text(style.rawValue)
                            if activeStyle == style {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "textformat")
                    Text(activeStyle.rawValue)
                        .font(.system(size: 11.5, weight: .medium))
                }
                .foregroundStyle(Color.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Divider().frame(height: 14).opacity(0.3)

            // Formatting Buttons
            formatButton(icon: "bold", help: "Bold (⌘B)") {
                wrapSelection(with: "**")
            }

            formatButton(icon: "italic", help: "Italic (⌘I)") {
                wrapSelection(with: "*")
            }

            formatButton(icon: "underline", help: "Underline (⌘U)") {
                wrapSelection(with: "__")
            }

            formatButton(icon: "strikethrough", help: "Strikethrough (⌘⇧X)") {
                wrapSelection(with: "~~")
            }

            Divider().frame(height: 14).opacity(0.3)

            // Checklist Toggle Button
            Button {
                toggleChecklist()
            } label: {
                Image(systemName: "checklist")
                    .font(.system(size: 12, weight: isChecklistActive ? .bold : .medium))
                    .foregroundStyle(isChecklistActive ? Color.accentColor : Color.white.opacity(0.8))
                    .frame(width: 26, height: 26)
                    .background(isChecklistActive ? Color.accentColor.opacity(0.18) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .help("Checklist (⌘⇧C)")
            .keyboardShortcut("c", modifiers: [.command, .shift])

            // Table Insert Button
            Button {
                toggleTable()
            } label: {
                Image(systemName: "tablecells")
                    .font(.system(size: 12, weight: note.hasTable ? .bold : .medium))
                    .foregroundStyle(note.hasTable ? Color.accentColor : Color.white.opacity(0.8))
                    .frame(width: 26, height: 26)
                    .background(note.hasTable ? Color.accentColor.opacity(0.18) : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .help("Table (⌘T)")
            .keyboardShortcut("t", modifiers: .command)

            // Link Insertion Button (⌘K)
            Button {
                linkURLString = ""
                linkDisplayText = ""
                isShowingLinkModal = true
            } label: {
                Image(systemName: "link")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .help("Add Link (⌘K)")
            .keyboardShortcut("k", modifiers: .command)

            // Attachment / Image Button
            Button {
                insertAttachment()
            } label: {
                Image(systemName: "paperclip")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .help("Attach File or Image")

            // Find in Note Button (⌘F)
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

            Spacer()

            // Lock Note Button
            Button {
                note.isLocked.toggle()
                note.updatedAt = Date()
                try? modelContext.save()
                Haptics.impact(.medium)
            } label: {
                Image(systemName: note.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 12))
                    .foregroundStyle(note.isLocked ? Color.indigo : Color.white.opacity(0.6))
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .help(note.isLocked ? "Unlock Note" : "Lock Note")

            // Share / Export Menu
            Menu {
                Button("Copy Note Text") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(note.bodyText, forType: .string)
                    Haptics.impact(.light)
                }
                Divider()
                Button("Export as Plain Text (.txt)") {
                    exportFile(content: note.bodyText, ext: "txt")
                }
                Button("Export as Markdown (.md)") {
                    exportFile(content: note.bodyText, ext: "md")
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Share & Export")

            // Fullscreen Zen Mode Button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isZenMode.toggle()
                }
            } label: {
                Image(systemName: isZenMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.06), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Zen Distraction-Free View (⌘⌃F)")
            .keyboardShortcut("f", modifiers: [.command, .control])
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.35))
    }

    private func formatButton(icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.85))
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .help(help)
    }

    // MARK: - Interactive Checklist View

    private var checklistSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("CHECKLIST", systemImage: "checklist")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.4))
                Spacer()

                Button {
                    let newItem = BrainStormChecklistItem(text: "")
                    checklistItems.append(newItem)
                    savePayloads()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 4) {
                ForEach(Array(checklistItems.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 8) {
                        Button {
                            checklistItems[index].isCompleted.toggle()
                            if autoMoveCheckedToBottom {
                                checklistItems.sort { !$0.isCompleted && $1.isCompleted }
                            }
                            savePayloads()
                            Haptics.impact(.light)
                        } label: {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14))
                                .foregroundStyle(item.isCompleted ? Color.accentColor : Color.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)

                        TextField("List item...", text: Binding(
                            get: { item.text },
                            set: { val in
                                checklistItems[index].text = val
                                savePayloads()
                            }
                        ))
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(item.isCompleted ? Color.white.opacity(0.4) : Color.white)
                        .strikethrough(item.isCompleted, color: Color.white.opacity(0.4))

                        Button {
                            checklistItems.remove(at: index)
                            savePayloads()
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.white.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Interactive Table Section View

    private var tableSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("TABLE", systemImage: "tablecells")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.4))
                Spacer()

                Button("Add Row") {
                    addRowToTable()
                }
                .font(.system(size: 10))
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)

                Button("Add Col") {
                    addColumnToTable()
                }
                .font(.system(size: 10))
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 1) {
                ForEach(Array(currentTable.rows.enumerated()), id: \.element.id) { rIdx, row in
                    HStack(spacing: 1) {
                        ForEach(Array(row.cells.enumerated()), id: \.element.id) { cIdx, cell in
                            TextField("", text: Binding(
                                get: { cell.text },
                                set: { val in
                                    currentTable.rows[rIdx].cells[cIdx].text = val
                                    savePayloads()
                                }
                            ))
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: (rIdx == 0 && currentTable.hasHeaderRow) ? .bold : .regular))
                            .padding(6)
                            .background(
                                (rIdx == 0 && currentTable.hasHeaderRow)
                                    ? Color.white.opacity(0.10)
                                    : Color.white.opacity(0.04)
                            )
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
        .padding(12)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Attachments Section View

    private var attachmentsSectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ATTACHMENTS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.4))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                ForEach(attachments) { att in
                    Button {
                        if let path = att.localPath {
                            NSWorkspace.shared.open(URL(fileURLWithPath: path))
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: att.fileType == "image" ? "photo" : "doc.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.accentColor)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(att.fileName)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.white)
                                    .lineLimit(1)

                                Text("\(att.fileSize / 1024) KB")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.4))
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .help("Open Attachment")
                }
            }
        }
    }

    // MARK: - Bottom Status Bar

    private var bottomStatusBar: some View {
        HStack {
            let words = note.bodyText.split(separator: " ").count
            let chars = note.bodyText.count

            Text("\(words) words   \(chars) characters")
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.4))

            Spacer()

            Text("Last edited \(formatHeaderDate(note.updatedAt))")
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.35))
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
                    var url = linkURLString.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !url.hasPrefix("http://") && !url.hasPrefix("https://") {
                        url = "https://" + url
                    }
                    let display = linkDisplayText.isEmpty ? url : linkDisplayText
                    note.bodyText += " [\(display)](\(url))"
                    note.updateTitleFromContent()
                    try? modelContext.save()
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

    // MARK: - Helpers & Data Binding

    private var canvasFont: Font {
        switch note.fontDesign {
        case "serif":
            return .custom("New York", size: 14)
        case "monospaced":
            return .system(size: 13, design: .monospaced)
        default:
            return .system(size: 14)
        }
    }

    private func applyParagraphStyle(_ style: NoteParagraphStyle) {
        switch style {
        case .title:
            if !note.bodyText.hasPrefix("# ") {
                note.bodyText = "# " + note.bodyText
            }
        case .heading:
            if !note.bodyText.hasPrefix("## ") {
                note.bodyText = "## " + note.bodyText
            }
        case .subheading:
            if !note.bodyText.hasPrefix("### ") {
                note.bodyText = "### " + note.bodyText
            }
        case .body:
            note.bodyText = note.bodyText.replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
        case .monospaced:
            note.fontDesign = "monospaced"
        }
        note.updateTitleFromContent()
        try? modelContext.save()
    }

    private func wrapSelection(with symbol: String) {
        note.bodyText += "\(symbol)text\(symbol)"
        note.updateTitleFromContent()
        try? modelContext.save()
    }

    private func toggleChecklist() {
        isChecklistActive.toggle()
        note.hasChecklist = isChecklistActive
        if isChecklistActive && checklistItems.isEmpty {
            checklistItems.append(BrainStormChecklistItem(text: ""))
        }
        savePayloads()
    }

    private func toggleTable() {
        note.hasTable.toggle()
        isShowingTableEditor = note.hasTable
        savePayloads()
    }

    private func addRowToTable() {
        let colCount = currentTable.rows.first?.cells.count ?? 2
        var newRow = BrainStormTableRow()
        for _ in 0..<colCount {
            newRow.cells.append(BrainStormTableCell(text: ""))
        }
        currentTable.rows.append(newRow)
        savePayloads()
    }

    private func addColumnToTable() {
        for i in 0..<currentTable.rows.count {
            currentTable.rows[i].cells.append(BrainStormTableCell(text: ""))
        }
        savePayloads()
    }

    private func insertAttachment() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        if panel.runModal() == .OK, let url = panel.url {
            let att = BrainStormAttachment(
                fileName: url.lastPathComponent,
                fileSize: (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init)) ?? 0,
                fileType: url.pathExtension.lowercased() == "pdf" ? "pdf" : "file",
                localPath: url.path
            )
            attachments.append(att)
            note.hasAttachments = true
            savePayloads()
        }
    }

    private func exportFile(content: String, ext: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(note.title).\(ext)"
        if panel.runModal() == .OK, let url = panel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func loadPayloads() {
        if let data = note.tableDataJSON?.data(using: .utf8),
           let table = try? JSONDecoder().decode(BrainStormTable.self, from: data) {
            currentTable = table
        }
        if let data = note.checklistItemsJSON?.data(using: .utf8),
           let items = try? JSONDecoder().decode([BrainStormChecklistItem].self, from: data) {
            checklistItems = items
            isChecklistActive = !items.isEmpty
        }
        if let data = note.attachmentsJSON?.data(using: .utf8),
           let atts = try? JSONDecoder().decode([BrainStormAttachment].self, from: data) {
            attachments = atts
        }
    }

    private func savePayloads() {
        if let data = try? JSONEncoder().encode(currentTable),
           let str = String(data: data, encoding: .utf8) {
            note.tableDataJSON = str
        }
        if let data = try? JSONEncoder().encode(checklistItems),
           let str = String(data: data, encoding: .utf8) {
            note.checklistItemsJSON = str
        }
        if let data = try? JSONEncoder().encode(attachments),
           let str = String(data: data, encoding: .utf8) {
            note.attachmentsJSON = str
        }
        note.updatedAt = Date()
        try? modelContext.save()
    }

    private func formatHeaderDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMMM d, yyyy 'at' h:mm a"
        return df.string(from: date)
    }
}
