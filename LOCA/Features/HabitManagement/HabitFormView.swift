//
//  HabitFormView.swift
//  LOCA
//
//  Phase 7.1 — Habit Management: Create / Edit Form
//

import SwiftUI
import SwiftData
import os

// MARK: - HabitFormView

struct HabitFormView: View {

    // MARK: Mode

    enum Mode {
        case create
        case edit(HabitBoard)
    }

    let mode: Mode
    var onBoardCreated: ((UUID) -> Void)?
    var onBoardArchived: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var draft: HabitBoardDraft
    @State private var showSaveError = false
    @State private var showArchiveConfirmation = false
    @State private var showArchiveError = false

    @FocusState private var nameFocused: Bool
    @FocusState private var goalFocused: Bool

    private let logger = Logger(subsystem: "com.mihirmaru.loca", category: "HabitManagement")
    private let swatchColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    // MARK: Init

    init(mode: Mode, onBoardCreated: ((UUID) -> Void)? = nil, onBoardArchived: (() -> Void)? = nil) {
        self.mode = mode
        self.onBoardCreated = onBoardCreated
        self.onBoardArchived = onBoardArchived
        switch mode {
        case .create:
            _draft = State(initialValue: HabitBoardDraft())
        case .edit(let board):
            _draft = State(initialValue: HabitBoardDraft(from: board))
        }
    }

    // MARK: Derived

    private var isCreate: Bool {
        if case .create = mode { return true }
        return false
    }

    private var navigationTitle: String { isCreate ? "New Habit" : "Edit Habit" }

