import Foundation
import AudioToolbox

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

// MARK: - PlutoSoundEngine (Acoustic Audio & Haptic Feedback Engine)

/// Native macOS acoustic sound engine providing tactile mechanical and resonant feedback.
public final class PlutoSoundEngine {

    public static let shared = PlutoSoundEngine()

    @Published public var isSoundEnabled: Bool = true

    private init() {
        if UserDefaults.standard.object(forKey: "mac_sound_effects_enabled") != nil {
            self.isSoundEnabled = UserDefaults.standard.bool(forKey: "mac_sound_effects_enabled")
        }
    }

    public enum AcousticSound {
        case checkmark     // Crisp mechanical click for habit completion / task check
        case timerStart    // Resonant crystal ping when focus sprint starts
        case timerComplete // Harmonic chime when focus session finishes
        case summitPassport// Triumphant gold-foil celebration chime
        case tabSwitch     // Subtle tactile air-pop on navigation
        case vaultLock     // Tumbler click on biometric lock
        case deleteTrash   // Subtle paper swoosh on archive/delete
    }

    /// Plays a native acoustic sound with zero latency.
    public func play(_ sound: AcousticSound) {
        guard isSoundEnabled else { return }

        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        switch sound {
        case .checkmark:
            // Native Tink / Pop sound
            if let nssound = NSSound(named: "Tink") {
                nssound.play()
            } else {
                AudioServicesPlaySystemSound(1057)
            }

        case .timerStart:
            if let nssound = NSSound(named: "Pop") {
                nssound.play()
            } else {
                AudioServicesPlaySystemSound(1054)
            }

        case .timerComplete:
            if let nssound = NSSound(named: "Ping") {
                nssound.play()
            } else {
                AudioServicesPlaySystemSound(1016)
            }

        case .summitPassport:
            if let nssound = NSSound(named: "Hero") {
                nssound.play()
            } else {
                AudioServicesPlaySystemSound(1025)
            }

        case .tabSwitch:
            AudioServicesPlaySystemSound(1054)

        case .vaultLock:
            if let nssound = NSSound(named: "Purr") {
                nssound.play()
            } else {
                AudioServicesPlaySystemSound(1053)
            }

        case .deleteTrash:
            if let nssound = NSSound(named: "Basso") {
                nssound.play()
            } else {
                AudioServicesPlaySystemSound(1051)
            }
        }
        #endif
    }
}
