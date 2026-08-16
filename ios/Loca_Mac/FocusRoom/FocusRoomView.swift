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
    @State private var showQuoteCard: Bool = true
    @State private var showTimerModal: Bool = false
    @AppStorage("mac_today_submode") private var todaySubmode: String = "Plan"
    @State private var isFullscreen: Bool = false

    // Background State
    @State private var selectedPresetID: String = "nat_1"
    @State private var youtubeVideoID: String? = nil
    @State private var currentSession: FocusSession? = nil

    // Queries for Telemetry
    @Query private var allGoals: [FocusGoal]

    private var openGoalsCount: Int { allGoals.filter { !$0.isCompleted }.count }
    private var totalGoalsCount: Int { allGoals.count }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {

                // ===================================================================
                // LAYER 1: FULLSCREEN BACKGROUND (Strictly Clipped to Window Frame)
                // ===================================================================
                fullscreenBackground(size: geo.size)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea(.all)
                    .zIndex(0)

                // ===================================================================
                // LAYER 3: FLOATING PANELS OVERLAY
                // ===================================================================
                HStack(alignment: .top, spacing: 0) {

                    // Left Column: Timer Card + Session Goals Panel stacked vertically
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

                    // Right Column: Active Tool Panels + Persistent Quote Card
                    VStack(alignment: .trailing, spacing: 12) {
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

                        case .none, .quote:
                            EmptyView()
                        }

                        // Persistent Quote Card (always stays visible on screen unless closed)
                        if showQuoteCard {
                            QuotePanel(isPresented: $showQuoteCard)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }

                        Spacer()
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 76)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .zIndex(50)

                // ===================================================================
                // LAYER 2: FLOATING TOP BAR (Pinned to Top-Center & Edges)
                // ===================================================================
                topFloatingBar
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .frame(width: geo.size.width)
                    .zIndex(100)

                // ===================================================================
                // LAYER 4: BOTTOM KEYBOARD SHORTCUT HUD
                // ===================================================================
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        shortcutBadge(key: "Space", label: timerVM.isRunning ? "Pause" : "Resume")
                        shortcutBadge(key: "⌘T", label: "Timer")
                        shortcutBadge(key: "⌘F", label: "Fullscreen")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .background(Color.black.opacity(0.65), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
                    .padding(.bottom, 16)
                }
                .frame(width: geo.size.width)
                .zIndex(70)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: activePanel)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showGoalsPanel)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showQuoteCard)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showTimerModal)
        .onAppear {
            DispatchQueue.main.async {
                startSession()
            }
        }
        .onDisappear {
            DispatchQueue.main.async {
                endSession()
            }
        }
    }

    // MARK: - Layer 1: Fullscreen Background (Constrained to Window Bounds)

    @ViewBuilder
    private func fullscreenBackground(size: CGSize) -> some View {
        if let videoID = youtubeVideoID, !videoID.isEmpty {
            YouTubeWebView(videoID: videoID, volume: soundVM.youtubeVolume)
                .frame(width: size.width, height: size.height)
                .clipped()
        } else if let preset = BackgroundPickerPanel.presets.first(where: { $0.id == selectedPresetID }) {
            ZStack {
                // Base fallback gradient
                LinearGradient(colors: preset.fallbackColors, startPoint: .topLeading, endPoint: .bottomTrailing)

                // High-Resolution Photo Background constrained to exact window size
                AsyncImage(url: URL(string: preset.fullImageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipped()
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
                .frame(width: size.width, height: size.height)
                .clipped()

                // Subtle Atmospheric Tint for Translucent Card Readability
                Color.black.opacity(0.20)
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        } else {
            presetGradientBackground(presetID: selectedPresetID)
                .frame(width: size.width, height: size.height)
                .clipped()
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
                
                // Quote Button (toggles persistent quote card on screen)
                Button {
                    withAnimation(.spring(response: 0.35)) {
                        showQuoteCard.toggle()
                    }
                    PlutoSoundEngine.shared.play(.tabSwitch)
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                        .background(Color.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(showQuoteCard ? Color.blue : Color.white.opacity(0.15), lineWidth: showQuoteCard ? 2 : 1)
                        )
                }
                .buttonStyle(.plain)
                .help("Toggle Motivational Quote")

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
        let session = FocusSession(
            startTime: Date(),
            sessionTag: "Study Stream",
            backgroundCategory: selectedPresetID
        )
        modelContext.insert(session)
        try? modelContext.save()
        currentSession = session
    }

    private func endSession() {
        guard let session = currentSession else { return }
        let duration = timerVM.secondsElapsed
        if duration < 15 {
            modelContext.delete(session)
            try? modelContext.save()
            currentSession = nil
            return
        }
        session.endTime = Date()
        session.durationSeconds = duration
        try? modelContext.save()
        currentSession = nil
    }

    private func shortcutBadge(key: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 3))
                .foregroundStyle(Color.white.opacity(0.85))
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.65))
        }
    }
}
