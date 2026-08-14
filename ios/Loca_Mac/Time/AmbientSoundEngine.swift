import Foundation
import AVFoundation
import Combine

// MARK: - AmbientSoundEngine (High-Fidelity Stereo & 3D Spatial Audio Synthesizer)

/// High-fidelity procedural audio generator for focus, flow state, and deep work.
/// Features Apple Spatial Audio 3D positioning (AVAudioEnvironmentNode), HRTF binaural rendering,
/// and procedural polyphonic synthesis locally with zero audio file dependencies.
final class AmbientSoundEngine: ObservableObject {

    static let shared = AmbientSoundEngine()

    @Published var isPlaying: Bool = false
    @Published var selectedSound: String = "Lo-Fi Focus Chords"
    @Published var volume: Float = 0.5
    @Published var isSpatialAudio: Bool = true

    private var engine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var environmentNode: AVAudioEnvironmentNode?

    // Audio Synthesis States & Oscillators
    private var sampleIndex: UInt64 = 0
    private var timeSec: Double = 0.0

    // Polyphonic chord oscillators (for Lo-Fi Chords & Cosmic Drift)
    private var oscPhase1: Float = 0.0
    private var oscPhase2: Float = 0.0
    private var oscPhase3: Float = 0.0
    private var oscPhase4: Float = 0.0
    private var oscPhase5: Float = 0.0

    // Spatial 3D orbit angles
    private var spatialAngle: Float = 0.0

    // Nature filter states
    private var pinkB0: Float = 0.0
    private var pinkB1: Float = 0.0
    private var pinkB2: Float = 0.0
    private var pinkB3: Float = 0.0
    private var pinkB4: Float = 0.0
    private var lfoPhase1: Float = 0.0
    private var lfoPhase2: Float = 0.0

    static let availableSounds: [(name: String, icon: String, description: String)] = [
        ("Lo-Fi Focus Chords", "music.note", "3D warm minor-9th ambient pad with gentle tape flutter"),
        ("Gentle Rain & Thunder", "cloud.rain.fill", "Spatial 3D stereo rainfall with distant rolling thunder"),
        ("Deep Binaural (432Hz)", "waveform.path.ecg", "432Hz carrier + 8Hz Alpha Wave flow state binaural beat"),
        ("Ocean Tide Swell", "water.waves", "3D sweeping surf swell with spatial acoustic depth"),
        ("Cosmic Synth Drift", "sparkles", "Lush ambient space pad with sweeping harmonic overtones"),
        ("Hearth & Campfire", "flame.fill", "Cozy wood hearth resonance with organic crackle pops"),
        ("Forest Wind & Chimes", "wind", "Mountain breeze with spatial 3D crystalline wind chimes"),
        ("Pristine White Noise", "circle.dotted", "Silky smooth broadband acoustic masking")
    ]

    private init() {}

    func togglePlay() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    func setSound(_ sound: String) {
        selectedSound = sound
        if isPlaying {
            stop()
            start()
        }
    }

    func toggleSpatialAudio() {
        isSpatialAudio.toggle()
        if isPlaying {
            stop()
            start()
        }
    }

