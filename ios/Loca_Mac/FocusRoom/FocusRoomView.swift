import SwiftUI
import SwiftData

// MARK: - FocusRoomActivePanel

enum FocusRoomActivePanel {
    case none
    case background
    case sound
    case quote
    case stats
}

// MARK: - FocusRoomView (Pluto Fullscreen StudyStream Study Mode)

struct FocusRoomView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var timerVM = FocusTimerViewModel()
    @StateObject private var soundVM = FocusSoundViewModel()

    // Active Navigation / Panels State
    @State private var activePanel: FocusRoomActivePanel = .none
    @State private var showGoalsPanel: Bool = true
    @State private var showTimerModal: Bool = false
    @AppStorage("mac_today_submode") private var todaySubmode: String = "Plan"
    @State private var isFullscreen: Bool = false

    // Background State
    @State private var selectedPresetID: String = "city_1"
    @State private var youtubeVideoID: String? = nil
    @State private var currentSession: FocusSession? = nil

    // Queries for Telemetry
    @Query private var allGoals: [FocusGoal]

    private var openGoalsCount: Int { allGoals.filter { !$0.isCompleted }.count }
    private var totalGoalsCount: Int { allGoals.count }

    var body: some View {
        ZStack {

            // ===================================================================
            // LAYER 1: FULLSCREEN BACKGROUND
            // ===================================================================
            fullscreenBackgroundLayer
                .ignoresSafeArea(.all)

            // ===================================================================
            // LAYER 2: FLOATING TOP BAR
            // ===================================================================
            VStack {
                topFloatingBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                Spacer()
            }

            // ===================================================================
            // LAYER 3: FLOATING PANELS OVERLAY
            // ===================================================================
            HStack(alignment: .top) {

                // Left Column: Timer Card + Session Goals Panel stacked vertically (never overlap!)
                VStack(alignment: .leading, spacing: 12) {
                    if showTimerModal {
                        bigTimerModal
                            .transition(.asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    }

                    if showGoalsPanel {
                        FocusGoalsPanel(isPresented: $showGoalsPanel)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }

                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.top, 76)

                Spacer()

                // Right: Active Tool Panel (Background, Sound, Quote, Stats)
                VStack {
                    switch activePanel {
                    case .background:
                        BackgroundPickerPanel(
                            isPresented: Binding(
                                get: { activePanel == .background },
                                set: { if !$0 { activePanel = .none } }
                            ),
                            selectedPresetID: $selectedPresetID,
                            youtubeVideoID: $youtubeVideoID,
                            youtubeVolume: $soundVM.youtubeVolume
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))

                    case .sound:
                        SoundMixerPanel(
                            soundVM: soundVM,
                            isPresented: Binding(
                                get: { activePanel == .sound },
                                set: { if !$0 { activePanel = .none } }
                            )
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))

                    case .quote:
                        QuotePanel(
                            isPresented: Binding(
                                get: { activePanel == .quote },
                                set: { if !$0 { activePanel = .none } }
                            )
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))

                    case .stats:
                        StudyStatsPanel(
                            isPresented: Binding(
                                get: { activePanel == .stats },
                                set: { if !$0 { activePanel = .none } }
                            )
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))

                    case .none:
                        EmptyView()
                    }
                    Spacer()
                }
                .padding(.trailing, 20)
                .padding(.top, 76)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: activePanel)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showGoalsPanel)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showTimerModal)
        .onAppear {
            startSession()
        }
        .onDisappear {
            endSession()
        }
    }

    // MARK: - Layer 1: Fullscreen Background

    @ViewBuilder
    private var fullscreenBackgroundLayer: some View {
        if let videoID = youtubeVideoID, !videoID.isEmpty {
            YouTubeWebView(videoID: videoID, volume: soundVM.youtubeVolume)
        } else if let preset = BackgroundPickerPanel.presets.first(where: { $0.id == selectedPresetID }) {
            ZStack {
                // High-Resolution Photo Background
                AsyncImage(url: URL(string: preset.fullImageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .transition(.opacity)
                    case .failure:
                        LinearGradient(colors: preset.fallbackColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    case .empty:
                        ZStack {
                            LinearGradient(colors: preset.fallbackColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                            ProgressView().tint(.white)
                        }
                    @unknown default:
                        LinearGradient(colors: preset.fallbackColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }

                // Subtle Atmospheric Tint for Translucent Card Readability
                Color.black.opacity(0.20)
            }
        } else {
            // High fidelity artistic landscape gradients
            presetGradientBackground(presetID: selectedPresetID)
        }
    }

    private func presetGradientBackground(presetID: String) -> some View {
        ZStack {
            switch presetID {
            case "city_1":
                LinearGradient(
                    colors: [Color(red: 0.15, green: 0.25, blue: 0.45), Color(red: 0.05, green: 0.10, blue: 0.20)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case "anime_1":
                LinearGradient(
                    colors: [Color(red: 0.55, green: 0.35, blue: 0.55), Color(red: 0.15, green: 0.15, blue: 0.30)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case "lib_1":
                LinearGradient(
                    colors: [Color(red: 0.25, green: 0.18, blue: 0.12), Color(red: 0.08, green: 0.05, blue: 0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            default:
                LinearGradient(
                    colors: [Color(red: 0.12, green: 0.18, blue: 0.28), Color(red: 0.04, green: 0.06, blue: 0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            // Atmospheric Ambient Overlay
            RadialGradient(
                colors: [Color.blue.opacity(0.15), Color.clear],
                center: .center,
                startRadius: 100,
                endRadius: 600
            )
        }
    }

    // MARK: - Layer 2: Floating Top Bar

    private var topFloatingBar: some View {
        HStack {

            // Top-Left: Personal Timer Pill + Session Goals Pill
            HStack(spacing: 8) {
                // 1. Personal Timer Pill
                Button {
                    showTimerModal.toggle()
                    PlutoSoundEngine.shared.play(.tabSwitch)
                    Haptics.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))

                        VStack(alignment: .leading, spacing: 0) {
                            Text("Personal timer")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white.opacity(0.6))
                            Text(timerVM.formattedTime)
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .background(Color.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(.plain)

                // 2. Session Goals Pill (Toggles Goals Panel)
                Button {
                    showGoalsPanel.toggle()
                    PlutoSoundEngine.shared.play(.tabSwitch)
                    Haptics.impact(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))

                        VStack(alignment: .leading, spacing: 0) {
                            Text("Session goals")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white.opacity(0.6))
                            Text("\(totalGoalsCount - openGoalsCount)/\(totalGoalsCount)")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .background(Color.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(showGoalsPanel ? Color.blue.opacity(0.8) : Color.white.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Top-Center: Sub-pillar Mode Switcher [ Plan | List | Time ]
            HStack(spacing: 4) {
                ForEach(["Plan", "List", "Time"], id: \.self) { mode in
                    let isSelected = todaySubmode == mode
                    Button {
                        withAnimation(.spring(response: 0.35)) {
                            todaySubmode = mode
                        }
                        PlutoSoundEngine.shared.play(.tabSwitch)
                        Haptics.impact(.light)
                    } label: {
                        Text(mode)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(isSelected ? Color.white.opacity(0.2) : Color.clear)
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(.ultraThinMaterial, in: Capsule())
            .background(Color.black.opacity(0.65), in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))

            Spacer()

            // Top-Right: 5 Control Icon Buttons (Background, Sound, Quote, Stats, Fullscreen/Exit)
            HStack(spacing: 8) {
                topIconButton(icon: "photo.on.rectangle.angled", panel: .background)
                topIconButton(icon: "music.note", panel: .sound)
                topIconButton(icon: "quote.bubble.fill", panel: .quote)
                topIconButton(icon: "chart.bar.fill", panel: .stats)

                // Fullscreen / Exit Button
                Button {
                    #if os(macOS)
                    NSApp.keyWindow?.toggleFullScreen(nil)
                    #else
                    dismiss()
                    #endif
                    Haptics.impact(.medium)
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .background(Color.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Toggle Fullscreen")
            }
        }
    }

    private func topIconButton(icon: String, panel: FocusRoomActivePanel) -> some View {
        let isActive = activePanel == panel

        return Button {
            withAnimation(.spring(response: 0.35)) {
                if activePanel == panel {
                    activePanel = .none
                } else {
                    activePanel = panel
                }
            }
            PlutoSoundEngine.shared.play(.tabSwitch)
            Haptics.impact(.light)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                .background(Color.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isActive ? Color.blue : Color.white.opacity(0.15), lineWidth: isActive ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Big Timer Modal Popup

    private var bigTimerModal: some View {
        VStack(spacing: 12) {
            HStack {
                Label("Personal timer", systemImage: "timer")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()

                Button {
                    timerVM.isMuted.toggle()
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: timerVM.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showTimerModal = false
                    }
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text(timerVM.formattedTime)
                    .font(.system(size: 32, weight: .heavy, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        timerVM.resetTimer()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button {
                        timerVM.togglePlayPause()
                    } label: {
                        Image(systemName: timerVM.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .frame(width: 290)
        .background(
            Color.black.opacity(0.72)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.14), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
    }

    // MARK: - Session Persistence

    private func startSession() {
        let session = FocusSession(startTime: Date())
        modelContext.insert(session)
        try? modelContext.save()
        currentSession = session
    }

    private func endSession() {
        if let session = currentSession {
            session.endTime = Date()
            session.durationSeconds = timerVM.secondsElapsed
            try? modelContext.save()
        }
    }
}
