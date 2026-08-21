import SwiftUI

// MARK: - SoundMixerPanel (Studio Multi-Stem Audio Console & Apple Background Sounds)

struct SoundMixerPanel: View {

    @ObservedObject var soundVM: FocusSoundViewModel
    @ObservedObject private var appleSounds = AppleComfortSoundsManager.shared
    @Binding var isPresented: Bool

    @State private var selectedTab: SoundSourceTab = .all

    enum SoundSourceTab: String, CaseIterable, Identifiable {
        case all   = "All"
        case apple = " Apple"
        case dsp   = "Studio"

        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "slider.vertical.3")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.accentColor)

                    Text("SOUND CONSOLE")
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(.white)
                }

                Spacer()

                // Master Pause / Resume All Button
                Button {
                    soundVM.togglePauseAll()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: soundVM.isAllPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(soundVM.isAllPaused ? "RESUME" : "MUTE ALL")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
                .help(soundVM.isAllPaused ? "Resume All Tracks" : "Mute All Tracks")

                Button {
                    isPresented = false
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
            }

            // Quick Atmospheric Preset Switcher
            VStack(alignment: .leading, spacing: 6) {
                Text("FOCUS PRESETS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.45))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        presetPill(title: "🌧️ Apple Rain") {
                            soundVM.applyAppleSoundPreset(kind: .rain, volume: 0.45)
                        }
                        presetPill(title: "🌊 Apple Stream") {
                            soundVM.applyAppleSoundPreset(kind: .stream, volume: 0.40)
                        }
                        presetPill(title: "🌑 Dark Noise") {
                            soundVM.applyAppleSoundPreset(kind: .darkNoise, volume: 0.35)
                        }
                        presetPill(title: "🔥 Apple Fire") {
                            soundVM.applyAppleSoundPreset(kind: .fire, volume: 0.40)
                        }
                        presetPill(title: "🌙 Quiet Night") {
                            soundVM.applyAppleSoundPreset(kind: .quietNight, volume: 0.35)
                        }
                        presetPill(title: "⭐ Deep LoFi") {
                            soundVM.applyPreset(lofi: 0.45, nature: 0.0, rain: 0.15, fire: 0.0, library: 0.0, piano: 0.20)
                        }
                        presetPill(title: "🔇 Clear") {
                            soundVM.clearAllTracks()
                        }
                    }
                }
            }

            // Source Filter Segmented Control
            HStack(spacing: 4) {
                ForEach(SoundSourceTab.allCases) { tab in
                    let isSelected = selectedTab == tab
                    Button {
                        selectedTab = tab
                        Haptics.impact(.light)
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.55))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                isSelected ? Color.white.opacity(0.18) : Color.clear,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                // macOS System Settings Link
                Button {
                    appleSounds.openBackgroundSoundsSystemSettings()
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 8))
                        Text("macOS Sounds")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(Color.blue.opacity(0.9))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)
                .help("Open macOS Accessibility Background Sounds Settings")
            }
            .padding(.vertical, 2)

            Divider().opacity(0.25)

            // Tracks List
            ScrollView {
                VStack(spacing: 10) {
                    let filteredTracks = soundVM.tracks.filter { track in
                        switch selectedTab {
                        case .all:   return true
                        case .apple: return track.isAppleNative
                        case .dsp:   return !track.isAppleNative
                        }
                    }

                    ForEach(filteredTracks) { track in
                        trackRow(track: track)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 320)
        }
        .padding(16)
        .frame(width: 330)
        .background(
            Color.black.opacity(0.85)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))
        .shadow(color: .black.opacity(0.55), radius: 24, x: 0, y: 10)
    }

    private func presetPill(title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.6))
        }
        .buttonStyle(.plain)
    }

    private func trackRow(track: AmbientSoundTrack) -> some View {
        let isActive = track.volume > 0.001 && !track.isMuted && !soundVM.isAllPaused
        let isDownloaded = track.appleKind != nil ? appleSounds.isSoundDownloaded(track.appleKind!) : true

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Text(track.emoji)
                        .font(.system(size: 13))

                    Text(track.name)
                        .font(.system(size: 12, weight: isActive ? .semibold : .medium))
                        .foregroundStyle(Color.white)

                    if track.isAppleNative {
                        HStack(spacing: 2) {
                            Text("")
                                .font(.system(size: 8, weight: .bold))
                            Text(isDownloaded ? "Native" : "DSP")
                                .font(.system(size: 8, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(isDownloaded ? Color.green.opacity(0.9) : Color.orange.opacity(0.8))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(
                            (isDownloaded ? Color.green : Color.orange).opacity(0.12),
                            in: Capsule()
                        )
                    }

                    if isActive {
                        // Mini pulsing equalizer visualizer
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { bar in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.blue)
                                    .frame(width: 2, height: CGFloat.random(in: 4...12))
                                    .animation(.easeInOut(duration: 0.4).repeatForever(), value: track.volume)
                            }
                        }
                    }
                }

                Spacer()

                Button {
                    soundVM.toggleMute(for: track.id)
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: (track.volume > 0.001 && !track.isMuted) ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 11))
                        .foregroundStyle((track.volume > 0.001 && !track.isMuted) ? Color.blue : Color.white.opacity(0.35))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { Double(track.volume) },
                        set: { soundVM.setVolume(for: track.id, volume: Float($0)) }
                    ),
                    in: 0.0...1.0
                )
                .tint(Color.blue)

                Text("\(Int(track.volume * 100))%")
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(isActive ? Color.white : Color.white.opacity(0.40))
                    .frame(width: 34, alignment: .trailing)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            isActive ? Color.white.opacity(0.06) : Color.white.opacity(0.02),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? Color.blue.opacity(0.35) : Color.white.opacity(0.05), lineWidth: 0.8)
        )
    }
}