    // MARK: Body

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                metricSection
                if draft.metric == .quantitative {
                    goalSection
                }
                colorSection
                if case .edit = mode {
                    Section {
                        Button("Delete Habit", role: .destructive) {
                            showArchiveConfirmation = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .inlineNavigationTitleDisplay()
            .scrollDismissesKeyboard(.interactively)
            .toolbar { toolbarContent }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        nameFocused = false
                        goalFocused = false
                    }
                }
            }
            .task {
                // Auto-focus the name field on create — but only AFTER the sheet's
                // presentation animation completes.
                //
                // Assigning @FocusState in `.onAppear` fires while the sheet is still
                // animating in, so `becomeFirstResponder` is requested against a text
                // field not yet settled in the window. UIKit drops that request while
                // SwiftUI's @FocusState latches `true`, desyncing SwiftUI's focus model
                // from UIKit's real responder chain. That single desync is the root of
                // this sheet's focus/keyboard failures: the first tap becomes a no-op
                // (the binding is already `true`, so no re-focus is issued), the keyboard
                // accessory toolbar installs against a transitioning window (floating/
                // detached), and "Done" can't resign a responder SwiftUI never owned.
                //
                // Waiting out the present animation lets the first-responder handshake
                // happen cleanly against a settled hierarchy. The delay must exceed the
                // sheet present animation (~0.35s); 0.4s clears it with margin.
                guard isCreate else { return }
                try? await Task.sleep(for: .milliseconds(400))
                nameFocused = true
            }
            .alert("Couldn't Save Habit", isPresented: $showSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your habit couldn't be saved. Please try again.")
            }
            .alert("Delete Habit?", isPresented: $showArchiveConfirmation) {
                Button("Delete", role: .destructive) { archiveBoard() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove the habit and all its history. This cannot be undone.")
            }
            .alert("Couldn't Delete Habit", isPresented: $showArchiveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("An error occurred. Please try again.")
            }
        }
    }

    // MARK: Name Section

    @ViewBuilder
    private var nameSection: some View {
        Section("Name") {
            TextField("Habit name", text: $draft.name)
                .focused($nameFocused)
                .submitLabel(.done)
                .onChange(of: draft.name) { _, new in
                    guard new.count > HabitBoardDraft.maxNameLength else { return }
                    draft.name = String(new.prefix(HabitBoardDraft.maxNameLength))
                }

            HStack {
                Text("Emoji")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("optional", text: $draft.emoji)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .onChange(of: draft.emoji) { _, new in
                        guard !new.isEmpty else { return }
                        let first = String(new.prefix(1))
                        let scalar = first.unicodeScalars.first
                        let valid = scalar.map { $0.properties.isEmoji && $0.value > 0x007F } ?? false
                        if !valid { draft.emoji = "" }
                        else if new.count > 1 { draft.emoji = first }
                    }
            }
        }
    }

    // MARK: Metric Section

    @ViewBuilder
    private var metricSection: some View {
        Section {
            Picker("Type", selection: $draft.metric) {
                Text("Daily Check-off").tag(HabitBoard.MetricType.binary)
                Text("Track Amount").tag(HabitBoard.MetricType.quantitative)
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Type")
        } footer: {
            Text(draft.metric == .binary
                 ? "Check off once a day."
                 : "Log a measured amount toward a daily goal.")
        }
    }

    // MARK: Goal Section (quantitative only)

    @ViewBuilder
    private var goalSection: some View {
        Section {
            HStack {
                Text("Daily Goal")
                Spacer()
                TextField("Amount", text: $draft.targetText)
                    .decimalKeyboard()
                    .focused($goalFocused)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(draft.parsedTarget != nil ? .primary : Color.red)
            }

            Picker("Unit", selection: $draft.unit) {
                ForEach(UnitOption.Category.allCases, id: \.self) { category in
                    Section(category.rawValue) {
                        ForEach(category.units) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                }
            }

            HStack {
                Text("Custom Unit")
                Spacer()
                TextField("e.g. pages", text: $draft.customUnitText)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
            }
        } header: {
            Text("Daily Goal")
        } footer: {
            if draft.targetText.isEmpty {
                Text("Enter an amount to enable Save.")
                    .foregroundStyle(Color.red)
            } else {
                Text("Multiple check-ins on the same day add up.")
            }
        }
    }

    // MARK: Color Section

    @ViewBuilder
    private var colorSection: some View {
        Section("Color") {
            LazyVGrid(columns: swatchColumns, spacing: 12) {
                ForEach(0 ..< ColorPalette.count, id: \.self) { index in
                    ColorSwatch(color: ColorPalette[index], isSelected: draft.colorIndex == index)
                        .contentShape(Circle())
                        .onTapGesture { draft.colorIndex = index }
                        .accessibilityLabel("Color \(index + 1)")
                        .accessibilityAddTraits(
                            draft.colorIndex == index ? [.isButton, .isSelected] : .isButton
                        )
                }
            }
            .padding(.vertical, 4)
            .listRowSeparator(.hidden)

            Toggle("Tinted Background", isOn: $draft.useColorBackground)
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { save() }
                .fontWeight(.semibold)
                .disabled(!draft.isValid)
                .tint(ColorPalette[draft.colorIndex])
        }
    }

    // MARK: Actions

    private func archiveBoard() {
        guard case .edit(let board) = mode else { return }
        do {
            try board.archive(in: modelContext)
            dismiss()
            onBoardArchived?()
        } catch {
            showArchiveError = true
        }
    }

    private func save() {
        var newBoardID: UUID?
        switch mode {
        case .create:
            let board = draft.makeBoard()
            newBoardID = board.id
            modelContext.insert(board)
        case .edit(let board):
            draft.apply(to: board)
        }
        do {
            try modelContext.save()
            dismiss()
            if let id = newBoardID { onBoardCreated?(id) }
        } catch {
            logger.error("Habit save failed: \(error.localizedDescription, privacy: .public)")
            modelContext.rollback()
            showSaveError = true
        }
    }
}

// MARK: - ColorSwatch

private struct ColorSwatch: View {
    let color: Color
    let isSelected: Bool

    var body: some View {
        Circle()
            .fill(color)
            .frame(height: 36)
            .overlay {
                Circle().strokeBorder(.primary, lineWidth: isSelected ? 3 : 0)
            }
            .overlay {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
    }
}

// MARK: - Preview

@MainActor
private func makeFormContainer() -> ModelContainer {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [config])
}

@MainActor
private func makeEditContainer() -> (ModelContainer, HabitBoard) {
    let container = makeFormContainer()
    let board = HabitBoard(
        name: "Running",
        metricType: HabitBoard.MetricType.quantitative.rawValue,
        targetValue: 5.0,
        unitLabel: "mi",
        colorIndex: 0
    )
    container.mainContext.insert(board)
    try? container.mainContext.save()
    return (container, board)
}

#Preview("Create") {
    HabitFormView(mode: .create)
        .modelContainer(makeFormContainer())
}

#Preview("Edit — Running") {
    let (container, board) = makeEditContainer()
    return HabitFormView(mode: .edit(board))
        .modelContainer(container)
}
