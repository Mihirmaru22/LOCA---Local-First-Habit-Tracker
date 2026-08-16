import SwiftUI
import SwiftData
import Combine

// MARK: - MacSteveJobsTrinityView (The Steve Jobs Sovereign Edition)

/// The Steve Jobs Edition: Collapsing all fragmented tabs and sidebars into
/// a single, uncompromised 3-dimensional glass monolith:
/// - ⚡ PULSE (What is NOW · Zen Focus Sprint Cockpit)
/// - ☀️ ORBIT (What is TODAY · Unified Day Stream of Habits + Tasks + Evening Reflection)
/// - 🏔️ APEX (Who you BECOME · 3D Himalayan Topography + Work Milestones + Life Blueprint)
struct MacSteveJobsTrinityView: View {

    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var vaultManager = LocaVaultAuthManager.shared

    // Queries
    @Query(filter: #Predicate<HabitBoard> { $0.archivedAt == nil }, sort: \HabitBoard.createdAt)
    private var habits: [HabitBoard]

    @Query(filter: #Predicate<TodoItem> { $0.completedAt == nil && $0.archivedAt == nil }, sort: \TodoItem.priority, order: .reverse)
    private var activeTodos: [TodoItem]

    @Query(sort: \JournalNote.date, order: .reverse)
    private var notes: [JournalNote]

    @Query private var treks: [TrekRecord]

    // Active Trinity Layer (1 = Pulse, 2 = Orbit, 3 = Apex)
    @State private var activeTrinityLayer: TrinityLayer = .pulse
    @State private var showSettingsModal: Bool = false

    // Pulse Timer State
    @State private var timerSecondsRemaining: Int = 25 * 60
    @State private var isTimerRunning: Bool = false
    @State private var selectedFocusTodo: TodoItem? = nil
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Orbit State
    @State private var newQuickTodoTitle: String = ""
    @State private var eveningReflectionText: String = ""
    @State private var selectedMoodTag: String = "⚡ Peak Energy"

    // Settings Storage
    @AppStorage("mac_selected_accent_index") private var selectedAccentIndex: Int = 0

    enum TrinityLayer: String, CaseIterable, Identifiable {
        case pulse = "Pulse"
        case orbit = "Orbit"
        case apex  = "Apex"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .pulse: return "bolt.fill"
            case .orbit: return "sun.max.fill"
            case .apex:  return "mountain.2.fill"
            }
        }

        var subtitle: String {
            switch self {
            case .pulse: return "WHAT IS NOW · Deep Focus Sprint"
            case .orbit: return "WHAT IS TODAY · The Unified Day Stream"
            case .apex:  return "WHO YOU BECOME · 3D Summits & Life Blueprint"
            }
        }
    }

    private var accentColor: Color {
        let palette: [Color] = [
            Color(red: 0.95, green: 0.77, blue: 0.25), // Golden Amber
            Color(red: 0.35, green: 0.65, blue: 0.95), // Alpine Cyan
            Color(red: 0.85, green: 0.40, blue: 0.40), // Crimson Energy
            Color(red: 0.45, green: 0.85, blue: 0.55), // Emerald Growth
            Color(red: 0.75, green: 0.55, blue: 0.95), // Royal Amethyst
            Color(red: 0.95, green: 0.55, blue: 0.35), // Solar Orange
            Color(red: 0.30, green: 0.85, blue: 0.80), // Glacier Teal
            Color(red: 0.80, green: 0.80, blue: 0.85), // Platinum Titanium
        ]
        if selectedAccentIndex >= 0 && selectedAccentIndex < palette.count {
            return palette[selectedAccentIndex]
        }
        return palette[0]
    }

