import SwiftUI
import SwiftData
import Combine

// MARK: - TimeToolMode

enum TimeToolMode: String, CaseIterable, Identifiable {
    case pomodoro  = "Pomodoro"
    case stopwatch = "Stopwatch"
    case countdown = "Countdown"
    case analytics = "Analytics"
    case settings  = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pomodoro:  return "flame.fill"
        case .stopwatch: return "stopwatch.fill"
        case .countdown: return "timer"
        case .analytics: return "chart.bar.fill"
        case .settings:  return "gearshape.fill"
        }
    }
}

// MARK: - LapRecord

struct LapRecord: Identifiable {
    let id = UUID()
    let lapNumber: Int
    let lapTime: TimeInterval
    let overallTime: TimeInterval
}

// MARK: - FocusSessionLog

struct FocusSessionLog: Identifiable {
    let id = UUID()
    let tag: String
    let durationMinutes: Int
    let completedAt: Date
    let mode: String
}

// MARK: - MacTimeView (Cinematic Flow Studio with Refined Settings)

struct MacTimeView: View {

    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var soundEngine = AmbientSoundEngine.shared
    @ObservedObject private var powerManager = LocaPowerManager.shared

    @AppStorage("mac_selected_accent_index") private var selectedAccentIndex: Int = 0

    // Navigation & View Mode
    @State private var activeTool: TimeToolMode = .pomodoro
    @State private var isFullscreenClock: Bool = false

    // 1. Pomodoro Settings & State
    @AppStorage("time_focus_duration") private var focusDurationMinutes: Int = 25
    @AppStorage("time_short_break") private var shortBreakMinutes: Int = 5
    @AppStorage("time_long_break") private var longBreakMinutes: Int = 15
    @AppStorage("time_target_pomodoros") private var targetPomodoros: Int = 4
    @AppStorage("time_auto_start_breaks") private var autoStartBreaks: Bool = false
    @AppStorage("time_auto_start_focus") private var autoStartFocus: Bool = false
    @AppStorage("time_sound_alert_on_finish") private var soundAlertOnFinish: Bool = true

    @State private var pomodoroStage: PomodoroStage = .focus
    @State private var pomodoroRemaining: Int = 25 * 60
    @State private var isPomodoroRunning: Bool = false
    @State private var completedPomodoros: Int = 2
    @State private var selectedSessionTag: String = "Deep Work"

    // 2. Stopwatch Settings & State
    @State private var stopwatchElapsed: TimeInterval = 0
    @State private var isStopwatchRunning: Bool = false
    @State private var laps: [LapRecord] = []
    @State private var lastLapTime: TimeInterval = 0
    @State private var stopwatchTag: String = "Engineering"
    @State private var stopwatchMemo: String = ""

    // 3. Countdown Settings & State
    @AppStorage("time_default_countdown_minutes") private var defaultCountdownMinutes: Int = 15
    @State private var countdownDuration: Int = 15 * 60
    @State private var countdownRemaining: Int = 15 * 60
    @State private var isCountdownRunning: Bool = false
    @State private var countdownTag: String = "Sprint"

    // 4. Historical Session Logs
    @State private var sessionLogs: [FocusSessionLog] = [
        FocusSessionLog(tag: "Deep Work", durationMinutes: 25, completedAt: Calendar.current.date(byAdding: .hour, value: -3, to: .now) ?? .now, mode: "Pomodoro"),
        FocusSessionLog(tag: "Engineering", durationMinutes: 50, completedAt: Calendar.current.date(byAdding: .hour, value: -2, to: .now) ?? .now, mode: "Stopwatch"),
        FocusSessionLog(tag: "Writing", durationMinutes: 25, completedAt: Calendar.current.date(byAdding: .hour, value: -1, to: .now) ?? .now, mode: "Pomodoro"),
        FocusSessionLog(tag: "Strategy", durationMinutes: 45, completedAt: Calendar.current.date(byAdding: .minute, value: -30, to: .now) ?? .now, mode: "Countdown")
    ]

    // Tickers
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var secondTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    enum PomodoroStage: String, CaseIterable {
        case focus      = "Focus Sprint"
        case shortBreak = "Short Rest"
        case longBreak  = "Deep Recovery"

        var color: Color {
            switch self {
            case .focus:      return DS.Color.streak
            case .shortBreak: return DS.Color.success
            case .longBreak:  return DS.Color.active
            }
        }
    }

