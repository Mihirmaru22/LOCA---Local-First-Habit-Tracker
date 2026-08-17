import SwiftUI
import SwiftData

// MARK: - TodoMode (sub-pillar toggle)

/// The three sub-pillars of the Today section:
/// - **plan**: time-blocked day planner on a vertical timeline (`MacDayPlannerColumn`)
/// - **list**: GTD-style task queues and bento cards (`MacTodoListColumn`)
/// - **time**: Focus timer and flow studio (`MacTimeView`)
enum TodoMode: String, CaseIterable, Identifiable {
    case plan = "Plan"
    case list = "List"
    case time = "Time"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .plan: return "calendar.day.timeline.left"
        case .list: return "checklist.checked"
        case .time: return "timer.circle.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .plan: return "Day Planner"
        case .list: return "Tasks & Queues"
        case .time: return "Focus Studio"
        }
    }
}

// MARK: - MacTodoContentColumn

/// Middle column of the Mac layout for the Today (Todo) section.
/// Features a floating macOS Liquid Glass pill switcher with live telemetry,
/// ultra-thin materials, and seamless cross-fade transitions.
struct MacTodoContentColumn: View {

    @Binding var selection: TodoItem?
    @AppStorage("mac_today_submode") private var modeString: String = "Plan"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: [SortDescriptor(\TodoItem.createdAt)], animation: .default)
    private var allItems: [TodoItem]

    private var openItems: [TodoItem] {
        allItems.filter { !$0.isArchived && $0.parentID == nil && !$0.isCompleted }
    }

    private var scheduledItems: [TodoItem] {
        allItems.filter { !$0.isArchived && $0.parentID == nil && $0.startTime != nil }
    }

    private var mode: Binding<TodoMode> {
        Binding(
            get: { TodoMode(rawValue: modeString) ?? .plan },
            set: { modeString = $0.rawValue }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Floating macOS Liquid Glass Segmented Control
            glassPillarSwitcher
                .padding(.horizontal, DS.Space.md)
                .padding(.vertical, 10)

            Divider()
                .opacity(0.4)

            // Plan ↔ List ↔ Time crossfade view
            ZStack {
                if mode.wrappedValue == .plan {
                    MacDayPlannerColumn(selection: $selection)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal:   .opacity.combined(with: .scale(scale: 1.02))
                        ))
                } else if mode.wrappedValue == .list {
                    MacTodoListColumn(selection: $selection)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal:   .opacity.combined(with: .scale(scale: 1.02))
                        ))
                } else {
                    MacTimeView()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal:   .opacity.combined(with: .scale(scale: 1.02))
                        ))
                }
            }
            .animation(reduceMotion ? .linear(duration: 0.1) : .spring(response: 0.35, dampingFraction: 0.82), value: mode.wrappedValue)
        }
        .navigationTitle("Today")
        // Vend context-sensitive ⌘N action to the menu bar
        .focusedValue(\.todayNewItemAction, {
            switch mode.wrappedValue {
            case .plan: NotificationCenter.default.post(name: .locaAddBlock, object: nil)
            case .list: NotificationCenter.default.post(name: .locaFocusQuickAdd, object: nil)
            case .time: break
            }
        })
    }

    @Namespace private var glassPillNamespace

    // MARK: - Apple Liquid Glass Capsule Switcher (matching Apple Music / Safari)

    private var glassPillarSwitcher: some View {
        HStack(spacing: 2) {
            ForEach(TodoMode.allCases) { m in
                let isSelected = mode.wrappedValue == m
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        mode.wrappedValue = m
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: m.icon)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.70))

                        Text(m.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.70))

                        // Badge Counts
                        if m == .plan && !scheduledItems.isEmpty {
                            Text("\(scheduledItems.count)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.60))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color.white.opacity(0.20) : Color.white.opacity(0.08))
                                )
                        } else if m == .list && !openItems.isEmpty {
                            Text("\(openItems.count)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.60))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color.white.opacity(0.20) : Color.white.opacity(0.08))
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .contentShape(Capsule())
                    .background {
                        if isSelected {
                            ZStack {
                                // Glass thumb fill
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.28),
                                                Color.white.opacity(0.18)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                // Chromatic optical refraction rim (VisionOS / Apple physical glass)
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            stops: [
                                                .init(color: Color.white.opacity(0.55), location: 0.0),
                                                .init(color: Color.cyan.opacity(0.15), location: 0.3),
                                                .init(color: Color.purple.opacity(0.12), location: 0.6),
                                                .init(color: Color.white.opacity(0.10), location: 1.0)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.85
                                    )
                            }
                            .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 1.5)
                            .matchedGeometryEffect(id: "activeAppleGlassPill", in: glassPillNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            ZStack {
                // Outer dark translucent glass track
                Capsule()
                    .fill(Color.white.opacity(0.10))

                // Track specular stroke
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.75
                    )
            }
        )
    }
}