    func start() {
        guard !isPlaying else { return }

        let newEngine = AVAudioEngine()
        let mainMixer = newEngine.mainMixerNode
        let outputFormat = mainMixer.outputFormat(forBus: 0)
        let sampleRate: Float = outputFormat.sampleRate > 0 ? Float(outputFormat.sampleRate) : 44100.0

        let currentType = selectedSound
        let useSpatial = isSpatialAudio

        // Reset phases
        oscPhase1 = 0; oscPhase2 = 0; oscPhase3 = 0; oscPhase4 = 0; oscPhase5 = 0
        pinkB0 = 0; pinkB1 = 0; pinkB2 = 0; pinkB3 = 0; pinkB4 = 0
        lfoPhase1 = 0; lfoPhase2 = 0
        spatialAngle = 0
        sampleIndex = 0

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let masterVol = self.volume * 0.16

            for frame in 0..<Int(frameCount) {
                var sampleL: Float = 0.0
                var sampleR: Float = 0.0

                self.sampleIndex &+= 1
                let t = Float(self.sampleIndex) / sampleRate

                // 3D Spatial panning LFO (0.05 Hz slow organic rotation)
                self.spatialAngle += 2.0 * Float.pi * 0.05 / sampleRate
                if self.spatialAngle > 2.0 * Float.pi { self.spatialAngle -= 2.0 * Float.pi }
                let spatialPanL = useSpatial ? 0.7 + 0.3 * cos(self.spatialAngle) : 1.0
                let spatialPanR = useSpatial ? 0.7 + 0.3 * sin(self.spatialAngle) : 1.0

                switch currentType {
                case "Lo-Fi Focus Chords":
                    // D minor 9 stack: D3 (146.83 Hz), F3 (174.61 Hz), A3 (220.0 Hz), C4 (261.63 Hz), E4 (329.63 Hz)
                    // With subtle tape flutter (0.3 Hz LFO) and warm soft clipping
                    let flutter = 1.0 + 0.003 * sin(2.0 * Float.pi * 0.4 * t)
                    let tremolo = 0.85 + 0.15 * sin(2.0 * Float.pi * 0.2 * t)

                    let f1 = 146.83 * flutter
                    let f2 = 174.61 * flutter
                    let f3 = 220.00 * flutter
                    let f4 = 261.63 * flutter
                    let f5 = 329.63 * flutter

                    self.oscPhase1 += 2.0 * Float.pi * f1 / sampleRate
                    self.oscPhase2 += 2.0 * Float.pi * f2 / sampleRate
                    self.oscPhase3 += 2.0 * Float.pi * f3 / sampleRate
                    self.oscPhase4 += 2.0 * Float.pi * f4 / sampleRate
                    self.oscPhase5 += 2.0 * Float.pi * f5 / sampleRate

                    let twoPi = 2.0 * Float.pi
                    if self.oscPhase1 > twoPi { self.oscPhase1 -= twoPi }
                    if self.oscPhase2 > twoPi { self.oscPhase2 -= twoPi }
                    if self.oscPhase3 > twoPi { self.oscPhase3 -= twoPi }
                    if self.oscPhase4 > twoPi { self.oscPhase4 -= twoPi }
                    if self.oscPhase5 > twoPi { self.oscPhase5 -= twoPi }

                    let s1 = sin(self.oscPhase1) * 0.28
                    let s2 = sin(self.oscPhase2) * 0.22
                    let s3 = sin(self.oscPhase3) * 0.20
                    let s4 = sin(self.oscPhase4) * 0.18
                    let s5 = sin(self.oscPhase5) * 0.12

                    // Warm soft-clip distortion
                    let rawL = (s1 + s3 + s5) * tremolo * spatialPanL
                    let rawR = (s2 + s4 + s5) * tremolo * spatialPanR

                    sampleL = tanh(rawL) * masterVol
                    sampleR = tanh(rawR) * masterVol

                case "Gentle Rain & Thunder":
                    // Multi-band Paul Kellet pink noise algorithm
                    let white = Float.random(in: -1.0...1.0)
                    self.pinkB0 = 0.99886 * self.pinkB0 + white * 0.0555179
                    self.pinkB1 = 0.99332 * self.pinkB1 + white * 0.0750759
                    self.pinkB2 = 0.96900 * self.pinkB2 + white * 0.1538520
                    self.pinkB3 = 0.86650 * self.pinkB3 + white * 0.3104856
                    self.pinkB4 = 0.55000 * self.pinkB4 + white * 0.5329522
                    let pink = self.pinkB0 + self.pinkB1 + self.pinkB2 + self.pinkB3 + self.pinkB4 + white * 0.5362

                    // Modulated spatial rain droplet variations
                    let rainMod = 0.6 + 0.4 * sin(2.0 * Float.pi * 0.08 * t)
                    let rainL = pink * rainMod * Float.random(in: 0.95...1.05) * 0.18
                    let rainR = pink * rainMod * Float.random(in: 0.95...1.05) * 0.18

                    // Low-frequency 3D rolling thunder every 18 seconds
                    let thunderCycle = t.truncatingRemainder(dividingBy: 18.0)
                    var thunder: Float = 0.0
                    if thunderCycle < 3.5 {
                        let env = sin((thunderCycle / 3.5) * Float.pi)
                        thunder = (sin(2.0 * Float.pi * 42.0 * t) + sin(2.0 * Float.pi * 55.0 * t) * 0.7) * env * 0.35
                    }

                    sampleL = (rainL * spatialPanL + thunder * 0.7) * masterVol
                    sampleR = (rainR * spatialPanR + thunder * 0.4) * masterVol

                case "Deep Binaural (432Hz)":
                    // Left ear: 432.0 Hz, Right ear: 440.0 Hz (Difference = 8.0 Hz Alpha Wave for deep focus)
                    self.oscPhase1 += 2.0 * Float.pi * 432.0 / sampleRate
                    self.oscPhase2 += 2.0 * Float.pi * 440.0 / sampleRate

                    let twoPi = 2.0 * Float.pi
                    if self.oscPhase1 > twoPi { self.oscPhase1 -= twoPi }
                    if self.oscPhase2 > twoPi { self.oscPhase2 -= twoPi }

                    // Subtle background pink noise bed
                    let white = Float.random(in: -1.0...1.0)
                    self.pinkB0 = 0.99 * self.pinkB0 + white * 0.05
                    let humBed = self.pinkB0 * 0.04

                    sampleL = (sin(self.oscPhase1) * 0.45 + humBed) * masterVol
                    sampleR = (sin(self.oscPhase2) * 0.45 + humBed) * masterVol

                case "Ocean Tide Swell":
                    // 12-second rhythmic tidal swell with resonant wave shaping
                    let wavePeriod: Float = 12.0
                    let phase = (t.truncatingRemainder(dividingBy: wavePeriod)) / wavePeriod
                    let swellEnv = pow(sin(phase * Float.pi), 2.2)

                    let white = Float.random(in: -1.0...1.0)
                    self.pinkB0 = 0.98 * self.pinkB0 + white * 0.08
                    let surf = self.pinkB0 * swellEnv * 0.45

                    sampleL = surf * (0.8 + 0.2 * cos(phase * Float.pi * 2)) * spatialPanL * masterVol
                    sampleR = surf * (0.8 + 0.2 * sin(phase * Float.pi * 2)) * spatialPanR * masterVol

                case "Cosmic Synth Drift":
                    // Lush space pad: 55Hz, 110Hz, 164.81Hz, 220Hz + slow LFO resonance
                    self.lfoPhase1 += 2.0 * Float.pi * 0.08 / sampleRate
                    if self.lfoPhase1 > 2.0 * Float.pi { self.lfoPhase1 -= 2.0 * Float.pi }
                    let lfo = (sin(self.lfoPhase1) + 1.0) * 0.5

                    self.oscPhase1 += 2.0 * Float.pi * 55.0 / sampleRate
                    self.oscPhase2 += 2.0 * Float.pi * 110.0 / sampleRate
                    self.oscPhase3 += 2.0 * Float.pi * 164.81 / sampleRate
                    self.oscPhase4 += 2.0 * Float.pi * 220.0 / sampleRate

                    let twoPi = 2.0 * Float.pi
                    if self.oscPhase1 > twoPi { self.oscPhase1 -= twoPi }
                    if self.oscPhase2 > twoPi { self.oscPhase2 -= twoPi }
                    if self.oscPhase3 > twoPi { self.oscPhase3 -= twoPi }
                    if self.oscPhase4 > twoPi { self.oscPhase4 -= twoPi }

                    let pad = sin(self.oscPhase1) * 0.3 + sin(self.oscPhase2) * 0.25 + sin(self.oscPhase3) * 0.2 + sin(self.oscPhase4) * 0.15
                    sampleL = (pad * (0.8 + 0.2 * lfo)) * spatialPanL * masterVol
                    sampleR = (pad * (0.8 + 0.2 * (1.0 - lfo))) * spatialPanR * masterVol

                case "Hearth & Campfire":
                    // Low hearth rumble + random wood crackle transients
                    let white = Float.random(in: -1.0...1.0)
                    self.pinkB0 = 0.995 * self.pinkB0 + white * 0.03
                    let rumble = self.pinkB0 * 0.3

                    var popL: Float = 0.0
                    var popR: Float = 0.0
                    if Float.random(in: 0...1.0) < 0.0015 {
                        let popAmp = Float.random(in: 0.4...0.9)
                        if Float.random(in: 0...1.0) < 0.5 {
                            popL = popAmp
                        } else {
                            popR = popAmp
                        }
                    }

                    sampleL = (rumble + popL) * masterVol
                    sampleR = (rumble * 0.95 + popR) * masterVol

                case "Forest Wind & Chimes":
                    // Mountain wind filter
                    let white = Float.random(in: -1.0...1.0)
                    self.pinkB0 = 0.985 * self.pinkB0 + white * 0.06
                    let windMod = 0.5 + 0.5 * sin(2.0 * Float.pi * 0.12 * t)
                    let wind = self.pinkB0 * 0.35 * windMod

                    // Chimes ping occasionally in 3D spatial field
                    var chimeL: Float = 0.0
                    var chimeR: Float = 0.0
                    let chimeCycle = t.truncatingRemainder(dividingBy: 6.0)
                    if chimeCycle < 0.8 {
                        let env = exp(-chimeCycle * 4.0)
                        let chimeSig = (sin(2.0 * Float.pi * 1760.0 * t) + sin(2.0 * Float.pi * 2637.0 * t) * 0.5) * env * 0.15
                        chimeL = chimeSig * spatialPanL
                        chimeR = chimeSig * spatialPanR
                    }

                    sampleL = (wind * spatialPanL + chimeL) * masterVol
                    sampleR = (wind * spatialPanR + chimeR) * masterVol

                default: // Pristine White Noise
                    let white = Float.random(in: -1.0...1.0)
                    sampleL = white * masterVol * 0.35 * spatialPanL
                    sampleR = white * masterVol * 0.35 * spatialPanR
                }

                if ablPointer.count >= 2 {
                    let bufL = UnsafeMutableBufferPointer<Float>(ablPointer[0])
                    let bufR = UnsafeMutableBufferPointer<Float>(ablPointer[1])
                    bufL[frame] = sampleL
                    bufR[frame] = sampleR
                } else if let first = ablPointer.first {
                    let buf = UnsafeMutableBufferPointer<Float>(first)
                    buf[frame] = (sampleL + sampleR) * 0.5
                }
            }
            return noErr
        }

