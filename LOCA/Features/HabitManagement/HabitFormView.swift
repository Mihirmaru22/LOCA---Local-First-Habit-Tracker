//
//  HabitFormView.swift
//  LOCA
//
//  Phase 7.1 — Habit Management: Create / Edit Form
//
//  A single form serving both create and edit. Presented as a `.sheet`:
//  from the Dashboard "+" (create, Phase 7.1) and from HabitDetailView's
//  "Edit" toolbar button (edit, Phase 7.2). Owns its own ModelContext for the
//  insert/save, following the CheckInSheet pattern.
//

import SwiftUI
import SwiftData
import os

// MARK: - HabitFormView

/// Modal form for creating a new `HabitBoard` or editing an existing one.
///
/// ## Modes
/// `Mode.create` starts from an empty `HabitBoardDraft`; `Mode.edit(board)`
/// pre-populates the draft from the board and writes changes back on save. The
/// form UI is identical in both modes — only the initial draft, navigation
/// title, and save action differ.
///
/// ## Persistence
/// Mirrors `CheckInSheet`: a `NavigationStack`-hosted `Form` with Cancel /
/// Save toolbar actions, its own `@Environment(\.modelContext)`, and a
/// non-blocking save-error alert that keeps the sheet open on failure. Create
/// inserts a new board; edit mutates in place. Both persist through the shared
/// container, so the Dashboard's `@Query` reflects the change reactively with
/// no data flow back to the parent.
struct HabitFormView: View {

    // MARK: Mode

    /// Whether the form creates a new board or edits an existing one.
    enum Mode {
        case create
        case edit(HabitBoard)
    }

    let mode: Mode

    /// Called after a successful **create** save, with the new board's `UUID`.
    /// The caller (Dashboard → RootNavigationView) sets `selectedBoardID` to
    /// navigate straight to the new habit's detail view.
    var onBoardCreated: ((UUID) -> Void)?
    var onBoardArchived: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var draft: HabitBoardDraft
    @State private var showSaveError = false
    @State private var showArchiveConfirmation = false
    @State private var showArchiveError = false

    /// Auto-focuses the name field on create so the keyboard is immediately
    /// available; edit mode leaves focus unset so the user sees the whole form.
    @FocusState private var nameFocused: Bool
    @FocusState private var anyFieldFocused: Bool

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