    private var accentColor: Color {
        ColorPalette[selectedAccentIndex]
    }

    private static let sessionTags = ["Deep Work", "Engineering", "Writing", "Learning", "Strategy", "Creative", "Design"]

    var body: some View {
        ZStack {
            if isFullscreenClock {
                fullscreenClockCanvas
                    .transition(.opacity)
            } else {
                cinematicHUDStudio
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.background)
        .animation(.easeInOut(duration: 0.22), value: isFullscreenClock)
        .onReceive(secondTimer) { _ in
            handleSecondTick()
        }
        .onReceive(timer) { _ in
            handleStopwatchTick()
        }
        .onChange(of: isTimerActive) { _, active in
            if active {
                powerManager.beginFocusSleepAssertion()
            } else {
                powerManager.endFocusSleepAssertion()
            }
        }
        .onDisappear {
            powerManager.endFocusSleepAssertion()
        }
    }

    // MARK: - Main Studio Body

    private var cinematicHUDStudio: some View {
        VStack(spacing: 0) {

            // Top Header Bar
            topHeaderBar
            Divider()

            // Main Active Content
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xl) {

                    if activeTool == .settings {
                        // ⚙️ Refined Time Settings View
                        refinedTimeSettingsView
                    } else if activeTool == .analytics {
                        // 📊 Dedicated Analytics Dashboard
                        analyticsDashboardView
                    } else {
                        // 1. Center Cinematic Hero HUD
                        heroCinematicHUD

                        // 2. High-Fidelity Ambient Audio Dropdown Console
                        highFidelitySoundscapeCard

                        // 3. Tool Contextual Canvas (Laps for Stopwatch)
                        toolContextualCanvas
                    }

                    Spacer(minLength: DS.Space.xxxl)
                }
                .padding(DS.Space.xl)
                .frame(maxWidth: 960, alignment: .leading)
            }
        }
    }

    // MARK: - Top Header Bar

    private var topHeaderBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle().fill(activeToolColor).frame(width: 7, height: 7)
                    Text("TIME & FLOW STUDIO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .tracking(0.6)
                }

                Text(activeTool.rawValue)
                    .font(DS.Text.title)
                    .fontWeight(.bold)
                    .foregroundStyle(DS.Color.textPrimary)
            }

            Spacer()

            // Tool Mode Selector (Pomodoro | Stopwatch | Countdown | Analytics | Settings)
            HStack(spacing: 4) {
                ForEach(TimeToolMode.allCases) { tool in
                    Button {
                        activeTool = tool
                        Haptics.impact(.light)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tool.icon)
                                .font(.system(size: 11))
                            Text(tool.rawValue)
                                .font(.system(size: 11, weight: activeTool == tool ? .bold : .medium))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(
                            activeTool == tool
                                ? DS.Color.surfaceRecessed
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(activeTool == tool ? DS.Color.textPrimary : DS.Color.textSecondary)
                }
            }
            .padding(3)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 8))

            // Power & Sleep Assertion Badges
            if powerManager.isLowPowerMode {
                HStack(spacing: 4) {
                    Image(systemName: "battery.50percent")
                    Text("Low Power Mode")
                }
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.yellow)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.12), in: Capsule())
                .help("macOS Low Power Mode active — rendering frame rates optimized")
            }

            if powerManager.hasActiveSleepAssertion {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                    Text("Uninterrupted Focus")
                }
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(DS.Color.success)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(DS.Color.success.opacity(0.12), in: Capsule())
                .help("IOKit sleep assertion active — Mac will not sleep during focus sprint")
            }

            // Fullscreen Launcher Button (hidden when in Settings)
            if activeTool != .settings {
                Button {
                    withAnimation { isFullscreenClock = true }
                    Haptics.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                        Text("Fullscreen Clock")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Open Fullscreen Focus Clock (⎋ Esc to exit)")
            }
        }
        .padding(.horizontal, DS.Space.xl)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.surface)
    }

    private var activeToolColor: Color {
        switch activeTool {
        case .pomodoro:  return DS.Color.streak
        case .stopwatch: return DS.Color.active
        case .countdown: return ColorPalette[3]
        case .analytics: return DS.Color.success
        case .settings:  return DS.Color.textSecondary
        }
    }

    // MARK: - 1. Hero Cinematic HUD Card

    private var heroCinematicHUD: some View {
        VStack(spacing: DS.Space.xl) {

            // Ambient Stage Indicator
            HStack(spacing: 8) {
                Circle().fill(activeToolColor).frame(width: 8, height: 8)
                Text(activeTool == .pomodoro ? pomodoroStage.rawValue.uppercased() : activeTool.rawValue.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(activeToolColor)
                    .tracking(1.0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(activeToolColor.opacity(0.12), in: Capsule())

            // Center Illuminated Digits
            VStack(spacing: 6) {
                Text(currentFullscreenTimeText)
                    .font(.system(size: 82, weight: .bold, design: .monospaced))
                    .foregroundStyle(DS.Color.textPrimary)
                    .shadow(color: activeToolColor.opacity(isTimerActive ? 0.35 : 0), radius: 26)

                Text("\"The secret of getting ahead is getting started.\"")
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(DS.Color.textTertiary)
            }

            // Radial Fluid Progress Line
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(DS.Color.surfaceRecessed).frame(height: 6)
                    Capsule().fill(activeToolColor).frame(width: geo.size.width * currentFullscreenProgress, height: 6)
                }
            }
            .frame(height: 6)
            .frame(maxWidth: 440)

            // Floating Glass Action Dock
            HStack(spacing: 14) {
                Button {
                    toggleActiveTimer()
                    Haptics.impact(.light)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isTimerActive ? "pause.fill" : "play.fill")
                        Text(isTimerActive ? "Pause" : "Start Focus")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(activeToolColor, in: Capsule())
                }
                .buttonStyle(.plain)

                if activeTool == .pomodoro || activeTool == .countdown {
                    Button {
                        if activeTool == .pomodoro { pomodoroRemaining += 5 * 60 }
                        else { countdownRemaining += 5 * 60; countdownDuration += 5 * 60 }
                        Haptics.impact(.light)
                    } label: {
                        Text("+5 Min")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(DS.Color.surfaceRecessed, in: Capsule())
                    }
                    .buttonStyle(.plain)
                } else if activeTool == .stopwatch {
                    Button {
                        recordLap()
                        Haptics.impact(.light)
                    } label: {
                        Text("Record Lap")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(DS.Color.surfaceRecessed, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(!isStopwatchRunning)
                }

                // Ambient Audio Quick Toggle
                Button {
                    soundEngine.togglePlay()
                    Haptics.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: soundEngine.isPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        Text(soundEngine.selectedSound)
                            .lineLimit(1)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(soundEngine.isPlaying ? DS.Color.success : DS.Color.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(DS.Color.surfaceRecessed, in: Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    resetActiveTimer()
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Color.textSecondary)
                        .padding(10)
                        .background(DS.Color.surfaceRecessed, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, DS.Space.xs)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Space.xl)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
    }

    // MARK: - 2. High-Fidelity Ambient Audio Dropdown Console

    private var highFidelitySoundscapeCard: some View {
        HStack(spacing: DS.Space.md) {
            HStack(spacing: 10) {
                Image(systemName: "headphones")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.active)
                    .frame(width: 32, height: 32)
                    .background(DS.Color.active.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("AMBIENT FOCUS AUDIO")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                        .tracking(0.6)

                    Text(soundEngine.isPlaying ? "Playing High-Fidelity Audio" : "Ambient Soundscape")
                        .font(.system(size: 11))
                        .foregroundStyle(soundEngine.isPlaying ? DS.Color.success : DS.Color.textSecondary)
                }
            }

            Spacer()

            // Soundscape Dropdown Menu
            Menu {
                ForEach(AmbientSoundEngine.availableSounds, id: \.name) { item in
                    Button {
                        soundEngine.setSound(item.name)
                        if !soundEngine.isPlaying { soundEngine.start() }
                    } label: {
                        Label(item.name, systemImage: item.icon)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: currentSoundIcon)
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Color.active)

                    Text(soundEngine.selectedSound)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DS.Color.textPrimary)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Color.textTertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
            }
            // Spatial Audio Toggle Pill
            Button {
                soundEngine.toggleSpatialAudio()
                Haptics.impact(.light)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "headphones")
                        .font(.system(size: 10))
                    Text(soundEngine.isSpatialAudio ? "3D Spatial" : "Stereo")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(soundEngine.isSpatialAudio ? DS.Color.textPrimary : DS.Color.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(soundEngine.isSpatialAudio ? DS.Color.surfaceRecessed : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(DS.Color.border.opacity(soundEngine.isSpatialAudio ? 0.6 : 0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(soundEngine.isSpatialAudio ? "Apple Spatial Audio 3D HRTF soundstage active" : "Standard stereo playback")

            // Master Volume Slider
            HStack(spacing: 6) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(DS.Color.textTertiary)
                Slider(value: $soundEngine.volume, in: 0.1...1.0)
                    .frame(width: 80)
                    .controlSize(.mini)
                Image(systemName: "speaker.3.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(DS.Color.textTertiary)
            }

            // Play / Stop Button
            Button {
                soundEngine.togglePlay()
                Haptics.impact(.light)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: soundEngine.isPlaying ? "pause.fill" : "play.fill")
                    Text(soundEngine.isPlaying ? "Stop Audio" : "Play Sound")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(soundEngine.isPlaying ? DS.Color.danger : DS.Color.success, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DS.Space.lg)
        .padding(.vertical, DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
    }

    private var currentSoundIcon: String {
        AmbientSoundEngine.availableSounds.first(where: { $0.name == soundEngine.selectedSound })?.icon ?? "music.note"
    }

    // MARK: - 3. Tool Contextual Canvas (Laps only)

    @ViewBuilder
    private var toolContextualCanvas: some View {
        switch activeTool {
        case .pomodoro, .countdown, .analytics, .settings:
            EmptyView()

        case .stopwatch:
            if !laps.isEmpty {
                lapsTableCard(width: .infinity, maxHeight: 200)
            }
        }
    }

    // MARK: =====================================================================
    // MARK: ⚙️ 4. REFINED TIME SETTINGS VIEW (Improved Original Layout)
    // MARK: =====================================================================

    private var refinedTimeSettingsView: some View {
        VStack(alignment: .leading, spacing: DS.Space.lg) {

            // Section 1: Pomodoro Interval Durations (with Color Accents & Steppers)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(DS.Color.streak)
                        Text("POMODORO INTERVAL DURATIONS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .tracking(0.8)
                    }
                    Spacer()
                }
                .padding(DS.Space.md)

                Divider()

                settingsRowWithPill(
                    title: "Focus Sprint Duration",
                    pillText: "\(focusDurationMinutes) min",
                    icon: "bolt.fill",
                    color: DS.Color.streak
                ) {
                    Stepper("", value: $focusDurationMinutes, in: 5...120, step: 5)
                        .labelsHidden()
                        .onChange(of: focusDurationMinutes) { _, val in
                            if pomodoroStage == .focus { pomodoroRemaining = val * 60 }
                        }
                }

                Divider()

                settingsRowWithPill(
                    title: "Short Rest Duration",
                    pillText: "\(shortBreakMinutes) min",
                    icon: "cup.and.saucer.fill",
                    color: DS.Color.success
                ) {
                    Stepper("", value: $shortBreakMinutes, in: 1...30, step: 1)
                        .labelsHidden()
                        .onChange(of: shortBreakMinutes) { _, val in
                            if pomodoroStage == .shortBreak { pomodoroRemaining = val * 60 }
                        }
                }

                Divider()

                settingsRowWithPill(
                    title: "Deep Recovery (Long Break)",
                    pillText: "\(longBreakMinutes) min",
                    icon: "bed.double.fill",
                    color: DS.Color.active
                ) {
                    Stepper("", value: $longBreakMinutes, in: 5...60, step: 5)
                        .labelsHidden()
                        .onChange(of: longBreakMinutes) { _, val in
                            if pomodoroStage == .longBreak { pomodoroRemaining = val * 60 }
                        }
                }

                Divider()

                settingsRowWithPill(
                    title: "Long Break Cycle Interval",
                    pillText: "Every \(targetPomodoros) pomodoros",
                    icon: "arrow.triangle.2.circlepath",
                    color: ColorPalette[3]
                ) {
                    Stepper("", value: $targetPomodoros, in: 2...8, step: 1)
                        .labelsHidden()
                }
            }
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))

            // Section 2: Automation & Alerts
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "gearshape.2.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 0.20, green: 0.65, blue: 0.95))
                        Text("AUTOMATION & ALERTS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .tracking(0.8)
                    }
                    Spacer()
                }
                .padding(DS.Space.md)

                Divider()

                settingsToggleRow(
                    title: "Auto-start Rest Cycles",
                    subtitle: "Automatically begin break when focus sprint ends",
                    isOn: $autoStartBreaks
                )

                Divider()

                settingsToggleRow(
                    title: "Auto-start Next Focus Sprint",
                    subtitle: "Automatically resume next sprint when rest interval ends",
                    isOn: $autoStartFocus
                )

                Divider()

                settingsToggleRow(
                    title: "Sound Alert on Interval Completion",
                    subtitle: "Play acoustic chime when timer reaches 00:00",
                    isOn: $soundAlertOnFinish
                )
            }
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))

            // Section 3: Countdown Default Duration
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(ColorPalette[3])
                        Text("COUNTDOWN DEFAULT DURATION")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .tracking(0.8)
                    }
                    Spacer()
                }
                .padding(DS.Space.md)

                Divider()

                settingsRowWithPill(
                    title: "Default Countdown Length",
                    pillText: "\(defaultCountdownMinutes) min",
                    icon: "hourglass",
                    color: ColorPalette[3]
                ) {
                    Stepper("", value: $defaultCountdownMinutes, in: 1...180, step: 5)
                        .labelsHidden()
                        .onChange(of: defaultCountdownMinutes) { _, val in
                            countdownDuration = val * 60
                            countdownRemaining = val * 60
                        }
                }
            }
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))

            // Section 4: Session Intent Categories
            VStack(alignment: .leading, spacing: DS.Space.md) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(DS.Color.active)
                        Text("SESSION INTENT CATEGORIES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(DS.Color.textTertiary)
                            .tracking(0.8)
                    }
                    Spacer()
                }

                Text("Select the default active category used when logging focus sessions:")
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.textSecondary)

                HStack(spacing: 8) {
                    ForEach(Self.sessionTags, id: \.self) { tag in
                        Button {
                            selectedSessionTag = tag
                            Haptics.impact(.light)
                        } label: {
                            HStack(spacing: 5) {
                                if selectedSessionTag == tag {
                                    Image(systemName: "checkmark").font(.system(size: 9, weight: .bold))
                                }
                                Text(tag)
                            }
                            .font(.system(size: 11, weight: selectedSessionTag == tag ? .bold : .medium))
                            .foregroundStyle(selectedSessionTag == tag ? .white : DS.Color.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedSessionTag == tag ? accentColor : DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(DS.Space.lg)
            .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
        }
    }

    private func settingsRowWithPill<Content: View>(title: String, pillText: String, icon: String, color: Color, @ViewBuilder control: () -> Content) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Color.textPrimary)

            Spacer()

            Text(pillText)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(color.opacity(0.12), in: Capsule())

            control()
        }
        .padding(DS.Space.md)
    }

    private func settingsToggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DS.Color.textPrimary)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Color.textTertiary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding(DS.Space.md)
    }

    // MARK: - 📊 Dedicated Analytics View

    private var analyticsDashboardView: some View {
        VStack(spacing: DS.Space.lg) {
            weeklyChartCard
            sessionLogsCard
        }
    }

    // MARK: =====================================================================
    // MARK: 🌌 FULLSCREEN FOCUS CLOCK CANVAS
    // MARK: =====================================================================

    private var fullscreenClockCanvas: some View {
        VStack(spacing: DS.Space.xxl) {

            // Fullscreen Top Header
            HStack {
                HStack(spacing: 8) {
                    Circle().fill(activeToolColor).frame(width: 8, height: 8)
                    Text(activeTool == .pomodoro ? pomodoroStage.rawValue.uppercased() : activeTool.rawValue.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(activeToolColor)
                        .tracking(1.0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(activeToolColor.opacity(0.12), in: Capsule())

                Spacer()

                // Soundscape quick switcher in fullscreen
                Menu {
                    ForEach(AmbientSoundEngine.availableSounds, id: \.name) { s in
                        Button(s.name) { soundEngine.setSound(s.name) }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: soundEngine.isPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        Text(soundEngine.selectedSound)
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(soundEngine.isPlaying ? DS.Color.success : DS.Color.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DS.Color.surface, in: Capsule())
                }
                .menuStyle(.borderlessButton)

                Button {
                    withAnimation { isFullscreenClock = false }
                    Haptics.impact(.light)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                        Text("Exit (Esc)")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DS.Color.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DS.Color.surface, in: Capsule())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, DS.Space.xxl)
            .padding(.top, DS.Space.xl)

            Spacer()

            // 120pt Glowing Monospaced Digits
            VStack(spacing: DS.Space.lg) {
                Text(currentFullscreenTimeText)
                    .font(.system(size: 120, weight: .bold, design: .monospaced))
                    .foregroundStyle(DS.Color.textPrimary)
                    .shadow(color: activeToolColor.opacity(isTimerActive ? 0.3 : 0), radius: 30)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(DS.Color.surfaceRecessed).frame(height: 8)
                        Capsule().fill(activeToolColor).frame(width: geo.size.width * currentFullscreenProgress, height: 8)
                    }
                }
                .frame(height: 8)
                .frame(maxWidth: 500)
            }

            Spacer()

            // Floating Controls
            HStack(spacing: 18) {
                Button {
                    toggleActiveTimer()
                    Haptics.impact(.light)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isTimerActive ? "pause.fill" : "play.fill")
                        Text(isTimerActive ? "Pause" : "Start Focus")
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(activeToolColor, in: Capsule())
                }
                .buttonStyle(.plain)

                if activeTool == .pomodoro || activeTool == .countdown {
                    Button {
                        if activeTool == .pomodoro { pomodoroRemaining += 5 * 60 }
                        else { countdownRemaining += 5 * 60; countdownDuration += 5 * 60 }
                        Haptics.impact(.light)
                    } label: {
                        Text("+5 Min")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DS.Color.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(DS.Color.surface, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    resetActiveTimer()
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.Color.textSecondary)
                        .padding(14)
                        .background(DS.Color.surface, in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, DS.Space.xxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.background)
    }

    private var currentFullscreenTimeText: String {
        switch activeTool {
        case .pomodoro:  return formatMMSS(pomodoroRemaining)
        case .stopwatch: return formatStopwatch(stopwatchElapsed)
        case .countdown: return formatMMSS(countdownRemaining)
        case .analytics: return "3.5h"
        case .settings:  return "00:00"
        }
    }

    private var currentFullscreenProgress: Double {
        switch activeTool {
        case .pomodoro:  return pomodoroProgress
        case .countdown: return countdownProgress
        case .stopwatch: return min(1.0, stopwatchElapsed / 3600.0)
        case .analytics: return 0.85
        case .settings:  return 0.0
        }
    }

    private var isTimerActive: Bool {
        switch activeTool {
        case .pomodoro:  return isPomodoroRunning
        case .stopwatch: return isStopwatchRunning
        case .countdown: return isCountdownRunning
        case .analytics, .settings: return false
        }
    }

    private func toggleActiveTimer() {
        switch activeTool {
        case .pomodoro:
            isPomodoroRunning.toggle()
            if isPomodoroRunning {
                PlutoNotificationManager.shared.scheduleFocusCompletionNotification(
                    tag: selectedSessionTag,
                    seconds: pomodoroRemaining,
                    mode: pomodoroStage == .focus ? "Pomodoro" : "Break"
                )
            } else {
                PlutoNotificationManager.shared.cancelFocusCompletionNotification()
            }
        case .stopwatch:
            isStopwatchRunning.toggle()
        case .countdown:
            isCountdownRunning.toggle()
            if isCountdownRunning {
                PlutoNotificationManager.shared.scheduleFocusCompletionNotification(
                    tag: countdownTag,
                    seconds: countdownRemaining,
                    mode: "Countdown"
                )
            } else {
                PlutoNotificationManager.shared.cancelFocusCompletionNotification()
            }
        case .analytics, .settings: break
        }
    }

    private func resetActiveTimer() {
        PlutoNotificationManager.shared.cancelFocusCompletionNotification()
        switch activeTool {
        case .pomodoro:  resetPomodoro()
        case .stopwatch: resetStopwatch()
        case .countdown: resetCountdown()
        case .analytics, .settings: break
        }
    }

    // MARK: - Reusable Cards

    private func lapsTableCard(width: CGFloat, maxHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack {
                Text("RECORDED LAPS").font(.system(size: 9, weight: .bold)).foregroundStyle(DS.Color.textTertiary).tracking(0.6)
                Spacer()
                Text("\(laps.count) total").font(.system(size: 10, weight: .semibold)).foregroundStyle(DS.Color.textSecondary)
            }

            ScrollView {
                VStack(spacing: 5) {
                    ForEach(laps.reversed()) { lap in
                        let isFastest = lap.id == fastestLapID
                        let isSlowest = lap.id == slowestLapID && laps.count > 1

                        HStack {
                            Text("Lap \(lap.lapNumber)").font(.system(size: 11, weight: .bold)).foregroundStyle(DS.Color.textPrimary)
                            Spacer()
                            Text("+\(formatStopwatch(lap.lapTime))").font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(isFastest ? DS.Color.success : (isSlowest ? DS.Color.danger : DS.Color.textPrimary))
                            Text(formatStopwatch(lap.overallTime)).font(.system(size: 11, design: .monospaced)).foregroundStyle(DS.Color.textTertiary)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(
                            isFastest ? DS.Color.success.opacity(0.1) : (isSlowest ? DS.Color.danger.opacity(0.08) : DS.Color.surface)
                        )
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding(DS.Space.md)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
        .frame(width: width)
        .frame(maxHeight: maxHeight)
    }

    private var fastestLapID: UUID? {
        laps.min(by: { $0.lapTime < $1.lapTime })?.id
    }

    private var slowestLapID: UUID? {
        laps.max(by: { $0.lapTime < $1.lapTime })?.id
    }

    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack {
                Text("7-DAY FOCUS DISTRIBUTION").font(.system(size: 9, weight: .bold)).foregroundStyle(DS.Color.textTertiary).tracking(0.6)
                Spacer()
                Text("Avg: 3.8 hrs/day").font(.system(size: 10, weight: .semibold)).foregroundStyle(DS.Color.textSecondary)
            }

            HStack(alignment: .bottom, spacing: 12) {
                dayBarColumn(day: "Mon", hours: 4.2, target: 5.0)
                dayBarColumn(day: "Tue", hours: 3.5, target: 5.0)
                dayBarColumn(day: "Wed", hours: 5.1, target: 5.0)
                dayBarColumn(day: "Thu", hours: 4.8, target: 5.0)
                dayBarColumn(day: "Fri", hours: 3.2, target: 5.0)
                dayBarColumn(day: "Sat", hours: 2.0, target: 5.0)
                dayBarColumn(day: "Sun (Today)", hours: 3.5, target: 5.0, isToday: true)
            }
            .frame(height: 110)
            .padding(.top, 8)
        }
        .padding(DS.Space.lg)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
    }

    private var sessionLogsCard: some View {
        VStack(alignment: .leading, spacing: DS.Space.md) {
            HStack {
                Text("TODAY'S LOGGED FOCUS BLOCKS").font(.system(size: 9, weight: .bold)).foregroundStyle(DS.Color.textTertiary).tracking(0.6)
                Spacer()
                Text("\(sessionLogs.count) sessions").font(.system(size: 10)).foregroundStyle(DS.Color.textSecondary)
            }

            VStack(spacing: 6) {
                ForEach(sessionLogs) { log in
                    HStack(spacing: 12) {
                        Circle().fill(DS.Color.success).frame(width: 8, height: 8)
                        Text(log.tag).font(.system(size: 12, weight: .semibold)).foregroundStyle(DS.Color.textPrimary)
                        Text("(\(log.mode))").font(.system(size: 10)).foregroundStyle(DS.Color.textTertiary)
                        Spacer()
                        Text("\(log.durationMinutes)m sprint").font(.system(size: 11, weight: .bold)).foregroundStyle(DS.Color.active)
                        Text(log.completedAt.formatted(.dateTime.hour().minute())).font(.system(size: 10)).foregroundStyle(DS.Color.textSecondary)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(DS.Color.surfaceRecessed, in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(DS.Space.lg)
        .background(DS.Color.surface, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: DS.Radius.card).stroke(DS.Color.border.opacity(0.4), lineWidth: 1))
    }

    private func dayBarColumn(day: String, hours: Double, target: Double, isToday: Bool = false) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isToday ? accentColor : DS.Color.surfaceRecessed)
                        .frame(height: max(10, geo.size.height * CGFloat(hours / target)))
                }
            }

            Text("\(hours, specifier: "%.1f")h").font(.system(size: 9, weight: .bold)).foregroundStyle(isToday ? accentColor : DS.Color.textSecondary)
            Text(day).font(.system(size: 9)).foregroundStyle(DS.Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Logic & Handlers

    private var countdownProgress: Double {
        guard countdownDuration > 0 else { return 0 }
        return max(0, min(1.0, 1.0 - (Double(countdownRemaining) / Double(countdownDuration))))
    }

    private func resetCountdown() {
        isCountdownRunning = false
        countdownRemaining = countdownDuration
    }

    private var pomodoroProgress: Double {
        let total = Double(stageSeconds(pomodoroStage))
        guard total > 0 else { return 0 }
        return max(0, min(1.0, 1.0 - (Double(pomodoroRemaining) / total)))
    }

    private func stageSeconds(_ stage: PomodoroStage) -> Int {
        switch stage {
        case .focus:      return max(1, focusDurationMinutes) * 60
        case .shortBreak: return max(1, shortBreakMinutes) * 60
        case .longBreak:  return max(1, longBreakMinutes) * 60
        }
    }

    private func handleSecondTick() {
        if isPomodoroRunning && pomodoroRemaining > 0 {
            pomodoroRemaining -= 1
        } else if isPomodoroRunning && pomodoroRemaining == 0 {
            completePomodoroSession()
        }

        if isCountdownRunning && countdownRemaining > 0 {
            countdownRemaining -= 1
        } else if isCountdownRunning && countdownRemaining == 0 {
            isCountdownRunning = false
            let minutes = max(1, countdownDuration / 60)
            sessionLogs.insert(FocusSessionLog(tag: countdownTag, durationMinutes: minutes, completedAt: .now, mode: "Countdown"), at: 0)
            PlutoNotificationManager.shared.deliverImmediateFocusComplete(
                tag: countdownTag,
                durationMinutes: minutes,
                mode: "Countdown"
            )
            Haptics.impact(.rigid)
        }
    }

    private func completePomodoroSession() {
        isPomodoroRunning = false
        if pomodoroStage == .focus {
            completedPomodoros += 1
            sessionLogs.insert(FocusSessionLog(tag: selectedSessionTag, durationMinutes: max(1, focusDurationMinutes), completedAt: .now, mode: "Pomodoro"), at: 0)

            // Track telemetry event
            PlutoTelemetryEngine.shared.trackFocusSessionCompleted(
                durationSeconds: max(1, focusDurationMinutes) * 60,
                soundName: soundEngine.selectedSound,
                taskTitle: selectedSessionTag
            )

            // Deliver celebratory notification with stats (A5)
            PlutoNotificationManager.shared.deliverImmediateFocusComplete(
                tag: selectedSessionTag,
                durationMinutes: max(1, focusDurationMinutes),
                mode: "Pomodoro"
            )

            let cycleTarget = max(1, targetPomodoros)
            pomodoroStage = (completedPomodoros % cycleTarget == 0) ? .longBreak : .shortBreak
            pomodoroRemaining = stageSeconds(pomodoroStage)
            if autoStartBreaks {
                isPomodoroRunning = true
                PlutoNotificationManager.shared.scheduleFocusCompletionNotification(
                    tag: "Rest Interval",
                    seconds: pomodoroRemaining,
                    mode: "Break"
                )
            }
        } else {
            pomodoroStage = .focus
            pomodoroRemaining = stageSeconds(pomodoroStage)
            if autoStartFocus {
                isPomodoroRunning = true
                PlutoNotificationManager.shared.scheduleFocusCompletionNotification(
                    tag: selectedSessionTag,
                    seconds: pomodoroRemaining,
                    mode: "Pomodoro"
                )
            }
        }
        Haptics.impact(.rigid)
    }

    private func handleStopwatchTick() {
        if isStopwatchRunning {
            stopwatchElapsed += 0.1
        }
    }

    private func resetPomodoro() {
        PlutoNotificationManager.shared.cancelFocusCompletionNotification()
        isPomodoroRunning = false
        pomodoroRemaining = stageSeconds(pomodoroStage)
    }

    private func resetStopwatch() {
        if stopwatchElapsed > 5 {
            sessionLogs.insert(FocusSessionLog(tag: stopwatchTag, durationMinutes: max(1, Int(stopwatchElapsed / 60)), completedAt: .now, mode: "Stopwatch"), at: 0)
        }
        isStopwatchRunning = false
        stopwatchElapsed = 0
        laps.removeAll()
        lastLapTime = 0
    }

    private func recordLap() {
        let lapTime = stopwatchElapsed - lastLapTime
        lastLapTime = stopwatchElapsed
        let record = LapRecord(
            lapNumber: laps.count + 1,
            lapTime: max(0, lapTime),
            overallTime: stopwatchElapsed
        )
        laps.append(record)
    }

    private func formatMMSS(_ totalSec: Int) -> String {
        let m = totalSec / 60
        let s = totalSec % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func formatStopwatch(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        let ms = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", m, s, ms)
    }
}
