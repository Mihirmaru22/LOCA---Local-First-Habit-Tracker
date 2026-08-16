import Foundation
import AVFoundation
import Combine

// MARK: - AmbientSoundTrack

struct AmbientSoundTrack: Identifiable {
    let id: String
    let name: String
    let emoji: String
    var volume: Float = 0.0
    var isMuted: Bool = false
    var previousVolume: Float = 0.5
}

// MARK: - FocusSoundViewModel

@MainActor
final class FocusSoundViewModel: ObservableObject {

    @Published var tracks: [AmbientSoundTrack] = [
        AmbientSoundTrack(id: "lofi", name: "LoFi beats", emoji: "⭐", volume: 0.0),
        AmbientSoundTrack(id: "nature", name: "Nature sounds", emoji: "🌿", volume: 0.0),
        AmbientSoundTrack(id: "rain", name: "Rain sounds", emoji: "💧", volume: 0.0),
        AmbientSoundTrack(id: "fireplace", name: "Fireplace sounds", emoji: "🔥", volume: 0.0),
        AmbientSoundTrack(id: "library", name: "Library ambience", emoji: "📚", volume: 0.0),
        AmbientSoundTrack(id: "piano", name: "Piano & jazz", emoji: "🎹", volume: 0.0)
    ]

    @Published var isAllPaused: Bool = false
    @Published var youtubeVolume: Double = 0.5

    private var audioPlayers: [String: AVAudioPlayer] = [:]

    init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    func setVolume(for trackID: String, volume: Float) {
        guard let index = tracks.firstIndex(where: { $0.id == trackID }) else { return }
        tracks[index].volume = volume
        if volume > 0 {
            tracks[index].isMuted = false
            tracks[index].previousVolume = volume
            playTrack(id: trackID, volume: volume)
        } else {
            stopTrack(id: trackID)
        }
    }

    func toggleMute(for trackID: String) {
        guard let index = tracks.firstIndex(where: { $0.id == trackID }) else { return }
        if tracks[index].isMuted {
            tracks[index].isMuted = false
            tracks[index].volume = tracks[index].previousVolume > 0 ? tracks[index].previousVolume : 0.5
            playTrack(id: trackID, volume: tracks[index].volume)
        } else {
            tracks[index].isMuted = true
            tracks[index].previousVolume = tracks[index].volume
            tracks[index].volume = 0.0
            stopTrack(id: trackID)
        }
    }

    func togglePauseAll() {
        isAllPaused.toggle()
        if isAllPaused {
            for track in tracks {
                stopTrack(id: track.id)
            }
        } else {
            for track in tracks where track.volume > 0 && !track.isMuted {
                playTrack(id: track.id, volume: track.volume)
            }
        }
    }

    private func playTrack(id: String, volume: Float) {
        if isAllPaused { return }
        
        // If player exists, update volume and play
        if let player = audioPlayers[id] {
            player.volume = volume
            if !player.isPlaying {
                player.play()
            }
            return
        }

        // Initialize bundled audio file or fallback generator
        if let url = Bundle.main.url(forResource: id, withExtension: "mp3") ??
                     Bundle.main.url(forResource: id, withExtension: "wav") {
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.numberOfLoops = -1 // Infinite loop
                player.volume = volume
                player.prepareToPlay()
                player.play()
                audioPlayers[id] = player
            }
        } else {
            // Placeholder: When audio assets are provided, they loop seamlessly.
            // AmbientSoundEngine.shared handles synthesized sounds as fallback.
            AmbientSoundEngine.shared.start()
        }
    }

    private func stopTrack(id: String) {
        if let player = audioPlayers[id] {
            player.pause()
        }
    }

    deinit {
        for (_, player) in audioPlayers {
            player.stop()
        }
    }
}
