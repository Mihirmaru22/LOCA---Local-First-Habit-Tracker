import SwiftUI
import SwiftData

// MARK: - TodoMode   (sub-pillar toggle)

/// The two sub-pillars of the Today (Todo) section.
///
/// - **plan**: a time-blocked day planner — a vertical timeline of tasks placed
///   at specific times on a chosen day (`MacDayPlannerColumn`).
/// - **list**: the GTD-style Today / Upcoming / Anytime bucket list
///   (`MacTodoListColumn`).
///
/// Both modes select the same `TodoItem`, so the shared detail column
/// (`MacTodoDetailColumn`) works unchanged for either sub-pillar.
enum TodoMode: String, CaseIterable, Identifiable {
    case plan = "Plan"
    case list = "List"
    var id: String { rawValue }
}

// MARK: - MacTodoContentColumn

/// Middle column of the Mac three-pane layout for the Today (Todo) section.
///
/// A segmented `Picker` at the top switches between the two sub-pillars,
/// mirroring the Journal section's Collect / Analyse toggle. `selection` is
/// threaded up to `MacRootView` so the detail column shows the chosen task
/// regardless of which sub-pillar surfaced it.
struct MacTodoContentColumn: View {

    @Binding var selection: TodoItem?
    @State private var mode: TodoMode = .plan
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // Sub-pillar toggle
            Picker("Mode", selection: $mode) {
                ForEach(TodoMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DS.Space.md)
            .padding(.vertical, DS.Space.sm)

            Divider()

            // Plan ↔ List crossfade with directional slide
            ZStack {
                if mode == .plan {
                    MacDayPlannerColumn(selection: $selection)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal:   .opacity.combined(with: .move(edge: .trailing))
                        ))
                } else {
                    MacTodoListColumn(selection: $selection)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal:   .opacity.combined(with: .move(edge: .leading))
                        ))
                }
            }
            .animation(reduceMotion ? .linear(duration: 0.1) : DS.Motion.settle, value: mode)
        }
        .navigationTitle("Today")
        // Vend context-sensitive ⌘N action to the menu bar
        .focusedValue(\.todayNewItemAction, {
            switch mode {
            case .plan: NotificationCenter.default.post(name: .locaAddBlock, object: nil)
            case .list: NotificationCenter.default.post(name: .locaFocusQuickAdd, object: nil)
            }
        })
    }
}
