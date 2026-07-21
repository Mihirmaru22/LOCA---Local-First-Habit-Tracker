//
//  HabitListView.swift
//  LOCA
//
//  Minimal version - direct rendering, no state computation loops
//

import SwiftUI
import SwiftData

struct HabitListView: View {
    @Query(sort: [SortDescriptor(\HabitBoard.createdAt)], animation: .default)
    private var boards: [HabitBoard]

    @Environment(\.modelContext) private var modelContext
    @State private var showingCreateSheet = false
    @AppStorage("habitListLayout") private var layout: String = "list"

    var body: some View {
        ZStack {
            if boards.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No habits yet")
                        .font(.title2)
                    Button("Create Habit") {
                        showingCreateSheet = true
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(boards.filter { $0.archivedAt == nil }, id: \.id) { board in
                            NavigationLink(destination: HabitDetailView(board: board)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(board.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("Current Streak: \(board.currentStreak)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Today")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    SettingsMenuView()
                    Button(action: { showingCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            HabitFormView(mode: .create)
        }
    }
}

#Preview {
    NavigationStack {
        HabitListView()
    }
}
