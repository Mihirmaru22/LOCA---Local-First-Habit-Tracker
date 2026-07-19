//
//  HabitDetailView.swift
//  LOCA
//
//  Phase 12.3 — Habit Detail: Three-Surface Redesign
//
//  Restructures the detail page into three surfaces accessible via bottom tabs:
//  - Analytics: charts and trend visualizations
//  - Check-ins: today's status and quick logging interface
//  - Journal: day-grouped activity timeline
//
//  This separation allows each surface to focus on its purpose without
//  compression, and provides a natural workflow: review trends → log today →
//  reflect on history.
//

import SwiftUI
import SwiftData

// MARK: - HabitDetailView

struct HabitDetailView: View {

    let board: HabitBoard
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditSheet = false
    @State private var _selectedTab = 0


    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $_selectedTab) {
                // Analytics Tab
                HabitAnalyticsView(board: board)
                    .tabItem { Label("Analytics", systemImage: "chart.xyaxis.line") }
                    .tag(0)

                // Check-ins Tab
                HabitCheckInsView(board: board)
                    .tabItem { Label("Check-ins", systemImage: "checklist") }
                    .tag(1)

                // Journal Tab
                HabitJournalView(board: board)
                    .tabItem { Label("Journal", systemImage: "doc.text") }
                    .tag(2)
            }
            .pagedTabView()

            // iOS uses the paged style, which draws no tab bar of its own, so the
            // selector is ours to supply. macOS falls back to the native tabbed
            // TabView (driven by the .tabItem labels above) — adding the pill
            // there would duplicate it.
            #if os(iOS)
            SurfaceSelector(selection: $_selectedTab)
                .padding(.bottom, DS.Space.lg)
            #endif
        }
        .navigationTitle(board.name)
        .largeNavigationTitleDisplay()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            HabitFormView(mode: .edit(board))
        }
    }
}

// MARK: - SurfaceSelector

/// Floating segmented control for the three detail surfaces.
///
/// Sits over the paged `TabView` on iOS, where `.page(indexDisplayMode: .never)`
/// supplies no affordance of its own. Icon-only to stay compact at the bottom
/// of the screen; each segment carries an accessibility label so the meaning is
/// never carried by the glyph alone.
private struct SurfaceSelector: View {

    @Binding var selection: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Surface {
        let index: Int
        let icon: String
        let label: String
    }

    private let surfaces: [Surface] = [
        Surface(index: 0, icon: "chart.xyaxis.line", label: "Analytics"),
        Surface(index: 1, icon: "checklist", label: "Check-ins"),
        Surface(index: 2, icon: "doc.text", label: "Journal")
    ]

    var body: some View {
        HStack(spacing: DS.Space.xs) {
            ForEach(surfaces, id: \.index) { surface in
                Button {
                    withAnimation(DS.Motion.confirm(reduceMotion: reduceMotion)) {
                        selection = surface.index
                    }
                } label: {
                    Image(systemName: surface.icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(
                            selection == surface.index
                                ? DS.Color.textPrimary
                                : DS.Color.textSecondary
                        )
                        .frame(width: 52, height: 40)
                        .background {
                            if selection == surface.index {
                                RoundedRectangle(cornerRadius: DS.Radius.control, style: .continuous)
                                    .fill(DS.Color.surfaceRecessed)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(surface.label))
                .accessibilityAddTraits(
                    selection == surface.index ? [.isButton, .isSelected] : .isButton
                )
            }
        }
        .padding(DS.Space.xs)
        .background {
            Capsule(style: .continuous)
                .fill(DS.Color.surface)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        }
    }
}

// MARK: - Preview

@MainActor
private func makeDetailPreviewContainer() -> (ModelContainer, HabitBoard) {
    let schema = Schema([HabitBoard.self, LogEntry.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    let context = container.mainContext

    let habit = HabitBoard(name: "Morning Run", metricType: 1, targetValue: 5, unitLabel: "km", colorIndex: 0)
    habit.currentStreak = 12
    habit.longestStreak = 45
    context.insert(habit)

    // Add logs across this month
    let now = Date()
    let calendar = Calendar.current
    guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
        return (container, habit)
    }

    for daysAgo in 0..<30 {
        if daysAgo % 2 == 0 { // Log every other day
            guard let logDate = calendar.date(byAdding: .day, value: daysAgo, to: monthStart) else { continue }
            let value = Double.random(in: 3...7)
            context.insert(LogEntry(timestamp: logDate, value: value, boardID: habit.id, board: habit))
        }
    }

    try? context.save()
    return (container, habit)
}

#Preview {
    let (container, habit) = makeDetailPreviewContainer()
    return NavigationStack {
        HabitDetailView(board: habit)
    }
    .modelContainer(container)
}
