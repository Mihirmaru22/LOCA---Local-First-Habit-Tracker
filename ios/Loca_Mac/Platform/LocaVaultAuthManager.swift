import Foundation
import LocalAuthentication
import SwiftUI
import Combine

// MARK: - LocaVaultAuthManager (Touch ID & Secure Enclave Biometric Lock)

/// Manages hardware-level biometric authentication (Touch ID / Face ID / Apple Watch proximity)
/// to safeguard Private Journal reflections, Net Worth goals, and Life Blueprint.
final class LocaVaultAuthManager: ObservableObject {

    static let shared = LocaVaultAuthManager()

    @AppStorage("mac_vault_biometrics_enabled") var isVaultSecurityEnabled: Bool = false
    @AppStorage("mac_vault_auto_lock_minutes") var autoLockMinutes: Int = 5

    @Published var isJournalUnlocked: Bool = false
    @Published var isLifeUnlocked: Bool = false
    @Published var lastUnlockTime: Date? = nil

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Auto-lock when Mac goes to sleep or app resigns active
        NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.handleBackgroundLock()
            }
            .store(in: &cancellables)
    }

    var isBiometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    var biometryTypeString: String {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        switch context.biometryType {
        case .touchID: return "Touch ID"
        case .faceID:  return "Face ID"
        case .opticID: return "Optic ID"
        default:       return "Touch ID / System Password"
        }
    }

    /// Authenticates with Touch ID or system passcode fallback.
    func authenticate(for section: String, completion: ((Bool) -> Void)? = nil) {
        guard isVaultSecurityEnabled else {
            unlockAll()
            completion?(true)
            return
        }

        // Check if recently unlocked within auto-lock window
        if let last = lastUnlockTime, Date().timeIntervalSince(last) < Double(autoLockMinutes * 60) {
            unlock(section: section)
            completion?(true)
            return
        }

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Password"

        let reason = "Authenticate with \(biometryTypeString) to access your \(section)."

        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.lastUnlockTime = Date()
                    self?.unlock(section: section)
                    Haptics.notify(.success)
                    completion?(true)
                } else {
                    Haptics.notify(.error)
                    completion?(false)
                }
            }
        }
    }

    private func unlock(section: String) {
        if section.lowercased().contains("journal") {
            isJournalUnlocked = true
        } else if section.lowercased().contains("life") {
            isLifeUnlocked = true
        } else {
            isJournalUnlocked = true
            isLifeUnlocked = true
        }
    }

    func lockAll() {
        isJournalUnlocked = false
        isLifeUnlocked = false
        lastUnlockTime = nil
        Haptics.impact(.light)
    }

    private func unlockAll() {
        isJournalUnlocked = true
        isLifeUnlocked = true
    }

    private func handleBackgroundLock() {
        if isVaultSecurityEnabled && autoLockMinutes == 0 {
            lockAll()
        }
    }
}
