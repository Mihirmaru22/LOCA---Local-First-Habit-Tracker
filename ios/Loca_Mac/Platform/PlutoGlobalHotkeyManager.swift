//
//  PlutoGlobalHotkeyManager.swift
//  PLUTO
//
//  Global Hotkey Manager for PLUTO Version 3.
//  Listens for ⌃⌥P (Control + Option + P) system-wide and toggles
//  a floating quick-action HUD overlay.
//

import SwiftUI
import AppKit
import SwiftData
import Combine

// MARK: - PlutoGlobalHotkeyManager

@MainActor
final class PlutoGlobalHotkeyManager: ObservableObject {

    static let shared = PlutoGlobalHotkeyManager()

    // MARK: - Published State

    @Published var isHUDVisible: Bool = false

    // MARK: - Internal Panel

    private var hudPanel: NSPanel?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    private init() {}

    // MARK: - Monitoring

    func startMonitoring() {
        guard globalMonitor == nil && localMonitor == nil else { return }

        // Global monitor: fires when other apps are active.
        // Requires macOS Accessibility Trust (System Settings → Privacy → Accessibility).
        // If not trusted, skip the global monitor entirely — registering it without
        // trust can freeze the Cocoa event dispatch pipeline on some macOS versions.
        if AXIsProcessTrusted() {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else { return }
                if self.isMatchingHotkey(event) {
                    Task { @MainActor in
                        self.toggleHUD()
                    }
                }
            }
        }

        // Local monitor: fires when PLUTO is active (no Accessibility Trust required)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if self.isMatchingHotkey(event) {
                self.toggleHUD()
                return nil // consume event
            }
            if event.keyCode == 53 && self.isHUDVisible { // Escape key
                self.hideHUD()
                return nil
            }
            return event
        }
    }

    func stopMonitoring() {
        if let g = globalMonitor { NSEvent.removeMonitor(g); globalMonitor = nil }
        if let l = localMonitor { NSEvent.removeMonitor(l); localMonitor = nil }
    }

    private func isMatchingHotkey(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let isControlOption = flags.contains([.control, .option])
        let isKeyP = event.keyCode == 35 || event.charactersIgnoringModifiers?.lowercased() == "p"
        return isControlOption && isKeyP
    }

    // MARK: - HUD Display

    func toggleHUD() {
        if isHUDVisible {
            hideHUD()
        } else {
            showHUD()
        }
    }

    func showHUD() {
        guard let container = try? ModelContainerFactory.makeConfiguredContainer() else { return }

        if hudPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 260),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.isMovableByWindowBackground = true
            panel.animationBehavior = .utilityWindow

            let hudView = PlutoQuickActionHUD(onClose: { [weak self] in
                self?.hideHUD()
            })
            .modelContainer(container)

            panel.contentView = NSHostingView(rootView: hudView)
            self.hudPanel = panel
        }

        if let panel = hudPanel {
            panel.center()
            panel.orderFrontRegardless()
            isHUDVisible = true
        }
    }

    func hideHUD() {
        hudPanel?.orderOut(nil)
        isHUDVisible = false
    }
}