    var body: some View {
        ZStack {
            // Dark Titanium Background
            Color(red: 0.05, green: 0.05, blue: 0.07)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Top Minimalist Floating Trinity Monolith Bar
                trinityTopBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                Divider()

                // Main Active Layer Canvas
                Group {
                    switch activeTrinityLayer {
                    case .pulse:
                        pulseLayerCanvas
                    case .orbit:
                        orbitLayerCanvas
                    case .apex:
                        apexLayerCanvas
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showSettingsModal) {
            MacSettingsView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .onReceive(timer) { _ in
            guard isTimerRunning else { return }
            if timerSecondsRemaining > 0 {
                timerSecondsRemaining -= 1
            } else {
                isTimerRunning = false
                PlutoSoundEngine.shared.play(.timerComplete)
                PlutoNotificationManager.shared.scheduleFocusCompletionNotification(tag: "Deep Focus Sprint", seconds: 0, mode: "Pomodoro")
            }
        }
    }

    // MARK: - Top Trinity Monolith Bar
    private var trinityTopBar: some View {
        HStack(spacing: 16) {

            // Apple & Pluto Sovereign Emblem
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accentColor)

                Text("PLUTO")
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundStyle(DS.Color.textPrimary)

                Text("STEVE JOBS EDITION")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.2))
                    .foregroundStyle(accentColor)
                    .clipShape(Capsule())
            }

            Spacer()

            // Center Trinity Segmented Switcher (Pulse · Orbit · Apex)
            HStack(spacing: 6) {
                ForEach(TrinityLayer.allCases) { layer in
                    let isSelected = activeTrinityLayer == layer

                    Button {
                        activeTrinityLayer = layer
                        PlutoSoundEngine.shared.play(.tabSwitch)
                        Haptics.impact(.light)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: layer.icon)
                                .font(.system(size: 11, weight: .bold))
                            Text(layer.rawValue.uppercased())
                                .font(.system(size: 11, weight: isSelected ? .heavy : .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(isSelected ? accentColor : Color.clear)
                        .foregroundStyle(isSelected ? .black : DS.Color.textSecondary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color.black.opacity(0.4), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))

            Spacer()

            // Settings Trigger
            Button {
                showSettingsModal = true
                PlutoSoundEngine.shared.play(.tabSwitch)
                Haptics.impact(.light)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(6)
                    .background(DS.Color.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .help("Preferences (⌘,)")
        }
    }

    // MARK: =====================================================================
    // MARK: ⚡ LAYER 1 · PULSE (What is NOW · Zen Focus Sprint Cockpit)
    // MARK: =====================================================================

    private var pulseLayerCanvas: some View {
        VStack(spacing: 28) {
            Spacer()

            // Glowing Focus Sprint Dial
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 8)
                    .frame(width: 240, height: 240)

                Circle()
                    .trim(from: 0.0, to: CGFloat(timerSecondsRemaining) / CGFloat(25 * 60))
                    .stroke(
                        LinearGradient(
                            colors: [accentColor, Color(red: 0.95, green: 0.55, blue: 0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: timerSecondsRemaining)
                    .shadow(color: accentColor.opacity(isTimerRunning ? 0.6 : 0.15), radius: 16)

                VStack(spacing: 4) {
                    Text(formatTime(seconds: timerSecondsRemaining))
                        .font(.system(size: 48, weight: .heavy, design: .monospaced))
                        .foregroundStyle(DS.Color.textPrimary)

                    Text(isTimerRunning ? "FOCUS SPRINT IN PROGRESS" : "READY FOR DEEP WORK")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundStyle(accentColor)
                }
            }

            // Target Leverage Task Card
            VStack(spacing: 8) {
                Text("CURRENT HIGHEST-LEVERAGE OBJECTIVE:")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)

                if let todo = selectedFocusTodo ?? activeTodos.first {
                    HStack(spacing: 12) {
                        Button {
                            todo.completedAt = Date()
                            try? modelContext.save()
                            PlutoSoundEngine.shared.play(.checkmark)
                            Haptics.notify(.success)
                        } label: {
                            Image(systemName: "circle")
                                .font(.system(size: 16))
                                .foregroundStyle(accentColor)
                        }
                        .buttonStyle(.plain)

                        Text(todo.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)

                        Spacer()

                        Text("PRIORITY 1")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accentColor.opacity(0.2))
                            .foregroundStyle(accentColor)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .frame(maxWidth: 540)
                    .background(Color(red: 0.10, green: 0.10, blue: 0.14), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentColor.opacity(0.3), lineWidth: 1))
                } else {
                    Text("No active tasks in queue. You are 100% clear.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DS.Color.textSecondary)
                        .padding(.vertical, 8)
                }
            }

            // Sprint Control Actions
            HStack(spacing: 16) {
                Button {
                    isTimerRunning.toggle()
                    if isTimerRunning {
                        PlutoSoundEngine.shared.play(.timerStart)
                    } else {
                        PlutoSoundEngine.shared.play(.tabSwitch)
                    }
                    Haptics.impact(.rigid)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        Text(isTimerRunning ? "Pause Sprint" : "Ignite 25m Focus")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(accentColor)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
                    .shadow(color: accentColor.opacity(0.4), radius: 10)
                }
                .buttonStyle(.plain)

                Button {
                    isTimerRunning = false
                    timerSecondsRemaining = 25 * 60
                    PlutoSoundEngine.shared.play(.tabSwitch)
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .bold))
                        .padding(12)
                        .background(Color.white.opacity(0.08), in: Circle())
                        .foregroundStyle(DS.Color.textPrimary)
                }
                .buttonStyle(.plain)
                .help("Reset Timer")
            }

            Spacer()
        }
        .padding(24)
    }

    private func formatTime(seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    // MARK: =====================================================================
    // MARK: ☀️ LAYER 2 · ORBIT (What is TODAY · The Unified Day Stream)
    // MARK: =====================================================================

    private var orbitLayerCanvas: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // 1. Morning Habit Ignition Stream
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("MORNING HABIT IGNITION", systemImage: "flame.fill")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundStyle(accentColor)
                        Spacer()
                        Text("\(habits.count) Daily Keystone Habits")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Color.textTertiary)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(habits) { habit in
                                habitPillCard(habit: habit)
                            }
                        }
                    }
                }

                Divider()

                // 2. Midday Execution: Active Priorities
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("MIDDAY EXECUTION · PRIORITY BACKLOG", systemImage: "bolt.horizontal.fill")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color(red: 0.85, green: 0.40, blue: 0.40))
                        Spacer()
                        Text("\(activeTodos.count) Tasks Remaining")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Color.textTertiary)
                    }

                    // Quick Add Input
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(accentColor)

                        TextField("Quick-capture new task for today…", text: $newQuickTodoTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .onSubmit {
                                saveQuickTodo()
                            }

                        if !newQuickTodoTitle.isEmpty {
                            Button("Add") {
                                saveQuickTodo()
                            }
                            .font(.system(size: 11, weight: .bold))
                            .buttonStyle(.plain)
                            .foregroundStyle(accentColor)
                        }
                    }
                    .padding(12)
                    .background(Color(red: 0.10, green: 0.10, blue: 0.13), in: RoundedRectangle(cornerRadius: 8))

                    // Task List
                    VStack(spacing: 6) {
                        ForEach(activeTodos) { todo in
                            HStack(spacing: 12) {
                                Button {
                                    todo.completedAt = Date()
                                    try? modelContext.save()
                                    PlutoSoundEngine.shared.play(.checkmark)
                                    Haptics.notify(.success)
                                } label: {
                                    Image(systemName: "circle")
                                        .font(.system(size: 14))
                                        .foregroundStyle(DS.Color.textTertiary)
                                }
                                .buttonStyle(.plain)

                                Text(todo.title)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(DS.Color.textPrimary)

                                Spacer()

                                Button {
                                    selectedFocusTodo = todo
                                    activeTrinityLayer = .pulse
                                    PlutoSoundEngine.shared.play(.timerStart)
                                } label: {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(accentColor)
                                }
                                .buttonStyle(.plain)
                                .help("Focus on this task in Pulse")
                            }
                            .padding(10)
                            .background(Color(red: 0.08, green: 0.08, blue: 0.11), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }

                Divider()

                // 3. Evening Reflection Sanctum
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("EVENING REFLECTION SANCTUM", systemImage: "book.closed.fill")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color(red: 0.75, green: 0.55, blue: 0.95))
                        Spacer()
                        Text("Touch ID Protected")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(red: 0.75, green: 0.55, blue: 0.95))
                    }

                    // Mood tags
                    HStack(spacing: 8) {
                        let tags = ["⚡ Peak Energy", "🎯 High Focus", "🌿 Calibrated", "🔋 Recharging"]
                        ForEach(tags, id: \.self) { tag in
                            Button {
                                selectedMoodTag = tag
                                PlutoSoundEngine.shared.play(.tabSwitch)
                            } label: {
                                Text(tag)
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(selectedMoodTag == tag ? Color(red: 0.75, green: 0.55, blue: 0.95).opacity(0.25) : Color.white.opacity(0.06))
                                    .foregroundStyle(selectedMoodTag == tag ? Color(red: 0.75, green: 0.55, blue: 0.95) : DS.Color.textSecondary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    TextEditor(text: $eveningReflectionText)
                        .font(.system(size: 12))
                        .frame(height: 90)
                        .padding(8)
                        .background(Color(red: 0.08, green: 0.08, blue: 0.11), in: RoundedRectangle(cornerRadius: 8))

                    HStack {
                        Spacer()
                        Button("Commit Evening Note") {
                            guard !eveningReflectionText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            let note = JournalNote(date: Date(), title: selectedMoodTag, text: eveningReflectionText, kind: .dailyNote)
                            modelContext.insert(note)
                            try? modelContext.save()
                            eveningReflectionText = ""
                            PlutoSoundEngine.shared.play(.checkmark)
                            Haptics.notify(.success)
                        }
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.75, green: 0.55, blue: 0.95))
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(28)
            .frame(maxWidth: 860)
        }
    }

    private func habitPillCard(habit: HabitBoard) -> some View {
        Button {
            PlutoSoundEngine.shared.play(.checkmark)
            Haptics.impact(.medium)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(accentColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text(habit.name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DS.Color.textPrimary)
                    Text("Streak: \(habit.currentStreak)d")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.10, green: 0.10, blue: 0.14), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(accentColor.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func saveQuickTodo() {
        let trimmed = newQuickTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let todo = TodoItem(title: trimmed, priority: 1)
        modelContext.insert(todo)
        try? modelContext.save()
        newQuickTodoTitle = ""
        PlutoSoundEngine.shared.play(.checkmark)
        Haptics.impact(.light)
    }

    // MARK: =====================================================================
    // MARK: 🏔️ LAYER 3 · APEX (Who You BECOME · 3D Summits & Life Blueprint)
    // MARK: =====================================================================

    private var apexLayerCanvas: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {

                // 1. 3D Himalayan Topographic Peak Banner
                HStack(spacing: 18) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.30, green: 0.85, blue: 0.80), Color.teal],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("3D HIMALAYAN EXPEDITION ATLAS")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color(red: 0.30, green: 0.85, blue: 0.80))

                        Text("Kedarkantha & Nanda Devi Peaks")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)

                        Text("Physical high-altitude summits, GPS altitude telemetry, and National Geographic gold passports.")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.Color.textSecondary)
                    }

                    Spacer()

                    Button("Open 3D Atlas") {
                        PlutoSoundEngine.shared.play(.summitPassport)
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.30, green: 0.85, blue: 0.80))
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .buttonStyle(.plain)
                }
                .padding(20)
                .background(Color(red: 0.08, green: 0.08, blue: 0.11), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.30, green: 0.85, blue: 0.80).opacity(0.3), lineWidth: 1))

                Divider()

                // 2. Strategic Work Milestones
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("STRATEGIC DELIVERABLES ROADMAP", systemImage: "briefcase.fill")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundStyle(accentColor)
                        Spacer()
                    }

                    MacAuditView()
                        .frame(height: 380)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Spacer(minLength: 40)
            }
            .padding(28)
            .frame(maxWidth: 860)
        }
    }
}
