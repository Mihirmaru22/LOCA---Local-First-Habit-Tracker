//
//  AppleComfortSoundsManager.swift
//  PLUTO
//
//  Direct integration bridge for Apple's Native Accessibility Background Sounds (Comfort Sounds).
//  Discovers and streams high-fidelity macOS system audio assets from:
//  /System/Library/AssetsV2/com_apple_MobileAsset_ComfortSoundsAssets/
//

import Foundation
import AVFoundation
import AppKit
import Combine

// MARK: - AppleComfortSoundKind

public enum AppleComfortSoundKind: String, CaseIterable, Identifiable, Sendable {
    case rain         = "Rain"
    case stream       = "Stream"
    case ocean        = "Ocean"
    case darkNoise    = "Dark Noise"
    case brightNoise  = "Bright Noise"
    case balancedNoise = "Balanced Noise"
    case fire         = "Fire"
    case night        = "Night"
    case quietNight   = "Quiet Night"
    case rainOnRoof   = "Rain On Roof"
    case babble       = "Babble"
    case steam        = "Steam"
    case train        = "Train"
    case aeroplane    = "Aeroplane"
    case boat         = "Boat"
    case bus          = "Bus"

    public var id: String { rawValue }

    public var emoji: String {
        switch self {
        case .rain:          return "🌧️"
        case .stream:        return "🌊"
        case .ocean:         return "🌊"
        case .darkNoise:     return "🌑"
        case .brightNoise:   return "💡"
        case .balancedNoise: return "⚖️"
        case .fire:          return "🔥"
        case .night:         return "🌌"
        case .quietNight:    return "🌙"
        case .rainOnRoof:    return "🏠"
        case .babble:        return "☕"
        case .steam:         return "♨️"
        case .train:         return "🚂"
        case .aeroplane:     return "✈️"
        case .boat:          return "⛵"
        case .bus:           return "🚌"
        }
    }

    public var assetNamePrefixes: [String] {
        switch self {
        case .rain:          return ["Rain", "rain"]
        case .stream:        return ["Stream", "stream"]
        case .ocean:         return ["Ocean", "ocean"]
        case .darkNoise:     return ["BrownNoise", "DarkNoise", "brown", "dark"]
        case .brightNoise:   return ["WhiteNoise", "BrightNoise", "white", "bright"]
        case .balancedNoise: return ["PinkNoise", "BalancedNoise", "pink", "balanced"]
        case .fire:          return ["Fire", "fire"]
        case .night:         return ["Night", "night"]
        case .quietNight:    return ["QuietNight", "quiet_night"]
        case .rainOnRoof:    return ["RainOnRoof", "Rain_On_Roof", "roof"]
        case .babble:        return ["Babble", "babble"]
        case .steam:         return ["Steam", "steam"]
        case .train:         return ["Train", "train"]
        case .aeroplane:     return ["Aeroplane", "Airplane", "aeroplane", "airplane"]
        case .boat:          return ["Boat", "boat"]
        case .bus:           return ["Bus", "bus"]
        }
    }
}

// MARK: - AppleComfortSoundInfo

public struct AppleComfortSoundInfo: Identifiable, Sendable {
    public var id: String { kind.rawValue }
    public let kind: AppleComfortSoundKind
    public var fileURLs: [URL]
    public var isDownloaded: Bool { !fileURLs.isEmpty }
    public var primaryFileURL: URL? { fileURLs.first }
}

// MARK: - AppleComfortSoundsManager

@MainActor
public final class AppleComfortSoundsManager: ObservableObject {

    public static let shared = AppleComfortSoundsManager()

    /// The base system path for macOS MobileAsset Comfort Sounds
    private static let systemAssetDirectoryPath = "/System/Library/AssetsV2/com_apple_MobileAsset_ComfortSoundsAssets"

    @Published public private(set) var availableSounds: [AppleComfortSoundKind: AppleComfortSoundInfo] = [:]
    @Published public private(set) var activePlayingSounds: Set<AppleComfortSoundKind> = []
    @Published public private(set) var isSystemBackgroundSoundsActive: Bool = false

    /// Active looping audio players keyed by sound kind
    private var players: [AppleComfortSoundKind: AVAudioPlayer] = [:]
    private var soundVolumes: [AppleComfortSoundKind: Float] = [:]

    private init() {
        scanSystemAssets()
        checkSystemBackgroundSoundsStatus()
    }

