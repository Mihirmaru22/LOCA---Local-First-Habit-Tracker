import SwiftUI

// MARK: - SoundMixerPanel

struct SoundMixerPanel: View {

    @ObservedObject var soundVM: FocusSoundViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Header
            HStack {
                Label("Sound", systemImage: "music.note")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

                Spacer()

                // Master Pause / Resume All Button
                Button {
                    soundVM.togglePauseAll()
                    Haptics.impact(.medium)
                } label: {
                    Image(systemName: soundVM.isAllPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(6)
                        .background(Color.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .help(soundVM.isAllPaused ? "Resume all sounds" : "Pause all sounds")

                Button {
                    isPresented = false
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }

            // Tracks List
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(soundVM.tracks) { track in
                        trackRow(track: track)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: 290)
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

    private func trackRow(track: AmbientSoundTrack) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(track.emoji) \(track.name)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    soundVM.toggleMute(for: track.id)
                    Haptics.impact(.light)
                } label: {
                    Image(systemName: (track.volume > 0 && !track.isMuted) ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 11))
                        .foregroundStyle((track.volume > 0 && !track.isMuted) ? Color.blue : Color.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            Slider(
                value: Binding(
                    get: { Double(track.volume) },
                    set: { soundVM.setVolume(for: track.id, volume: Float($0)) }
                ),
                in: 0.0...1.0
            )
            .tint(Color.blue)
        }
        .padding(8)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }
}
