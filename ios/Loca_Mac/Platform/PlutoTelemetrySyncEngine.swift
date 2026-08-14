//
//  PlutoTelemetrySyncEngine.swift
//  PLUTO
//
//  Background HTTPS Ingestion Sync Engine for Private Alpha.
//  Transmits queued events, state snapshots, and crashes to the Supabase Edge Function (/alpha-ingest).
//  Operates asynchronously in background threads with zero UI blocking, automatic retries,
//  and offline resilience.
//

import Foundation
import Network
import os.log

// MARK: - PlutoTelemetrySyncEngine

final class PlutoTelemetrySyncEngine: @unchecked Sendable {

    static let shared = PlutoTelemetrySyncEngine()

    private let logger = Logger(subsystem: "com.mihirmaru.pluto.telemetry", category: "sync")
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.mihirmaru.pluto.telemetry.network")

    private var isNetworkAvailable: Bool = false
    private var isSyncing: Bool = false
    private var retryBackoffSeconds: TimeInterval = 10

    // MARK: - Backend Ingestion Endpoint Config

    #if DEBUG
    var endpointURL = URL(string: "https://rqujshlqgffuabpxiujw.supabase.co/functions/v1/alpha-ingest")!
    #else
    var endpointURL = URL(string: "https://rqujshlqgffuabpxiujw.supabase.co/functions/v1/alpha-ingest")!
    #endif

    var alphaSecretToken: String = "pluto_alpha_conductor_secret_token_v3"

    private init() {
        startNetworkMonitoring()
    }

    // MARK: - Network Lifecycle

    private func startNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let available = (path.status == .satisfied)
            self.isNetworkAvailable = available
            if available {
                Task {
                    await self.triggerSync(reason: "network_available")
                }
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    // MARK: - Trigger Sync

    func triggerSync(reason: String) async {
        guard isNetworkAvailable && !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let (events, snapshots, crashes, perf, files) = PlutoTelemetryStorage.shared.peekQueuedBatch(limit: 200)
        guard !files.isEmpty else { return }

        let payload = PlutoAlphaBatchPayload(
            tester_id: PlutoTelemetryEngine.shared.testerID,
            tester_name: PlutoTelemetryEngine.shared.testerName,
            device_name: PlutoTelemetryEngine.shared.deviceName,
            device_model: PlutoTelemetryEngine.shared.deviceModel,
            macos_version: PlutoTelemetryEngine.shared.macosVersion,
            app_version: PlutoTelemetryEngine.shared.appVersion,
            session_id: PlutoTelemetryEngine.shared.sessionID,
            session_started_at: PlutoTelemetryEngine.shared.sessionStartedAtString,
            session_ended_at: nil,
            events: events,
            snapshots: snapshots,
            crashes: crashes,
            performance: perf
        )

        do {
            var request = URLRequest(url: endpointURL)
            request.httpMethod = "POST"
            request.timeoutInterval = 25
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(alphaSecretToken, forHTTPHeaderField: "x-pluto-alpha-token")

            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                // Success ACK
                PlutoTelemetryStorage.shared.acknowledgeAndRemove(files: files)
                retryBackoffSeconds = 10 // reset backoff
                logger.debug("Successfully synced \(events.count) events, \(snapshots.count) snapshots (\(reason))")

                // If more queued items remain, schedule another quick flush
                let remaining = PlutoTelemetryStorage.shared.peekQueuedBatch(limit: 10)
                if !remaining.processedFiles.isEmpty {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await triggerSync(reason: "drain_remaining_queue")
                }
            } else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                let msg = String(data: data, encoding: .utf8) ?? "unknown error"
                logger.error("Telemetry sync failed with status \(status): \(msg)")
                scheduleBackoffRetry()
            }
        } catch {
            logger.error("Telemetry network request error: \(error.localizedDescription)")
            scheduleBackoffRetry()
        }
    }

    private func scheduleBackoffRetry() {
        let delay = min(300, retryBackoffSeconds * 1.5)
        retryBackoffSeconds = delay
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await triggerSync(reason: "exponential_backoff_retry")
        }
    }
}
