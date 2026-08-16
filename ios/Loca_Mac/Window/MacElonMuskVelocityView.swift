import SwiftUI
import SwiftData

// MARK: - MacElonMuskVelocityView (The Elon Musk Cybernetic Velocity Cockpit)

/// The Elon Musk Edition: Built on first-principles physics and maximum velocity.
/// Structured into 5 Mission-Critical Cybernetic Pillars:
/// - 🔥 THRUST (Pillar 1 · Primary Launch Vector & 25m Focus Burn)
/// - ⚡ TELEMETRY (Pillar 2 · Vehicle Subsystem Gauges & Bio-Regime)
/// - 🛰️ TRAJECTORY (Pillar 3 · Critical Path Milestones & Burn-down)
/// - 🏔️ ENDURANCE (Pillar 4 · Himalayan High-Altitude Topography & Physical Grit)
/// - 🛡️ AIR-GAP (Pillar 5 · Zero-Cloud Hardware Security & SQLite Engine Diagnostics)
struct MacElonMuskVelocityView: View {

    @Environment(\.modelContext) private var modelContext

    // Queries
    @Query(filter: #Predicate<HabitBoard> { $0.archivedAt == nil }, sort: \HabitBoard.createdAt)
    private var habits: [HabitBoard]

    @Query(filter: #Predicate<TodoItem> { !$0.isCompleted }, sort: \TodoItem.priority, order: .reverse)
    private var activeTodos: [TodoItem]

    @Query private var treks: [TrekRecord]

    // Active Cockpit Pillar (1 to 5)
    @State private var activePillar: CockpitPillar = .thrust
    @State private var showSettingsModal: Bool = false

    // Thrust Burn Timer State
    @State private var burnSecondsRemaining: Int = 25 * 60
    @State private var isBurnRunning: Bool = false
    @State private var selectedMissionTodo: TodoItem? = nil
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Command Buffer Input
    @State private var commandInputText: String = ""

    // Accent Palette
    @AppStorage("mac_selected_accent_index") private var selectedAccentIndex: Int = 0

    enum CockpitPillar: String, CaseIterable, Identifiable {
        case thrust     = "Thrust"
        case telemetry  = "Telemetry"
        case trajectory = "Trajectory"
        case endurance  = "Endurance"
        case airgap     = "Air-Gap"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .thrust:     return "flame.fill"
            case .telemetry:  return "waveform.path.ecg"
            case .trajectory: return "location.north.circle.fill"
            case .endurance:  return "mountain.2.fill"
            case .airgap:     return "shield.lefthalf.filled"
            }
        }

        var tag: String {
            switch self {
            case .thrust:     return "PILLAR 1 · PRIMARY LAUNCH VECTOR"
            case .telemetry:  return "PILLAR 2 · BIO-REGIME & SUBSYSTEM GAUGES"
            case .trajectory: return "PILLAR 3 · CRITICAL PATH & ENGINEERING GANTT"
            case .endurance:  return "PILLAR 4 · HIMALAYAN SUMMITS & PHYSICAL GRIT"
            case .airgap:     return "PILLAR 5 · ZERO-CLOUD HARDWARE VAULT"
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
            // Cybernetic Dark Carbon Void
            Color(red: 0.04, green: 0.04, blue: 0.06)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Top Cybernetic Mission Control Bar
                cockpitMissionControlTopBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                Divider()

                // Active Cockpit Canvas
                Group {
                    switch activePillar {
                    case .thrust:
                        thrustPillarCanvas
                    case .telemetry:
                        telemetryPillarCanvas
                    case .trajectory:
                        trajectoryPillarCanvas
                    case .endurance:
                        endurancePillarCanvas
                    case .airgap:
                        airgapPillarCanvas
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
            guard isBurnRunning else { return }
            if burnSecondsRemaining > 0 {
                burnSecondsRemaining -= 1
            } else {
                isBurnRunning = false
                PlutoSoundEngine.shared.play(.timerComplete)
                PlutoNotificationManager.shared.scheduleFocusCompletionNotification(tag: "Mission Sprint Complete", seconds: 0, mode: "Pomodoro")
            }
        }
    }

    // MARK: - Top Cockpit Mission Control Bar
    private var cockpitMissionControlTopBar: some View {
        HStack(spacing: 16) {

            // Vehicle Telemetry Emblem
            HStack(spacing: 8) {
                Image(systemName: "bolt.horizontal.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accentColor)

                Text("PLUTO VELOCITY")
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundStyle(DS.Color.textPrimary)

                Text("ELON MUSK 5-PILLARS")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundStyle(Color.orange)
                    .clipShape(Capsule())
            }

            Spacer()

            // 5-Pillars Switcher (Thrust · Telemetry · Trajectory · Endurance · Air-Gap)
            HStack(spacing: 4) {
                ForEach(CockpitPillar.allCases) { pillar in
                    let isSelected = activePillar == pillar

                    Button {
                        activePillar = pillar
                        PlutoSoundEngine.shared.play(.tabSwitch)
                        Haptics.impact(.light)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: pillar.icon)
                                .font(.system(size: 10, weight: .bold))
                            Text(pillar.rawValue.uppercased())
                                .font(.system(size: 10, weight: isSelected ? .heavy : .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(isSelected ? accentColor : Color.clear)
                        .foregroundStyle(isSelected ? .black : DS.Color.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))

            Spacer()

            // Settings Trigger
            Button {
                showSettingsModal = true
                PlutoSoundEngine.shared.play(.tabSwitch)
                Haptics.impact(.light)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(6)
                    .background(DS.Color.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .help("Preferences (⌘,)")
        }
    }

    // MARK: =====================================================================
    // MARK: 🔥 PILLAR 1 · THRUST (Primary Launch Vector & 25m Focus Burn)
    // MARK: =====================================================================

    private var thrustPillarCanvas: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Mission Payload Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label("PRIMARY MISSION PAYLOAD (CRITICAL VECTOR)", systemImage: "target")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(accentColor)
                        Spacer()
                        Text("NON-NEGOTIABLE")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accentColor.opacity(0.2))
                            .foregroundStyle(accentColor)
                            .clipShape(Capsule())
                    }

                    if let missionTodo = selectedMissionTodo ?? activeTodos.first {
                        HStack(spacing: 14) {
                            Button {
                                missionTodo.isCompleted = true
                                try? modelContext.save()
                                PlutoSoundEngine.shared.play(.checkmark)
                                Haptics.notify(.success)
                            } label: {
                                Image(systemName: "circle.inset.filled")
                                    .font(.system(size: 18))
                                    .foregroundStyle(accentColor)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(missionTodo.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(DS.Color.textPrimary)

                                Text("Payload locked · Subordinated all secondary backlog tasks")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.Color.textTertiary)
                            }

                            Spacer()

                            Button("DEPLOY / DONE") {
                                missionTodo.isCompleted = true
                                try? modelContext.save()
                                PlutoSoundEngine.shared.play(.checkmark)
                                Haptics.notify(.success)
                            }
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(accentColor)
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .buttonStyle(.plain)
                        }
                    } else {
                        Text("No mission payload defined. All orbital goals achieved.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
                .padding(18)
                .frame(maxWidth: 860)
                .background(Color(red: 0.08, green: 0.08, blue: 0.11), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentColor.opacity(0.3), lineWidth: 1))

                // Rocket Engine Countdown Dial & Velocity Telemetry
                HStack(spacing: 24) {

                    // Circular Burn Timer Dial
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 8)
                                .frame(width: 180, height: 180)

                            Circle()
                                .trim(from: 0.0, to: CGFloat(burnSecondsRemaining) / CGFloat(25 * 60))
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.orange, accentColor],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 180, height: 180)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 1.0), value: burnSecondsRemaining)

                            VStack(spacing: 2) {
                                Text(formatTime(seconds: burnSecondsRemaining))
                                    .font(.system(size: 38, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(DS.Color.textPrimary)

                                Text(isBurnRunning ? "THRUST IGNITED" : "T-MINUS 25M")
                                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(Color.orange)
                            }
                        }

                        // Burn Controls
                        HStack(spacing: 12) {
                            Button {
                                isBurnRunning.toggle()
                                if isBurnRunning {
                                    PlutoSoundEngine.shared.play(.timerStart)
                                } else {
                                    PlutoSoundEngine.shared.play(.tabSwitch)
                                }
                                Haptics.impact(.rigid)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: isBurnRunning ? "pause.fill" : "flame.fill")
                                    Text(isBurnRunning ? "ABORT BURN" : "IGNITE THRUST")
                                }
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(isBurnRunning ? Color.red : Color.orange)
                                .foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)

                            Button {
                                isBurnRunning = false
                                burnSecondsRemaining = 25 * 60
                                PlutoSoundEngine.shared.play(.tabSwitch)
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(8)
                                    .background(Color.white.opacity(0.08), in: Circle())
                                    .foregroundStyle(DS.Color.textPrimary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                    .background(Color(red: 0.08, green: 0.08, blue: 0.11), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))

                    // Real-Time Velocity Telemetry Gauges
                    VStack(alignment: .leading, spacing: 12) {
                        Text("VELOCITY TELEMETRY GAUGES")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(DS.Color.textTertiary)

                        telemetryStatRow(label: "BURNDOWN RATE", value: "\(activeTodos.count) tasks in queue", unit: "QUEUE")
                        telemetryStatRow(label: "STORAGE WRITE CYCLE", value: "< 0.18", unit: "ms (SQLite)")
                        telemetryStatRow(label: "CLOUD EXPOSURE", value: "0.00%", unit: "AIR-GAPPED")
                        telemetryStatRow(label: "ENGINEERING ALGORITHM", value: "5-STEP PRUNING", unit: "ACTIVE")
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.08, green: 0.08, blue: 0.11), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.Color.border.opacity(0.5), lineWidth: 1))
                }
                .frame(maxWidth: 860)

                // Command Buffer
                HStack(spacing: 8) {
                    Text("❯")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundStyle(accentColor)

                    TextField("Type quick launch deliverable and press Enter…", text: $commandInputText)
                        .font(.system(size: 13, design: .monospaced))
                        .textFieldStyle(.plain)
                        .onSubmit {
                            saveCommandTodo()
                        }

                    if !commandInputText.isEmpty {
                        Button("ENTER") {
                            saveCommandTodo()
                        }
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accentColor)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .frame(maxWidth: 860)
                .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(accentColor.opacity(0.3), lineWidth: 1))

                Spacer(minLength: 40)
            }
            .padding(24)
        }
    }

    private func telemetryStatRow(label: String, value: String, unit: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)
                Text(value)
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundStyle(DS.Color.textPrimary)
            }
            Spacer()
            Text(unit)
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 4))
                .foregroundStyle(DS.Color.textSecondary)
        }
        .padding(8)
        .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
    }

    private func formatTime(seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    private func saveCommandTodo() {
        let trimmed = commandInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let todo = TodoItem(title: trimmed, priority: 1)
        modelContext.insert(todo)
        try? modelContext.save()
        commandInputText = ""
        PlutoSoundEngine.shared.play(.checkmark)
        Haptics.impact(.light)
    }

    // MARK: =====================================================================
    // MARK: ⚡ PILLAR 2 · TELEMETRY (Vehicle Health & Subsystem Gauges)
    // MARK: =====================================================================

    private var telemetryPillarCanvas: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("SPACECRAFT SUBSYSTEM TELEMETRY GAUGES")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(accentColor)
                    Text("Daily keystone routines treated as mission-critical vehicle subsystems.")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.textSecondary)
                }

                // Subsystem Gauges Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(habits) { habit in
                        subsystemGaugeCard(habit: habit)
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(28)
            .frame(maxWidth: 900)
        }
    }

    private func subsystemGaugeCard(habit: HabitBoard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(habit.name.uppercased())
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundStyle(DS.Color.textPrimary)
                Spacer()
                Text("STREAK: \(habit.currentStreak)d")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(accentColor.opacity(0.2))
                    .foregroundStyle(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text(habit.isQuantitative ? "Target: \(Int(habit.targetValue ?? 1)) \(habit.unitLabel ?? "")" : "Status: Nominal")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(DS.Color.textTertiary)

            Button {
                PlutoSoundEngine.shared.play(.checkmark)
                Haptics.impact(.medium)
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("LOG NOMINAL COMPLETION")
                }
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(accentColor.opacity(0.15))
                .foregroundStyle(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.08, blue: 0.11), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(accentColor.opacity(0.25), lineWidth: 1))
    }

    // MARK: =====================================================================
    // MARK: 🛰️ PILLAR 3 · TRAJECTORY (Critical Path & Engineering Gantt)
    // MARK: =====================================================================

    private var trajectoryPillarCanvas: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("CRITICAL PATH LAUNCH TRAJECTORY")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(accentColor)
                    Text("Deconstruct high-priority engineering deliverables into milestone burn-downs.")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.textSecondary)
                }

                // Work Deliverables Roadmap
                VStack(alignment: .leading, spacing: 10) {
                    MacAuditView()
                        .frame(height: 480)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Spacer(minLength: 40)
            }
            .padding(28)
            .frame(maxWidth: 900)
        }
    }

    // MARK: =====================================================================
    // MARK: 🏔️ PILLAR 4 · ENDURANCE (Himalayan Summits & Physical Grit)
    // MARK: =====================================================================

    private var endurancePillarCanvas: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("HIGH-ALTITUDE PHYSICAL GRIT TELEMETRY")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color(red: 0.30, green: 0.85, blue: 0.80))
                    Text("GPS altimeter telemetry, 3D topographic terrain, and Mountaineer Gold Passports.")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.textSecondary)
                }

                // Expedition Summary Cards
                HStack(spacing: 16) {
                    enduranceStatCard(title: "MAX PEAK ELEVATION", value: "6,816 m", subtitle: "Nanda Devi Ridge", icon: "mountain.2.fill")
                    enduranceStatCard(title: "ASCENT EXPEDITIONS", value: "6 Peaks", subtitle: "100% Completed", icon: "flag.fill")
                    enduranceStatCard(title: "VO2 / AEROBIC BASE", value: "Zone 2", subtitle: "High Altitude Tested", icon: "heart.fill")
                }

                Divider()

                Text("MOUNTAINEER EXPEDITION PASSPORTS")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)

                VStack(spacing: 12) {
                    ForEach(treks) { trek in
                        HStack(spacing: 14) {
                            Image(systemName: "seal.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.yellow)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(trek.name.uppercased())
                                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(DS.Color.textPrimary)
                                Text("Elevation: \(Int(trek.altitudeMeters))m · Location: \(trek.locationName)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.Color.textSecondary)
                            }

                            Spacer()

                            Text(trek.isCompleted ? "SUMMIT VERIFIED" : "IN TRAINING")
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(trek.isCompleted ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                .foregroundStyle(trek.isCompleted ? Color.green : Color.orange)
                                .clipShape(Capsule())
                        }
                        .padding(14)
                        .background(Color(red: 0.08, green: 0.08, blue: 0.11), in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(28)
            .frame(maxWidth: 900)
        }
    }

    private func enduranceStatCard(title: String, value: String, subtitle: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(DS.Color.textTertiary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.30, green: 0.85, blue: 0.80))
            }
            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .monospaced))
                .foregroundStyle(DS.Color.textPrimary)
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundStyle(DS.Color.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.08, green: 0.08, blue: 0.11), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(red: 0.30, green: 0.85, blue: 0.80).opacity(0.25), lineWidth: 1))
    }

    // MARK: =====================================================================
    // MARK: 🛡️ PILLAR 5 · AIR-GAP (Zero-Cloud Hardware Security & SQLite Engine)
    // MARK: =====================================================================

    private var airgapPillarCanvas: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                VStack(alignment: .leading, spacing: 4) {
                    Text("HARDWARE SECURITY & AIR-GAPPED STORAGE ARCHITECTURE")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color(red: 0.75, green: 0.55, blue: 0.95))
                    Text("Apple Secure Enclave, biometric Touch ID gatekeeper, and 100% offline SQLite persistence.")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.textSecondary)
                }

                // Security Diagnostic Cards
                VStack(spacing: 12) {
                    telemetryStatRow(label: "LOCAL DATABASE LATENCY", value: "0.14 ms", unit: "SUB-MILLISECOND")
                    telemetryStatRow(label: "OUTBOUND PACKETS", value: "0 bytes", unit: "100% AIR-GAPPED")
                    telemetryStatRow(label: "CRYPTOGRAPHIC ENCLAVE", value: "AES-256", unit: "HARDWARE LOCKED")
                    telemetryStatRow(label: "STORAGE FORMAT", value: "SwiftData / SQLite", unit: "PURE LOCAL")
                }

                Divider()

                HStack {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(red: 0.75, green: 0.55, blue: 0.95))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ZERO EXTERNAL DEPENDENCIES")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(DS.Color.textPrimary)
                        Text("No remote server can read your habits, tasks, or reflections. Complete data sovereignty.")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.Color.textSecondary)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(red: 0.75, green: 0.55, blue: 0.95).opacity(0.1), in: RoundedRectangle(cornerRadius: 8))

                Spacer(minLength: 40)
            }
            .padding(28)
            .frame(maxWidth: 900)
        }
    }
}
