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

    @Query(filter: #Predicate<TodoItem> { !$0.isArchived && $0.parentID == nil && !$0.isCompleted })
    private var openItems: [TodoItem]

    @Query(filter: #Predicate<TodoItem> { !$0.isArchived && $0.parentID == nil && $0.startTime != nil })
    private var scheduledItems: [TodoItem]

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

    // MARK: - Glass Pillar Switcher

    private var glassPillarSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(TodoMode.allCases) { m in
                let isSelected = mode.wrappedValue == m
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        mode.wrappedValue = m
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: m.icon)
                            .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? Color.accentColor : DS.Color.textSecondary)

                        Text(m.rawValue)
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? DS.Color.textPrimary : DS.Color.textSecondary)

                        // Badge Counts
                        if m == .plan && !scheduledItems.isEmpty {
                            Text("\(scheduledItems.count)")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(isSelected ? Color.accentColor : DS.Color.textTertiary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(isSelected ? Color.accentColor.opacity(0.15) : Color.white.opacity(0.06), in: Capsule())
                        } else if m == .list && !openItems.isEmpty {
                            Text("\(openItems.count)")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(isSelected ? Color.accentColor : DS.Color.textTertiary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(isSelected ? Color.accentColor.opacity(0.15) : Color.white.opacity(0.06), in: Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        ZStack {
                            if isSelected {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.35), .white.opacity(0.05)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 11))
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.20), .white.opacity(0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.8
                )
        )
    }
}
