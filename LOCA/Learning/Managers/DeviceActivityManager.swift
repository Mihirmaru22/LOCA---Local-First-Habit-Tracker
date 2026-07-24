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
        let lastHourActive = UIApplication.shared.applicationState == .active
        let activityScore = lastHourActive ? 0.7 : 0.2

        let signal = SignalEvent(
            timestamp: Date(),
            source: .deviceActivity,
            value: activityScore,
            uncertainty: 0.4,
            metadata: ["app_state": "\(UIApplication.shared.applicationState.description)"]
        )
        signals.append(signal)
        #endif

        return signals
    }
}

#if os(iOS)
extension UIApplicationState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }
}
#endif
