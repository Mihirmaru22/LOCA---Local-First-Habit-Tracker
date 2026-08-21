//
//  PlutoDiagnosticEngine.swift
//  PLUTO
//
//  Local Diagnostic & Crash Logging Engine.
//  Captures uncaught exceptions, system signals, and maintains an in-memory breadcrumb trail via os.Logger.
//

import Foundation
import AppKit
import os.log

// MARK: - PlutoDiagnosticEngine

final class PlutoDiagnosticEngine: @unchecked Sendable {

    static let shared = PlutoDiagnosticEngine()

    private static let logger = Logger(subsystem: "com.mihirmaru.loca.mac", category: "diagnostics")
    private let lock = NSLock()

    private var _currentScreen: String = "launch"
    var currentScreen: String {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _currentScreen
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _currentScreen = newValue
        }
    }

    private var breadcrumbBuffer: [String] = []
    private let maxBreadcrumbs = 50
    private var isConfigured = false

    private init() {}

    // MARK: - Breadcrumbs

    func leaveBreadcrumb(_ message: String) {
        lock.lock()
        defer { lock.unlock() }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "[\(timestamp)] \(message)"
        breadcrumbBuffer.append(entry)

        if breadcrumbBuffer.count > maxBreadcrumbs {
            breadcrumbBuffer.removeFirst(breadcrumbBuffer.count - maxBreadcrumbs)
        }
    }

    func getBreadcrumbs() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return breadcrumbBuffer
    }

    // MARK: - Crash Handling Configuration

    func configureCrashHandlers() {
        lock.lock()
        defer { lock.unlock() }

        guard !isConfigured else { return }
        isConfigured = true

        // 1. Uncaught NSException Handler
        NSSetUncaughtExceptionHandler { exception in
            PlutoDiagnosticEngine.shared.handleUncaughtException(exception)
        }

        // 2. POSIX Signal Handlers for native crashes
        signal(SIGABRT) { sig in PlutoDiagnosticEngine.handleSignal(sig, name: "SIGABRT") }
        signal(SIGILL)  { sig in PlutoDiagnosticEngine.handleSignal(sig, name: "SIGILL") }
        signal(SIGSEGV) { sig in PlutoDiagnosticEngine.handleSignal(sig, name: "SIGSEGV") }
        signal(SIGFPE)  { sig in PlutoDiagnosticEngine.handleSignal(sig, name: "SIGFPE") }
        signal(SIGBUS)  { sig in PlutoDiagnosticEngine.handleSignal(sig, name: "SIGBUS") }
        signal(SIGTRAP) { sig in PlutoDiagnosticEngine.handleSignal(sig, name: "SIGTRAP") }

        Self.logger.info("Pluto diagnostic and crash handlers successfully configured.")
    }

    // MARK: - Exception & Crash Reporting

    func handleUncaughtException(_ exception: NSException) {
        Self.logger.fault("Uncaught NSException: \(exception.name.rawValue) - \(exception.reason ?? "")")
    }

    private static func handleSignal(_ signal: Int32, name: String) {
        Self.logger.fault("Signal \(signal) (\(name)) received")
    }

    // MARK: - Manual Error & Performance Logging

    func recordError(_ error: Error, context: String = "") {
        Self.logger.error("Error recorded \(context.isEmpty ? "" : "[\(context)]"): \(error.localizedDescription)")
    }

    func recordPerformance(traceName: String, durationMs: Double) {
        Self.logger.debug("Performance trace '\(traceName)': \(durationMs)ms")
    }
}
