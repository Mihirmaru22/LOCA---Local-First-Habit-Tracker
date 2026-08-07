//
//  DeviceActivityManager.swift
//  LOCA
//
//  Device activity: screen time, app usage
//

import Foundation
#if os(iOS)
import UIKit
#endif

@MainActor
class DeviceActivityManager: NSObject {

    // MARK: - Screen Time Collection

    func collectScreenTime() async throws -> [SignalEvent] {
        var signals: [SignalEvent] = []

        #if os(iOS)
        let appState = UIApplication.shared.applicationState
        let lastHourActive = appState == .active
        let activityScore = lastHourActive ? 0.7 : 0.2

        let signal = SignalEvent(
            timestamp: Date(),
            source: .deviceActivity,
            value: activityScore,
            uncertainty: 0.4,
            metadata: ["app_state": appStateLabel(appState)]
        )
        signals.append(signal)
        #endif

        return signals
    }

    #if os(iOS)
    private func appStateLabel(_ state: UIApplication.State) -> String {
        switch state {
        case .active:     return "active"
        case .inactive:   return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }
    #endif
}
