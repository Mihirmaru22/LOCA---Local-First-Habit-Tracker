import SwiftUI
import SwiftData

// MARK: - FocusGoalsPanel

struct FocusGoalsPanel: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusGoal.createdAt, order: .forward) private var allGoals: [FocusGoal]

    @Binding var isPresented: Bool
    @State private var newGoalText: String = ""

    private var openGoals: [FocusGoal] {
        allGoals.filter { !$0.isCompleted }
    }

    private var completedGoals: [FocusGoal] {
        allGoals.filter { $0.isCompleted }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack {
                Label("Session goals", systemImage: "target")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    isPresented = false
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            // Add Goal Input
            HStack(spacing: 8) {
                TextField("Type a goal...", text: $newGoalText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .onSubmit {
                        addNewGoal()
                    }

                Button {
                    addNewGoal()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(newGoalText.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // Stats Row: Open vs Completed
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("\(openGoals.count)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Open")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: 32)

                VStack(spacing: 2) {
                    Text("\(completedGoals.count)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.green)
                    Text("Completed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))

            // Goal List ScrollView
            ScrollView {
                VStack(spacing: 8) {
                    // Open Goals
                    ForEach(openGoals) { goal in
                        goalRow(goal: goal)
                    }

                    // Completed Goals
                    if !completedGoals.isEmpty {
                        ForEach(completedGoals) { goal in
                            goalRow(goal: goal)
                        }
                    }
                }
            }
            .frame(maxHeight: 280)

            // Footer Telemetry
            HStack(spacing: 12) {
                HStack(spacing: 5) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("800 users studying")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                HStack(spacing: 5) {
                    Circle().fill(Color.pink).frame(width: 6, height: 6)
                    Text("Pluto StudyStream")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(width: 290)
        .background(
            Color.black.opacity(0.72)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
    }

    private func goalRow(goal: FocusGoal) -> some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    goal.isCompleted.toggle()
                    try? modelContext.save()
                    if goal.isCompleted {
                        PlutoSoundEngine.shared.play(.checkmark)
                        Haptics.notify(.success)
                    }
                }
            } label: {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(goal.isCompleted ? Color.green : Color.white.opacity(0.5))
            }
            .buttonStyle(.plain)

            Text(goal.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(goal.isCompleted ? .white.opacity(0.4) : .white)
                .strikethrough(goal.isCompleted, color: .white.opacity(0.4))
                .lineLimit(2)

            Spacer()

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    modelContext.delete(goal)
                    try? modelContext.save()
                    PlutoSoundEngine.shared.play(.deleteTrash)
                    Haptics.impact(.light)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(goal.isCompleted ? 0.02 : 0.06), in: RoundedRectangle(cornerRadius: 8))
    }

    private func addNewGoal() {
        let trimmed = newGoalText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let goal = FocusGoal(title: trimmed)
        modelContext.insert(goal)
        try? modelContext.save()
        newGoalText = ""
        PlutoSoundEngine.shared.play(.checkmark)
        Haptics.impact(.light)
    }
}
