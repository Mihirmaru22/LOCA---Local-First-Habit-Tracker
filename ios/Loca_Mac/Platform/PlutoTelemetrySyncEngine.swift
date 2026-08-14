//
//  PlutoTelemetrySyncEngine.swift
//  PLUTO
//
//  Background HTTPS Ingestion Sync Engine for Private Alpha.
//  Transmits queued events, state snapshots, and crashes directly to Supabase REST endpoints.
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

    private var isNetworkAvailable: Bool = true
    private var isSyncing: Bool = false
    private var retryBackoffSeconds: TimeInterval = 10

    // MARK: - Supabase Live Config

    let supabaseBaseURL = "https://uxmgychsvouemrqzlswy.supabase.co"
    let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV4bWd5Y2hzdm91ZW1ycXpsc3d5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY2ODY5NDEsImV4cCI6MjEwMjI2Mjk0MX0.ZL8dPBFwJg-O9awTNJi2JeQSGNuU-CEBob0kBEHVrLM"

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
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let (events, snapshots, _, _, files) = PlutoTelemetryStorage.shared.peekQueuedBatch(limit: 200)

        let testerID = await MainActor.run { PlutoTelemetryEngine.shared.testerID }
        let sessionID = await MainActor.run { PlutoTelemetryEngine.shared.sessionID }
        let testerName = await MainActor.run { PlutoTelemetryEngine.shared.testerName }
        let deviceModel = await MainActor.run { PlutoTelemetryEngine.shared.deviceModel }
        let macosVersion = await MainActor.run { PlutoTelemetryEngine.shared.macosVersion }
        let appVersion = await MainActor.run { PlutoTelemetryEngine.shared.appVersion }

        do {
            // 1. Upsert Tester Profile to /rest/v1/alpha_testers (MUST succeed before events)
            if let testersURL = URL(string: "\(supabaseBaseURL)/rest/v1/alpha_testers") {
                var request = URLRequest(url: testersURL)
                request.httpMethod = "POST"
                request.timeoutInterval = 15
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
                request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

                let testerPayload: [String: Any] = [
                    "id": testerID,
                    "name": testerName,
                    "device_model": deviceModel,
                    "macos_version": macosVersion,
                    "app_version": appVersion,
                    "last_active": ISO8601DateFormatter().string(from: Date())
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: testerPayload)
                let (testerData, testerResponse) = try await URLSession.shared.data(for: request)
                let testerStatus = (testerResponse as? HTTPURLResponse)?.statusCode ?? -1
                if !(200...299).contains(testerStatus) {
                    let msg = String(data: testerData, encoding: .utf8) ?? ""
                    logger.error("❌ Tester upsert failed: \(testerStatus) \(msg)")
                    print("📡 [PLUTO Telemetry] ❌ Tester upsert failed: \(testerStatus) \(msg)")
                    scheduleBackoffRetry()
                    return
                }
                logger.debug("✅ Tester upserted: \(testerID)")
                print("📡 [PLUTO Telemetry] ✅ Tester upserted to Supabase: \(testerID) (\(testerName))")
            }

            // 2. Insert Events to /rest/v1/alpha_events
            if !events.isEmpty, let eventsURL = URL(string: "\(supabaseBaseURL)/rest/v1/alpha_events") {
                var request = URLRequest(url: eventsURL)
                request.httpMethod = "POST"
                request.timeoutInterval = 20
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
                request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

                let eventsPayload: [[String: Any]] = events.map { e in
                    [
                        "tester_id": testerID,
                        "session_id": sessionID,
                        "event_name": e.event_name,
                        "properties": (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(e.properties))) ?? [:],
                        "timestamp": e.timestamp
                    ]
                }
                request.httpBody = try JSONSerialization.data(withJSONObject: eventsPayload)

                let (data, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                    logger.debug("Successfully synced \(events.count) alpha events to Supabase")
                    print("📡 [PLUTO Telemetry] ✅ Successfully synced \(events.count) events to Supabase")
                } else {
                    let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                    let msg = String(data: data, encoding: .utf8) ?? ""
                    logger.error("Events sync failed: \(status) \(msg)")
                    print("📡 [PLUTO Telemetry] ❌ Events sync failed: \(status) \(msg)")
                }
            }

            // 3. Insert Snapshots to /rest/v1/alpha_state_snapshots
            if !snapshots.isEmpty, let snapURL = URL(string: "\(supabaseBaseURL)/rest/v1/alpha_state_snapshots") {
                for snap in snapshots {
                    var request = URLRequest(url: snapURL)
                    request.httpMethod = "POST"
                    request.timeoutInterval = 15
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
                    request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

                    let snapPayload: [String: Any] = [
                        "id": snap.snapshot_id,
                        "tester_id": testerID,
                        "snapshot_payload": (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(snap.snapshot_json))) ?? [:],
                        "created_at": snap.timestamp
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: snapPayload)
                    let (data, response) = try await URLSession.shared.data(for: request)
                    let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                    if (200...299).contains(status) {
                        print("📡 [PLUTO Telemetry] ✅ State snapshot synced to Supabase: \(snap.snapshot_id)")
                    } else {
                        let msg = String(data: data, encoding: .utf8) ?? ""
                        print("📡 [PLUTO Telemetry] ❌ State snapshot sync failed: \(status) \(msg)")
                    }
                }
            }

            // Acknowledge and clear processed queue files
            if !files.isEmpty {
                PlutoTelemetryStorage.shared.acknowledgeAndRemove(files: files)
            }
            retryBackoffSeconds = 10

        } catch {
            logger.error("Telemetry sync exception: \(error.localizedDescription)")
            print("📡 [PLUTO Telemetry] ❌ Exception: \(error.localizedDescription)")
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
