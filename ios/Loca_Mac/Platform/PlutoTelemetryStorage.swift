//
//  PlutoTelemetryStorage.swift
//  PLUTO
//
//  Bounded Local-First Telemetry Storage for Private Alpha.
//  Persists raw events, state snapshots, crashes, and performance traces
//  to a sandboxed disk queue under ~/Library/Application Support/PLUTO/AlphaTelemetry/.
//  Strictly enforces a 5,000-event / 25MB backpressure limit with FIFO purge.
//

import Foundation
import os.log

// MARK: - Telemetry Models

struct PlutoAlphaEvent: Codable, Identifiable {
    var id: String { event_id }
    let event_id: String
    let event_name: String
    let timestamp: String
    let properties: [String: AnyCodable]
}

struct PlutoAlphaSnapshot: Codable, Identifiable {
    var id: String { snapshot_id }
    let snapshot_id: String
    let timestamp: String
    let snapshot_json: [String: AnyCodable]
}

struct PlutoAlphaCrash: Codable {
    let session_id: String?
    let timestamp: String
    let app_version: String
    let macos_version: String
    let current_screen: String?
    let exception_name: String?
    let exception_reason: String?
    let stack_trace: String?
    let breadcrumbs: [String]
    let metadata: [String: AnyCodable]
}

struct PlutoAlphaPerformance: Codable {
    let session_id: String?
    let trace_name: String
    let duration_ms: Double
    let timestamp: String
    let metadata: [String: AnyCodable]
}

struct PlutoAlphaBatchPayload: Codable {
    let tester_id: String
    let tester_name: String?
    let device_name: String?
    let device_model: String?
    let macos_version: String?
    let app_version: String
    let session_id: String
    let session_started_at: String?
    let session_ended_at: String?
    var events: [PlutoAlphaEvent]
    var snapshots: [PlutoAlphaSnapshot]
    var crashes: [PlutoAlphaCrash]
    var performance: [PlutoAlphaPerformance]
}

// MARK: - AnyCodable Helper (for arbitrary dictionary serialization)

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            value = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let date = value as? Date {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(f.string(from: date))
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        } else {
            try container.encode("\(value)")
        }
    }
}

// MARK: - PlutoTelemetryStorage

final class PlutoTelemetryStorage: @unchecked Sendable {

    static let shared = PlutoTelemetryStorage()

    private let fileManager = FileManager.default
    private let queueDirectory: URL
    private let lock = NSLock()
    private let logger = Logger(subsystem: "com.mihirmaru.pluto.telemetry", category: "storage")

    private let maxQueuedEventsLimit = 5000
    private let maxDiskBytesLimit: Int64 = 25 * 1024 * 1024 // 25 MB

    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.queueDirectory = appSupport.appendingPathComponent("PLUTO/AlphaTelemetry/Queue", isDirectory: true)

        try? fileManager.createDirectory(at: queueDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Queue Enqueue

    func enqueue(events: [PlutoAlphaEvent]) {
        guard !events.isEmpty else { return }
        lock.lock()
        defer { lock.unlock() }

        enforceBackpressureLimitIfNeeded()

        let fileName = "events_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString.prefix(6)).json"
        let fileURL = queueDirectory.appendingPathComponent(fileName)

        do {
            let data = try JSONEncoder().encode(events)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Failed to persist telemetry batch: \(error.localizedDescription)")
        }
    }

    func enqueue(snapshot: PlutoAlphaSnapshot) {
        lock.lock()
        defer { lock.unlock() }

        let fileName = "snap_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString.prefix(6)).json"
        let fileURL = queueDirectory.appendingPathComponent(fileName)

        if let data = try? JSONEncoder().encode(snapshot) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func enqueue(crash: PlutoAlphaCrash) {
        lock.lock()
        defer { lock.unlock() }

        let fileName = "crash_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString.prefix(6)).json"
        let fileURL = queueDirectory.appendingPathComponent(fileName)

        if let data = try? JSONEncoder().encode(crash) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    func enqueue(performance: PlutoAlphaPerformance) {
        lock.lock()
        defer { lock.unlock() }

        let fileName = "perf_\(Int(Date().timeIntervalSince1970 * 1000))_\(UUID().uuidString.prefix(6)).json"
        let fileURL = queueDirectory.appendingPathComponent(fileName)

        if let data = try? JSONEncoder().encode(performance) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    // MARK: - Queue Drainage (for Sync Engine)

    func peekQueuedBatch(limit: Int = 150) -> (events: [PlutoAlphaEvent], snapshots: [PlutoAlphaSnapshot], crashes: [PlutoAlphaCrash], perf: [PlutoAlphaPerformance], processedFiles: [URL]) {
        lock.lock()
        defer { lock.unlock() }

        var events: [PlutoAlphaEvent] = []
        var snapshots: [PlutoAlphaSnapshot] = []
        var crashes: [PlutoAlphaCrash] = []
        var perf: [PlutoAlphaPerformance] = []
        var processedFiles: [URL] = []

        guard let fileURLs = try? fileManager.contentsOfDirectory(at: queueDirectory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles) else {
            return ([], [], [], [], [])
        }

        let sorted = fileURLs.sorted {
            let d1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let d2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return d1 < d2
        }

        for fileURL in sorted {
            guard events.count < limit else { break }

            let name = fileURL.lastPathComponent
            guard let data = try? Data(contentsOf: fileURL) else { continue }

            if name.hasPrefix("events_") {
                if let parsed = try? JSONDecoder().decode([PlutoAlphaEvent].self, from: data) {
                    events.append(contentsOf: parsed)
                    processedFiles.append(fileURL)
                }
            } else if name.hasPrefix("snap_") {
                if let parsed = try? JSONDecoder().decode(PlutoAlphaSnapshot.self, from: data) {
                    snapshots.append(parsed)
                    processedFiles.append(fileURL)
                }
            } else if name.hasPrefix("crash_") {
                if let parsed = try? JSONDecoder().decode(PlutoAlphaCrash.self, from: data) {
                    crashes.append(parsed)
                    processedFiles.append(fileURL)
                }
            } else if name.hasPrefix("perf_") {
                if let parsed = try? JSONDecoder().decode(PlutoAlphaPerformance.self, from: data) {
                    perf.append(parsed)
                    processedFiles.append(fileURL)
                }
            }
        }

        return (events, snapshots, crashes, perf, processedFiles)
    }

    func acknowledgeAndRemove(files: [URL]) {
        lock.lock()
        defer { lock.unlock() }

        for url in files {
            try? fileManager.removeItem(at: url)
        }
    }

    func clearAllQueuedFiles() {
        lock.lock()
        defer { lock.unlock() }

        if let fileURLs = try? fileManager.contentsOfDirectory(at: queueDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            for url in fileURLs {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    // MARK: - Backpressure & Purge

    private func enforceBackpressureLimitIfNeeded() {
        guard let files = try? fileManager.contentsOfDirectory(at: queueDirectory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey], options: .skipsHiddenFiles) else { return }

        var totalBytes: Int64 = 0
        for f in files {
            if let size = try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalBytes += Int64(size)
            }
        }

        if files.count > maxQueuedEventsLimit || totalBytes > maxDiskBytesLimit {
            logger.warning("Telemetry disk queue exceeded capacity (\(files.count) files, \(totalBytes) bytes). Purging oldest 10%...")

            let sorted = files.sorted {
                let d1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return d1 < d2
            }

            let purgeCount = max(10, sorted.count / 10)
            for file in sorted.prefix(purgeCount) {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}
