//
//  SimpleHabitEditView.swift
//  LOCA
//
//  Phase 1.4 — Simple Habit Edit
//
//  Minimal edit modal: name only. No metric picker, no color picker,
//  no goal setter. Session 1.4's principle: invisible customization.
//

import SwiftUI
import SwiftData
import Foundation

struct SimpleHabitEditView: View {

    let board: HabitBoard

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var editedName = ""
    @State private var showSaveError = false
    @FocusState private var nameFocused: Bool

    var isValid: Bool {
        !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Space.lg) {
                VStack(alignment: .leading, spacing: DS.Space.sm) {
                    Text("Habit Name")
                        .font(DS.Text.body)
                        .foregroundStyle(DS.Color.textPrimary)

                    TextField("Habit name", text: $editedName)
                        .font(DS.Text.body)
                        .textFieldStyle(.roundedBorder)
                        .focused($nameFocused)
                        .submitLabel(.done)
                }
                .padding(DS.Space.lg)

                Spacer()

                Section {
                    Button("Delete Habit", role: .destructive) {
                        deleteHabit()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(DS.Space.lg)
            }
            .navigationTitle("Edit Habit")
            .inlineNavigationTitleDisplay()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
            .task {
                editedName = board.name
                try? await Task.sleep(for: .milliseconds(400))
                nameFocused = true
            }
            .alert("Couldn't Save", isPresented: $showSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please try again.")
            }
        }
    }

    private func saveChanges() {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        board.name = trimmed

        do {
            try modelContext.save()
            dismiss()
        } catch {
            showSaveError = true
        }
    }

    private func deleteHabit() {
        do {
            try board.archive(in: modelContext)
            // Cancel reminder when habit is archived (Phase 3.1). Capture the id
            // (a Sendable UUID) before crossing into the ReminderScheduler actor.
            let boardID = board.id
            Task {
                await ReminderScheduler.shared.cancelReminder(id: boardID)
            }
            NotificationCenter.default.post(name: .habitArchived, object: board)
            dismiss()
        } catch {
            showSaveError = true
        }
    }
}

// MARK: - Preview

@MainActor
private func makeHabitEditPreview() -> some View {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    // try! is acceptable in a #Preview fixture (Engineering Principles §Previews).
    let container = try! ModelContainer(for: schema, configurations: [config])
    let board = HabitBoard(name: "Morning Run", metricType: 0, colorIndex: 0)
    container.mainContext.insert(board)
    try? container.mainContext.save()
    return NavigationStack {
        SimpleHabitEditView(board: board)
            .modelContainer(container)
    }
}

#Preview {
    makeHabitEditPreview()
}
