//
//  PlutoLoginItemManager.swift
//  PLUTO
//
//  Auto-launch at macOS Login using modern ServiceManagement (SMAppService).
//  Sandboxed & Apple Native compliant for macOS 14+ (Sonoma/Sequoia).
//

import Foundation
import ServiceManagement
import SwiftUI
import Combine

// MARK: - PlutoLoginItemManager

@MainActor
final class PlutoLoginItemManager: ObservableObject {

    static let shared = PlutoLoginItemManager()

    // MARK: - Published State

    @Published var isEnabled: Bool = false
    @Published var statusDescription: String = "Disabled"
    @Published var lastErrorMessage: String? = nil

    // MARK: - Init

    private init() {
        refreshStatus()
    }

    // MARK: - Status Checking

    func refreshStatus() {
        let status = SMAppService.mainApp.status
        switch status {
        case .enabled:
            self.isEnabled = true
            self.statusDescription = "Active (Launches at login)"
        case .notRegistered:
            self.isEnabled = false
            self.statusDescription = "Not registered"
        case .requiresApproval:
            self.isEnabled = false
            self.statusDescription = "Requires approval in System Settings"
        case .notFound:
            self.isEnabled = false
            self.statusDescription = "App service not found"
        @unknown default:
            self.isEnabled = false
            self.statusDescription = "Unknown status"
        }
    }

    // MARK: - Toggle Action

    func setLaunchAtLogin(enabled: Bool) {
        lastErrorMessage = nil
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
            refreshStatus()
        } catch {
            self.lastErrorMessage = error.localizedDescription
            refreshStatus()
        }
    }
}
