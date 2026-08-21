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

    var index: Int {
        switch self {
        case .plan: return 0
        case .list: return 1
        case .time: return 2
        }
    }

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

// MARK: - Transition Direction

private enum TransitionDirection {
    case forward
    case backward
}

// MARK: - MacTodoContentColumn

/// Middle column of the Mac layout for the Today (Todo) section.
/// Features a floating macOS Liquid Glass pill switcher with live telemetry,
/// ultra-thin materials, and seamless direction-aware spatial transitions.
struct MacTodoContentColumn: View {

    @Binding var selection: TodoItem?
    @AppStorage("mac_today_submode") private var modeString: String = "Plan"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: [SortDescriptor(\TodoItem.createdAt)], animation: .default)
    private var allItems: [TodoItem]

    @State private var transitionDirection: TransitionDirection = .forward
    @State private var lastModeIndex: Int = 0

    private var openItems: [TodoItem] {
        allItems.filter { !$0.isArchived && $0.parentID == nil && !$0.isCompleted }
    }

    private var scheduledItems: [TodoItem] {
        allItems.filter { !$0.isArchived && $0.parentID == nil && $0.startTime != nil }
    }

    private var mode: Binding<TodoMode> {
        Binding(
            get: { TodoMode(rawValue: modeString) ?? .plan },
            set: { newMode in
                let newIndex = newMode.index
                transitionDirection = newIndex >= lastModeIndex ? .forward : .backward
                lastModeIndex = newIndex
                modeString = newMode.rawValue
            }
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

            // Direction-Aware Spatial Glide Viewport (Plan ↔ List ↔ Time)
            ZStack {
                if mode.wrappedValue == .plan {
                    MacDayPlannerColumn(selection: $selection)
                        .transition(contentTransition)
                } else if mode.wrappedValue == .list {
                    MacTodoListColumn(selection: $selection)
                        .transition(contentTransition)
                } else {
                    MacTimeView()
                        .transition(contentTransition)
                }
            }
            .clipped()
            .animation(
                reduceMotion ? .linear(duration: 0.12) : .spring(response: 0.30, dampingFraction: 0.82),
                value: mode.wrappedValue
            )
        }
        .navigationTitle("Today")
        .onAppear {
            lastModeIndex = (TodoMode(rawValue: modeString) ?? .plan).index
        }
    }

    // MARK: - Spatial Content Transition

    private var contentTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        switch transitionDirection {
        case .forward:
            return .asymmetric(
                insertion: .offset(x: 28).combined(with: .opacity),
                removal: .offset(x: -28).combined(with: .opacity)
            )
        case .backward:
            return .asymmetric(
                insertion: .offset(x: -28).combined(with: .opacity),
                removal: .offset(x: 28).combined(with: .opacity)
            )
        }
    }

    @Namespace private var glassPillNamespace
    @State private var hoveredMode: TodoMode? = nil
    @State private var mouseLocation: CGPoint = .zero
    @State private var isHoveringCapsule: Bool = false

    // MARK: - Apple Liquid Glass Capsule Switcher (with Optical Refraction & Hover Glint)

    private var glassPillarSwitcher: some View {
        HStack(spacing: 3) {
            ForEach(Array(TodoMode.allCases.enumerated()), id: \.element.id) { index, m in
                let isSelected = mode.wrappedValue == m
                let isHovered = hoveredMode == m

                Button {
                    guard mode.wrappedValue != m else { return }
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        mode.wrappedValue = m
                    }
                    Haptics.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: m.icon)
                            .font(.system(size: 11.5, weight: isSelected ? .bold : .semibold))
                            .foregroundStyle(isSelected ? Color.white : (isHovered ? Color.white : Color.white.opacity(0.68)))
                            .scaleEffect(isHovered ? 1.08 : 1.0)
                            .animation(.spring(response: 0.2), value: isHovered)

                        Text(m.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                            .foregroundStyle(isSelected ? Color.white : (isHovered ? Color.white : Color.white.opacity(0.68)))

                        // Badge Counts
                        if m == .plan && !scheduledItems.isEmpty {
                            Text("\(scheduledItems.count)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(isSelected ? Color.white : (isHovered ? Color.white : Color.white.opacity(0.60)))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color.white.opacity(0.22) : (isHovered ? Color.white.opacity(0.14) : Color.white.opacity(0.08)))
                                )
                        } else if m == .list && !openItems.isEmpty {
                            Text("\(openItems.count)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(isSelected ? Color.white : (isHovered ? Color.white : Color.white.opacity(0.60)))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color.white.opacity(0.22) : (isHovered ? Color.white.opacity(0.14) : Color.white.opacity(0.08)))
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6.5)
                    .contentShape(Capsule())
                    .background {
                        if isSelected {
                            ZStack {
                                // Active glass thumb fill with depth
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(isHovered ? 0.34 : 0.28),
                                                Color.white.opacity(isHovered ? 0.22 : 0.18)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                // Chromatic optical refraction rim (VisionOS / Apple physical lens)
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            stops: [
                                                .init(color: Color.white.opacity(isHovered ? 0.70 : 0.55), location: 0.0),
                                                .init(color: Color.cyan.opacity(isHovered ? 0.28 : 0.18), location: 0.28),
                                                .init(color: Color(red: 0.9, green: 0.4, blue: 0.9).opacity(isHovered ? 0.25 : 0.14), location: 0.65),
                                                .init(color: Color.white.opacity(0.12), location: 1.0)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: isHovered ? 1.1 : 0.85
                                    )
                            }
                            .shadow(color: Color.black.opacity(isHovered ? 0.35 : 0.22), radius: isHovered ? 6 : 4, x: 0, y: isHovered ? 2 : 1.5)
                            .matchedGeometryEffect(id: "activeAppleGlassPill", in: glassPillNamespace)
                        } else if isHovered {
                            // Inactive tab hover glass spotlight
                            ZStack {
                                Capsule()
                                    .fill(Color.white.opacity(0.11))

                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.35),
                                                Color.white.opacity(0.06)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 0.75
                                    )
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        }
                    }
                    .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                        hoveredMode = hovering ? m : nil
                    }
                    if hovering {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                .help("\(m.subtitle)  ⌘\(index + 1)")
            }
        }
        .padding(3.5)
        .background(
            ZStack {
                // Outer dark translucent glass track
                Capsule()
                    .fill(Color.white.opacity(0.09))

                // Track specular stroke
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.22),
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

    private func cycleMode(delta: Int) {
        let all = TodoMode.allCases
        if let idx = all.firstIndex(of: mode.wrappedValue) {
            let nextIdx = (idx + delta + all.count) % all.count
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                mode.wrappedValue = all[nextIdx]
                Haptics.impact(.light)
            }
        }
    }
}