    private var navigationTitle: String {
        isCreate ? "New Habit" : "Edit Habit"
    }

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
                        anyFieldFocused = false
                    }
                }
            }
            .onAppear { if isCreate { nameFocused = true } }
            .animation(reduceMotion ? nil : .rippleSettle, value: draft.metric)
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

    // MARK: Name

    @ViewBuilder
    private var nameSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Habit name", text: $draft.name)
                    .focused($nameFocused)
                    .font(.body)
                    .accessibilityLabel("Habit name")
                    .onChange(of: draft.name) { _, new in
                        if new.count > HabitBoardDraft.maxNameLength {
                            draft.name = String(new.prefix(HabitBoardDraft.maxNameLength))
                        }
                    }

                HStack(spacing: 8) {
                    Text("Emoji (optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("", text: $draft.emoji)
                        .frame(width: 32)
                        .multilineTextAlignment(.center)
                        .font(.title3)
                        .onChange(of: draft.emoji) { _, new in
                            let first = String(new.trimmingCharacters(in: .whitespaces).prefix(1))
                            let isValidEmoji = first.unicodeScalars.first.map {
                                $0.properties.isEmoji && $0.value > 0x007F
                            } ?? false
                            let clamped = isValidEmoji ? first : ""
                            if draft.emoji != clamped { draft.emoji = clamped }
                        }
                    Spacer()
                }
            }
        } header: {
            Text("Name")
        }
    }

    // MARK: Metric Type

    @ViewBuilder
    private var metricSection: some View {
        Section {
            Picker("Type", selection: $draft.metric) {
                Text("Daily Check-off").tag(HabitBoard.MetricType.binary)
                Text("Track Amount").tag(HabitBoard.MetricType.quantitative)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Habit type")
        } header: {
            Text("Type")
        } footer: {
            Text(draft.metric == .binary
                 ? "Check off once a day."
                 : "Log a measured amount toward a daily goal.")
        }
    }

    // MARK: Goal (Quantitative only)

    // MARK: SF Pro Rounded for the goal value (Engineering Principles §3)
    //
    // The numeric goal field uses `.rounded` to match CheckInSheet's value
    // field and the analytics numeric identity.

    @ViewBuilder
    private var goalSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Goal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("0", text: $draft.targetText)
                            .decimalKeyboard()
                            .focused($anyFieldFocused)
                            .font(.system(.body, design: .rounded))
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(draft.parsedTarget != nil ? .primary : .secondary)
                            .accessibilityLabel("Daily goal amount")
                    }
                    .frame(maxWidth: 100)

                    Picker("Unit", selection: $draft.unit) {
                        ForEach(UnitOption.Category.allCases, id: \.self) { category in
                            Section(category.rawValue) {
                                ForEach(category.units) { option in
                                    Text(option.displayName).tag(option)
                                }
                            }
                        }
                    }
                    .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Custom Unit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("or type your own", text: $draft.customUnitText)
                        .focused($anyFieldFocused)
                        .font(DS.Text.body)
                        .textFieldStyle(.roundedBorder)
                }

                if draft.targetText.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text("Enter a daily goal to save")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        } header: {
            Text("Daily Goal")
        } footer: {
            Text("The amount that completes a day. Multiple check-ins add up.")
        }
    }

    // MARK: Color

    @ViewBuilder
    private var colorSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose a color")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: swatchColumns, spacing: 12) {
                    ForEach(0 ..< ColorPalette.count, id: \.self) { index in
                        ColorSwatch(
                            color: ColorPalette[index],
                            isSelected: draft.colorIndex == index
                        )
                        .contentShape(Circle())
                        .onTapGesture { draft.colorIndex = index }
                        .accessibilityLabel("Color \(index + 1)")
                        .accessibilityAddTraits(
                            draft.colorIndex == index ? [.isButton, .isSelected] : .isButton
                        )
                    }
                }

                Divider()
                    .padding(.vertical, 4)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tinted Background")
                            .font(.body)
                        Text("Apply habit color to the card background")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $draft.useColorBackground)
                        .labelsHidden()
                        .accessibilityLabel("Use habit color as background tint")
                }
            }
        } header: {
            Text("Color")
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

    // MARK: Save

    // MARK: Persistence Sequence
    //
    // Create: insert(makeBoard()) → save.
    // Edit:   apply(to: board)    → save.
    // On failure: rollback() discards the insert or in-place mutation
    // atomically; the sheet stays open with a non-blocking alert (EP §4.1).

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
            logger.debug(
                "Habit saved (\(isCreate ? "create" : "edit", privacy: .public)): '\(draft.trimmedName, privacy: .public)'."
            )
            dismiss()
            if let id = newBoardID {
                onBoardCreated?(id)
            }
        } catch {
            logger.error(
                "Habit save failed: \(error.localizedDescription, privacy: .public)"
            )
            modelContext.rollback()
            showSaveError = true
        }
    }
}

// MARK: - ColorSwatch

/// A single selectable palette color in the form's color grid.
///
/// Renders a filled circle; the selected swatch gains a primary-colored ring
/// and a checkmark for a clear, accessible selected state that does not rely on
/// color alone.
private struct ColorSwatch: View {
    let color: Color
    let isSelected: Bool

    var body: some View {
        Circle()
            .fill(color)
            .frame(height: 36)
            .overlay {
                Circle()
                    .strokeBorder(.primary, lineWidth: isSelected ? 3 : 0)
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
    // try! is acceptable in a #Preview fixture (Engineering Principles §Previews).
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
