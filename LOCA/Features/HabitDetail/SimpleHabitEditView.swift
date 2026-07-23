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

extension Notification.Name {
    static let habitArchived = Notification.Name("habitArchived")
}

struct SimpleHabitEditView: View {

    let board: HabitBoard

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var editedName = ""
    @State private var showSaveError = false
    @State private var showDeleteConfirm = false
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
                        showDeleteConfirm = true
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
            .alert("Delete Habit?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) { deleteHabit() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The habit will be archived and can be restored later.")
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
            NotificationCenter.default.post(name: .habitArchived, object: board)
            dismiss()
        } catch {
            showSaveError = true
        }
    }
}

#Preview {
    @MainActor
    func makeContainer() -> (ModelContainer, HabitBoard) {
        let schema = Schema([HabitBoard.self, LogEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [config])
        let board = HabitBoard(name: "Morning Run", metricType: 0, colorIndex: 0)
        container.mainContext.insert(board)
        try? container.mainContext.save()
        return (container, board)
    }

    let (container, board) = makeContainer()
    return NavigationStack {
        SimpleHabitEditView(board: board)
            .modelContainer(container)
    }
}
