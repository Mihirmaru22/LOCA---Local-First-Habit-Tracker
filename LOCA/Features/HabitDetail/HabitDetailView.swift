import SwiftUI

// MARK: - HabitDetailView

/// Placeholder container for a selected habit's detail view.
///
/// This view intentionally contains **no business logic**, no heatmap rendering,
/// no charts, no journal UI, and no check-in flow. Phase 3's scope is navigation
/// structure only — this view exists so `NavigationSplitView`'s detail column has
/// somewhere to route to when a sidebar selection is made, and so Phase 5 (Heatmap
/// & Detail) has a stable, already-wired file and type to build real content inside,
/// rather than introducing a new file mid-navigation-wiring.
///
/// `ContentUnavailableView` is the correct native API for this "exists but has no
/// content yet" state — it's the same system component Apple uses for empty search
/// results, offline states, and similar placeholders, so this reads as an
/// intentional, first-party-feeling moment rather than an obviously-unfinished screen.
///
/// Phase 5 will replace this view's body with the real heatmap/stats/journal layout.
/// The type name and the `board: HabitBoard` parameter are expected to remain stable
/// across that change — only the body's content changes.
struct HabitDetailView: View {

    /// The selected board. Held directly (not by ID) because this view receives a
    /// live object from `RootNavigationView`'s own `@Query`-backed lookup — see
    /// ADR-007 for why navigation *selection state* itself avoids holding a model
    /// reference, which is a distinct concern from this view simply being handed
    /// one to display.
    let board: HabitBoard

    var body: some View {
        ContentUnavailableView {
            Label(board.name, systemImage: "circle.dashed")
        } description: {
            Text("Detail view coming in a later phase.")
        }
        .navigationTitle(board.name)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HabitDetailView(board: HabitBoard(name: "Running", colorIndex: 0))
    }
}
