//
//  PlutoDiagnosticEngine.swift
//  PLUTO
//
//  Crash Diagnostics, Breadcrumb Ring Buffer & Exception Recovery for Private Alpha.
//  Maintains an in-memory rolling ring buffer of the last 50 user actions.
//  On fatal crashes or unhandled NSExceptions, captures full diagnostics + breadcrumbs
//  and enqueues to PlutoTelemetryStorage for immediate creator inspection.
//

import Foundation
import AppKit
import os.log

// MARK: - PlutoDiagnosticEngine

final class PlutoDiagnosticEngine: @unchecked Sendable {

    static let shared = PlutoDiagnosticEngine()

    private let lock = NSLock()
    private var breadcrumbs: [String] = []
    private let maxBreadcrumbs = 50
    private let logger = Logger(subsystem: "com.mihirmaru.pluto.telemetry", category: "diagnostics")

    var currentScreen: String = "AppLaunch"

    private init() {}

    // MARK: - Setup Handlers

    func configureCrashHandlers() {
        // 1. NSSetUncaughtExceptionHandler
        NSSetUncaughtExceptionHandler { exception in
            PlutoDiagnosticEngine.shared.handleUncaughtException(exception)
        }

        // 2. Signal Handling (SIGABRT, SIGSEGV, SIGBUS, SIGILL, SIGFPE)
        signal(SIGABRT) { sig in PlutoDiagnosticEngine.shared.handleSignal(sig, name: "SIGABRT") }
        signal(SIGSEGV) { sig in PlutoDiagnosticEngine.shared.handleSignal(sig, name: "SIGSEGV") }
        signal(SIGBUS)  { sig in PlutoDiagnosticEngine.shared.handleSignal(sig, name: "SIGBUS") }
        signal(SIGILL)  { sig in PlutoDiagnosticEngine.shared.handleSignal(sig, name: "SIGILL") }
        signal(SIGFPE)  { sig in PlutoDiagnosticEngine.shared.handleSignal(sig, name: "SIGFPE") }
    }

    // MARK: - Breadcrumbs Buffer

    func leaveBreadcrumb(_ action: String, category: String = "ui") {
        lock.lock()
        defer { lock.unlock() }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let crumb = "[\(timestamp)] [\(category.uppercased())] \(action)"

        breadcrumbs.append(crumb)
        if breadcrumbs.count > maxBreadcrumbs {
            breadcrumbs.removeFirst(breadcrumbs.count - maxBreadcrumbs)
        }
    }

    func getCurrentBreadcrumbs() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return breadcrumbs
    }

    // MARK: - Crash Handling

    func handleUncaughtException(_ exception: NSException) {
        let name = exception.name.rawValue
        let reason = exception.reason ?? "No reason provided"
        let stack = exception.callStackSymbols.joined(separator: "\n")

        let crash = PlutoAlphaCrash(
            session_id: PlutoTelemetryEngine.shared.sessionID,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            app_version: PlutoTelemetryEngine.shared.appVersion,
            macos_version: PlutoTelemetryEngine.shared.macosVersion,
            current_screen: currentScreen,
            exception_name: name,
            exception_reason: reason,
            stack_trace: stack,
            breadcrumbs: getCurrentBreadcrumbs(),
            metadata: [
                "device_model": AnyCodable(PlutoTelemetryEngine.shared.deviceModel),
                "device_name": AnyCodable(PlutoTelemetryEngine.shared.deviceName)
            ]
        )

        PlutoTelemetryStorage.shared.enqueue(crash: crash)
        logger.fault("Captured unhandled NSException: \(name) - \(reason)")
    }

    func handleSignal(_ signalNum: Int32, name: String) {
        let stack = Thread.callStackSymbols.joined(separator: "\n")

        let crash = PlutoAlphaCrash(
            session_id: PlutoTelemetryEngine.shared.sessionID,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            app_version: PlutoTelemetryEngine.shared.appVersion,
            macos_version: PlutoTelemetryEngine.shared.macosVersion,
            current_screen: currentScreen,
            exception_name: "POSIX Signal \(name) (\(signalNum))",
            exception_reason: "Fatal POSIX OS signal caught",
            stack_trace: stack,
            breadcrumbs: getCurrentBreadcrumbs(),
            metadata: [
                "signal_code": AnyCodable(Int(signalNum))
            ]
        )

        PlutoTelemetryStorage.shared.enqueue(crash: crash)
    }
}
