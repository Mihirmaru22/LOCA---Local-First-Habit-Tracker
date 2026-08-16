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

// MARK: - FocusSoundViewModel (Multi-Channel Procedural Synthesis Engine)

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

    // Multi-Track Procedural Audio Engine
    private var audioEngine = AVAudioEngine()
    private var mixerNodes: [String: AVAudioMixerNode] = [:]
    private var sourceNodes: [String: AVAudioSourceNode] = [:]
    private var isEngineStarted: Bool = false

    // Direct thread-safe atomic volumes for audio render thread
    private var trackVolumes: [String: Float] = [
        "lofi": 0.0, "nature": 0.0, "rain": 0.0, "fireplace": 0.0, "library": 0.0, "piano": 0.0
    ]

    // Synthesis per-track phase trackers
    private var lofiPhase: Float = 0.0
    private var rainB0: Float = 0.0, rainB1: Float = 0.0, rainB2: Float = 0.0
    private var natureLfo: Float = 0.0, naturePink: Float = 0.0
    private var fireHumPhase: Float = 0.0
    private var libraryPhase: Float = 0.0
    private var pianoPhase: Float = 0.0

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupMultiTrackEngine()
        setupAudioObservers()
    }

    private func setupAudioObservers() {
        NotificationCenter.default.publisher(for: .AVAudioEngineConfigurationChange, object: audioEngine)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleEngineConfigurationChange()
            }
            .store(in: &cancellables)

        #if os(iOS)
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let userInfo = notification.userInfo,
                      let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

                if type == .ended {
                    if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                        if options.contains(.shouldResume) {
                            self?.checkEngineRunning()
                        }
                    }
                }
            }
            .store(in: &cancellables)
        #endif
    }

    private func handleEngineConfigurationChange() {
        let wasRunning = isEngineStarted
        audioEngine.stop()
        isEngineStarted = false

        // Detach old nodes cleanly
        for (_, node) in sourceNodes {
            audioEngine.detach(node)
        }
        for (_, node) in mixerNodes {
            audioEngine.detach(node)
        }
        sourceNodes.removeAll()
        mixerNodes.removeAll()

        // Rebuild graph with new output route hardware sample rate
        setupMultiTrackEngine()

        // Restore volumes
        for track in tracks {
            if !track.isMuted && !isAllPaused {
                applyVolume(trackID: track.id, volume: track.volume)
            }
        }

        if wasRunning && !isAllPaused {
            checkEngineRunning()
        }
    }

    private func setupMultiTrackEngine() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSession setup failed: \(error)")
        }
        #endif

        let mainMixer = audioEngine.mainMixerNode
        let format = mainMixer.outputFormat(forBus: 0)
        let sampleRate = Float(format.sampleRate > 0 ? format.sampleRate : 44100.0)

        for track in tracks {
            let mixer = AVAudioMixerNode()
            mixer.outputVolume = 0.0
            audioEngine.attach(mixer)
            audioEngine.connect(mixer, to: mainMixer, format: format)
            mixerNodes[track.id] = mixer

            // Dedicated procedural source node per channel
            let trackID = track.id
            let source = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
                guard let self = self else { return noErr }
                let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
                
                // If this track's volume is 0 or all paused, output absolute silence (0.0)
                let vol = self.trackVolumes[trackID] ?? 0.0
                if vol <= 0.001 || self.isAllPaused {
                    for buffer in ablPointer {
                        memset(buffer.mData, 0, Int(buffer.mDataByteSize))
                    }
                    return noErr
                }

                for frame in 0..<Int(frameCount) {
                    let sample = self.generateSample(for: trackID, sampleRate: sampleRate) * vol
                    for buffer in ablPointer {
                        let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                        if frame < buf.count {
                            buf[frame] = sample
                        }
                    }
                }
                return noErr
            }

            audioEngine.attach(source)
            audioEngine.connect(source, to: mixer, format: format)
            sourceNodes[trackID] = source
        }

        isEngineStarted = false
    }

    // MARK: - Procedural Audio Synthesizer per Channel

    private func generateSample(for trackID: String, sampleRate: Float) -> Float {
        let dt = 1.0 / sampleRate

        switch trackID {
        case "lofi":
            lofiPhase += 2.0 * .pi * 174.61 * dt // F3 warm root note
            if lofiPhase > 2.0 * .pi { lofiPhase -= 2.0 * .pi }
            let base = sin(lofiPhase) * 0.4
            let vinyl = Float.random(in: -1.0...1.0) * (Float.random(in: 0...1) > 0.985 ? 0.25 : 0.015)
            return (base + vinyl) * 0.35

        case "nature":
            natureLfo += 2.0 * .pi * 0.2 * dt
            if natureLfo > 2.0 * .pi { natureLfo -= 2.0 * .pi }
            let white = Float.random(in: -1.0...1.0)
            naturePink = 0.95 * naturePink + 0.05 * white
            let rustle = naturePink * (0.5 + 0.5 * sin(natureLfo))
            return rustle * 0.3

        case "rain":
            let white = Float.random(in: -1.0...1.0)
            rainB0 = 0.99765 * rainB0 + white * 0.0990460
            rainB1 = 0.96300 * rainB1 + white * 0.2965164
            rainB2 = 0.57000 * rainB2 + white * 1.0526913
            let pink = (rainB0 + rainB1 + rainB2 + white * 0.1848) * 0.05
            let drop = Float.random(in: 0...1) > 0.998 ? Float.random(in: 0.2...0.6) : 0.0
            return (pink + drop) * 0.35

        case "fireplace":
            fireHumPhase += 2.0 * .pi * 55.0 * dt
            if fireHumPhase > 2.0 * .pi { fireHumPhase -= 2.0 * .pi }
            let hum = sin(fireHumPhase) * 0.15
            let crackle = Float.random(in: 0...1) > 0.996 ? Float.random(in: 0.4...0.8) : 0.0
            return (hum + crackle) * 0.4

        case "library":
            libraryPhase += 2.0 * .pi * 0.05 * dt
            if libraryPhase > 2.0 * .pi { libraryPhase -= 2.0 * .pi }
            let white = Float.random(in: -1.0...1.0) * 0.08
            return white * (0.6 + 0.4 * sin(libraryPhase)) * 0.25

        case "piano":
            pianoPhase += 2.0 * .pi * 261.63 * dt // Middle C harmonic
            if pianoPhase > 2.0 * .pi { pianoPhase -= 2.0 * .pi }
            let harmonic1 = sin(pianoPhase) * 0.3
            let harmonic2 = sin(pianoPhase * 2.0) * 0.15
            return (harmonic1 + harmonic2) * 0.3

        default:
            return 0.0
        }
    }

    // MARK: - Public Control API

    func setVolume(for trackID: String, volume: Float) {
        guard let index = tracks.firstIndex(where: { $0.id == trackID }) else { return }
        tracks[index].volume = volume
        
        if volume > 0.001 {
            tracks[index].isMuted = false
            tracks[index].previousVolume = volume
            applyVolume(trackID: trackID, volume: volume)
        } else {
            applyVolume(trackID: trackID, volume: 0.0)
        }
    }

    func toggleMute(for trackID: String) {
        guard let index = tracks.firstIndex(where: { $0.id == trackID }) else { return }
        
        if tracks[index].isMuted {
            tracks[index].isMuted = false
            let restored = tracks[index].previousVolume > 0 ? tracks[index].previousVolume : 0.5
            tracks[index].volume = restored
            applyVolume(trackID: trackID, volume: restored)
        } else {
            tracks[index].isMuted = true
            tracks[index].previousVolume = tracks[index].volume > 0 ? tracks[index].volume : 0.5
            tracks[index].volume = 0.0
            applyVolume(trackID: trackID, volume: 0.0)
        }
    }

    func togglePauseAll() {
        isAllPaused.toggle()
        
        if isAllPaused {
            for track in tracks {
                mixerNodes[track.id]?.outputVolume = 0.0
                trackVolumes[track.id] = 0.0
            }
        } else {
            for track in tracks where !track.isMuted {
                mixerNodes[track.id]?.outputVolume = track.volume
                trackVolumes[track.id] = track.volume
            }
            checkEngineRunning()
        }
    }

    private func applyVolume(trackID: String, volume: Float) {
        trackVolumes[trackID] = volume
        mixerNodes[trackID]?.outputVolume = volume

        let hasActiveAudio = trackVolumes.values.contains(where: { $0 > 0.001 })
        if hasActiveAudio && !isAllPaused {
            if !isEngineStarted {
                try? audioEngine.start()
                isEngineStarted = true
            }
        } else {
            if isEngineStarted {
                audioEngine.pause()
                isEngineStarted = false
            }
        }
    }

    private func checkEngineRunning() {
        let hasActiveAudio = trackVolumes.values.contains(where: { $0 > 0.001 })
        if hasActiveAudio && !isAllPaused {
            if !isEngineStarted {
                try? audioEngine.start()
                isEngineStarted = true
            }
        }
    }

    deinit {
        audioEngine.stop()
    }
}
