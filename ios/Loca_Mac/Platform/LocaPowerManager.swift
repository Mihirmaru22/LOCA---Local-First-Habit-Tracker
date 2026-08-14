import Foundation
import IOKit.pwr_mgt
import Combine
import SwiftUI

// MARK: - LocaPowerManager (macOS Power Assertion & Battery Optimizer)

/// Manages system sleep prevention during active Pomodoro deep work sessions via IOKit
/// and coordinates battery optimization when macOS Low Power Mode is active.
final class LocaPowerManager: ObservableObject {

    static let shared = LocaPowerManager()

    @Published var isLowPowerMode: Bool = false
    @Published var hasActiveSleepAssertion: Bool = false

    private var assertionID: IOPMAssertionID = 0
    private var activeSessionsCount: Int = 0
    private var cancellables = Set<AnyCancellable>()

    private init() {
        checkLowPowerMode()

        NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.checkLowPowerMode()
            }
            .store(in: &cancellables)
    }

    private func checkLowPowerMode() {
        let isLPM = ProcessInfo.processInfo.isLowPowerModeEnabled
        DispatchQueue.main.async {
            self.isLowPowerMode = isLPM
        }
    }

    // MARK: - Sleep Assertion Management (IOKit)

    /// Prevents the Mac from sleeping during an active focus sprint.
    func beginFocusSleepAssertion(reason: String = "PLUTO Deep Work Focus Session Active") {
        activeSessionsCount += 1
        guard assertionID == 0 else { return }

        let success = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &assertionID
        )

        if success == kIOReturnSuccess {
            DispatchQueue.main.async {
                self.hasActiveSleepAssertion = true
            }
        } else {
            print("Failed to create IOKit power assertion: \(success)")
        }
    }

    /// Releases the sleep assertion when focus session is completed or paused.
    func endFocusSleepAssertion() {
        activeSessionsCount = max(0, activeSessionsCount - 1)
        guard activeSessionsCount == 0, assertionID != 0 else { return }

        IOPMAssertionRelease(assertionID)
        assertionID = 0
        DispatchQueue.main.async {
            self.hasActiveSleepAssertion = false
        }
    }

    deinit {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
        }
    }
}
