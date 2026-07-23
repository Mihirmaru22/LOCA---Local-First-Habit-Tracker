//
//  SimpleHabitCreationView.swift
//  LOCA
//
//  Phase 1.1 — Simplified Habit Creation
//
//  Minimal form for onboarding: name field only. Metric type (binary) and
//  color are auto-assigned. User creates a habit and begins logging in ~10 seconds.
//

import SwiftUI
import SwiftData

struct SimpleHabitCreationView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var habitName = ""
    @State private var isSaving = false
    @State private var showSaveError = false
    @FocusState private var nameFocused: Bool

    var onHabitCreated: ((UUID) -> Void)?

    var isValid: Bool {
        !habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: DS.Space.lg) {
                Spacer()

                VStack(spacing: DS.Space.md) {
                    Text("What habit do you want to build?")
                        .font(DS.Text.heading)
                        .foregroundStyle(DS.Color.textPrimary)

                    TextField("e.g. Morning run", text: $habitName)
                        .font(DS.Text.body)
                        .textFieldStyle(.roundedBorder)
                        .focused($nameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if isValid {
                                createHabit()
                            }
                        }
                }
                .padding(DS.Space.lg)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DS.Color.background)
            .navigationTitle("")
            .inlineNavigationTitleDisplay()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { createHabit() }
                        .fontWeight(.semibold)
                        .disabled(!isValid || isSaving)
                }
            }
            .task {
                // Auto-focus after sheet animation completes (~400ms)
                try? await Task.sleep(for: .milliseconds(400))
                nameFocused = true
            }
            .alert("Couldn't Create Habit", isPresented: $showSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please try again.")
            }
        }
    }

    private func createHabit() {
        guard isValid else { return }
        isSaving = true

        let trimmed = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nextColorIndex = nextColorIndexForNewHabit()

        let board = HabitBoard(
            name: trimmed,
            metricType: HabitBoard.MetricType.binary.rawValue,
            targetValue: nil,
            unitLabel: nil,
            colorIndex: nextColorIndex
        )

        modelContext.insert(board)

        do {
            try modelContext.save()
            let createdID = board.id
            dismiss()
            onHabitCreated?(createdID)
        } catch {
            isSaving = false
            showSaveError = true
        }
    }

    private func nextColorIndexForNewHabit() -> Int {
        // Simple rotation: count existing habits and use modulo
        let existingCount = (try? modelContext.fetchCount(FetchDescriptor<HabitBoard>(predicate: #Predicate { $0.archivedAt == nil }))) ?? 0
        return existingCount % ColorPalette.count
    }
}

#Preview {
    @MainActor
    func makePreviewContainer() -> ModelContainer {
        let schema = Schema([HabitBoard.self, LogEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [config])
    }

    NavigationStack {
        SimpleHabitCreationView()
            .modelContainer(makePreviewContainer())
    }
}