        // Apple Spatial Audio Environment Setup
        if useSpatial {
            let env = AVAudioEnvironmentNode()
            env.renderingAlgorithm = .sphericalHead // HRTF 3D spatial rendering
            env.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
            env.reverbParameters.enable = true
            env.reverbParameters.loadFactoryReverbPreset(.mediumChamber)

            newEngine.attach(node)
            newEngine.attach(env)
            newEngine.connect(node, to: env, format: outputFormat)
            newEngine.connect(env, to: mainMixer, format: outputFormat)
            self.environmentNode = env
        } else {
            newEngine.attach(node)
            newEngine.connect(node, to: mainMixer, format: outputFormat)
        }

        do {
            try newEngine.start()
            self.engine = newEngine
            self.sourceNode = node
            DispatchQueue.main.async { self.isPlaying = true }
        } catch {
            print("Failed to start ambient audio engine: \(error)")
            newEngine.stop()
            newEngine.detach(node)
            if let env = self.environmentNode {
                newEngine.detach(env)
            }
            self.engine = nil
            self.sourceNode = nil
            self.environmentNode = nil
            DispatchQueue.main.async { self.isPlaying = false }
        }
    }

    func stop() {
        engine?.stop()
        if let node = sourceNode {
            engine?.detach(node)
        }
        if let env = environmentNode {
            engine?.detach(env)
        }
        sourceNode = nil
        environmentNode = nil
        engine = nil
        DispatchQueue.main.async { self.isPlaying = false }
    }
}
