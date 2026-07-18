//
//  TodayView.swift
//  LOCA
//
//  Phase 11.1 — The "Today" root surface.
//
//  LOCA is being designed as a platform. This view is the root: a "Today" surface
//  that composes module dashboards via a ModuleDescriptor seam. Today, Habits is
//  the only tenant — no placeholder modules, no empty tabs. The seam exists for
//  when Fitness, Sleep, and other modules arrive; they'll plug in via a new
//  ModuleDescriptor conformer without redesign.
//
//  Architecture: SwiftUI NavigationStack root. When modules >= 3, the root
//  container upgrades to a TabView or Browse grid, but the screens beneath
//  (HabitListView, etc.) don't change — only the outer container swaps.
//

import SwiftUI

// MARK: - ModuleDescriptor

/// A protocol defining how a module presents itself on the "Today" surface.
/// Each module (Habits, Fitness, Sleep, etc.) conforms to this and provides
/// its own dashboard view.
protocol ModuleDescriptor {
    var id: String { get }
    var title: String { get }
    @ViewBuilder var dashboardView: some View { get }
}

// MARK: - HabitsModule (first tenant)

struct HabitsModule: ModuleDescriptor {
    let id = "habits"
    let title = "Habits"

    @ViewBuilder
    var dashboardView: some View {
        HabitListView()
    }
}

// MARK: - TodayView

struct TodayView: View {

    /// The active modules. Today: Habits only. When Fitness arrives, add it here.
    /// No placeholder modules — only fully implemented, tested, shipped modules.
    private let activeModules: [any ModuleDescriptor] = [
        HabitsModule()
    ]

    var body: some View {
        NavigationStack {
            // Single module today (Habits)
            HabitListView()
        }
    }
}

// MARK: - Preview

#Preview {
    TodayView()
}
