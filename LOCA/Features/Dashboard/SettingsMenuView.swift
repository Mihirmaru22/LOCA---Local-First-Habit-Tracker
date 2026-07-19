//
//  SettingsMenuView.swift
//  LOCA
//
//  Phase 14.3 — Dashboard settings menu (ship-blocker fix).
//
//  Removed: Layout picker (habitListLayout writes but nothing reads it; Grid/Timeline modes don't exist).
//  Routes to: Archive (view archived habits) and app Settings.
//

import SwiftUI
import SwiftData

// MARK: - SettingsMenuView

struct SettingsMenuView: View {

    @State private var showingArchive = false
    @State private var showingSettings = false

    var body: some View {
        Menu {
            Button(action: { showingArchive = true }) {
                Label("Archive", systemImage: "archivebox")
            }
            Button(action: { showingSettings = true }) {
                Label("Settings", systemImage: "gear")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .sheet(isPresented: $showingArchive) {
            ArchiveListView()
        }
        .sheet(isPresented: $showingSettings) {
            AppSettingsView()
        }
    }
}

// MARK: - Archive List

struct ArchiveListView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\HabitBoard.createdAt)]) private var allBoards: [HabitBoard]

    init() {}

    private var archivedBoards: [HabitBoard] {
        allBoards.filter { $0.archivedAt != nil }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                if archivedBoards.isEmpty {
                    VStack(spacing: DS.Space.md) {
                        Image(systemName: "archivebox")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No Archived Habits")
                            .font(DS.Text.body)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    VStack(spacing: DS.Space.md) {
                        ForEach(archivedBoards) { board in
                            HStack {
                                VStack(alignment: .leading, spacing: DS.Space.xs) {
                                    Text(board.name)
                                        .font(DS.Text.body)
                                    Text("Archived")
                                        .font(DS.Text.caption)
                                        .foregroundStyle(DS.Color.textSecondary)
                                }
                                Spacer()
                                Button(action: { unarchive(board) }) {
                                    Image(systemName: "arrow.uturn.backward")
                                        .foregroundStyle(ColorPalette[board.colorIndex])
                                }
                            }
                            .padding(DS.Space.md)
                            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                        }
                    }
                }

                Spacer()
            }
            .padding(DS.Space.lg)
            .navigationTitle("Archive")
            .inlineNavigationTitleDisplay()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done", action: { dismiss() })
                }
            }
        }
    }

    private func unarchive(_ board: HabitBoard) {
        board.archivedAt = nil
        try? modelContext.save()
    }
}


// MARK: - App Settings

struct AppSettingsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DS.Space.lg) {
                SectionHeader("App Settings")

                VStack(spacing: DS.Space.md) {
                    HStack {
                        Text("Version")
                            .font(DS.Text.body)
                        Spacer()
                        Text("1.0.0")
                            .font(DS.Text.caption)
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                    .padding(DS.Space.md)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
                }

                Spacer()
            }
            .padding(DS.Space.lg)
            .navigationTitle("Settings")
            .inlineNavigationTitleDisplay()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done", action: { dismiss() })
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsMenuView()
}