    // MARK: - Asset Scanning

    public func scanSystemAssets() {
        var catalog: [AppleComfortSoundKind: AppleComfortSoundInfo] = [:]
        for kind in AppleComfortSoundKind.allCases {
            catalog[kind] = AppleComfortSoundInfo(kind: kind, fileURLs: [])
        }

        let fileManager = FileManager.default
        let baseDir = URL(fileURLWithPath: Self.systemAssetDirectoryPath)

        guard let assetDirs = try? fileManager.contentsOfDirectory(at: baseDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            self.availableSounds = catalog
            return
        }

        for assetDir in assetDirs where assetDir.pathExtension == "asset" {
            let assetDataDir = assetDir.appendingPathComponent("AssetData", isDirectory: true)
            guard let audioFiles = try? fileManager.contentsOfDirectory(at: assetDataDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
                continue
            }

            for file in audioFiles where file.pathExtension.lowercased() == "m4a" || file.pathExtension.lowercased() == "caf" || file.pathExtension.lowercased() == "wav" {
                let filename = file.deletingPathExtension().lastPathComponent

                for kind in AppleComfortSoundKind.allCases {
                    let matches = kind.assetNamePrefixes.contains { prefix in
                        filename.localizedCaseInsensitiveContains(prefix)
                    }
                    if matches {
                        if var info = catalog[kind] {
                            info.fileURLs.append(file)
                            // Sort so _1.m4a or base name comes first
                            info.fileURLs.sort { $0.lastPathComponent < $1.lastPathComponent }
                            catalog[kind] = info
                        }
                    }
                }
            }
        }

        self.availableSounds = catalog
    }

    // MARK: - Playback Control

    public func isSoundDownloaded(_ kind: AppleComfortSoundKind) -> Bool {
        guard let info = availableSounds[kind] else { return false }
        return info.isDownloaded
    }

    public func setVolume(for kind: AppleComfortSoundKind, volume: Float) {
        let clamped = min(1.0, max(0.0, volume))
        soundVolumes[kind] = clamped

        if clamped > 0.001 {
            startPlaying(kind: kind, volume: clamped)
        } else {
            stopPlaying(kind: kind)
        }
    }

    public func startPlaying(kind: AppleComfortSoundKind, volume: Float) {
        guard let info = availableSounds[kind], let fileURL = info.primaryFileURL else {
            return
        }

        if let existing = players[kind] {
            existing.volume = volume
            if !existing.isPlaying {
                existing.play()
            }
            activePlayingSounds.insert(kind)
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.numberOfLoops = -1 // Infinite seamless loop
            player.volume = volume
            player.prepareToPlay()
            player.play()
            players[kind] = player
            activePlayingSounds.insert(kind)
        } catch {
            print("AppleComfortSoundsManager error playing \(kind.rawValue): \(error)")
        }
    }

    public func stopPlaying(kind: AppleComfortSoundKind) {
        if let player = players[kind] {
            player.stop()
            players.removeValue(forKey: kind)
        }
        activePlayingSounds.remove(kind)
    }

    public func pauseAll() {
        for (_, player) in players {
            player.pause()
        }
        activePlayingSounds.removeAll()
    }

    public func resumeAll() {
        for (kind, player) in players {
            let vol = soundVolumes[kind] ?? 0.5
            if vol > 0.001 {
                player.volume = vol
                player.play()
                activePlayingSounds.insert(kind)
            }
        }
    }

    public func stopAll() {
        for (_, player) in players {
            player.stop()
        }
        players.removeAll()
        activePlayingSounds.removeAll()
    }

    // MARK: - macOS System Settings Integration

    public func checkSystemBackgroundSoundsStatus() {
        let defaults = UserDefaults(suiteName: "com.apple.ComfortSounds")
        let isEnabled = defaults?.bool(forKey: "comfortSoundsEnabled") ?? false
        self.isSystemBackgroundSoundsActive = isEnabled
    }

    /// Opens macOS Accessibility Background Sounds settings pane
    public func openBackgroundSoundsSystemSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.preference.universalaccess?Hearing",
            "x-apple.systempreferences:com.apple.preference.universalaccess?Audio",
            "x-apple.systempreferences:com.apple.Sound-Settings.extension"
        ]
        for candidate in candidates {
            if let url = URL(string: candidate) {
                if NSWorkspace.shared.open(url) {
                    return
                }
            }
        }
    }
}
