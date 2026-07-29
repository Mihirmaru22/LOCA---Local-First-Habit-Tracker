//
//  SourceProvenanceManager.swift
//  LOCA
//
//  C3.4 — Maintains the instrument provenance ledger.
//  Called after each collection cycle. For every source that produced signals
//  this cycle: upserts a SourceProvenance record and marks it active.
//  For previously-active sources that produced nothing: marks them inactive
//  (lastActiveAt records when they last contributed; beliefs formed in that
//  window remain valid — the ledger just notes the instrument is gone).
//

import Foundation
import SwiftData
import os.log

@MainActor
final class SourceProvenanceManager {
    static let shared = SourceProvenanceManager()

    private let logger = Logger(subsystem: "com.loca.signals", category: "provenance")

    // MARK: - Public API

    /// Updates the provenance ledger for the given collection of signals.
    /// Call this after inserting signals into the store but before saving.
    func updateProvenance(for signals: [SignalEvent], modelContext: ModelContext) {
        let now = Date()
        let activeSources = Set(signals.map { $0.source.rawValue })
        let countsBySources = Dictionary(
            signals.map { ($0.source.rawValue, 1) },
            uniquingKeysWith: +
        )

        // Fetch all existing provenance records
        let descriptor = FetchDescriptor<SourceProvenance>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        var ledger = Dictionary(existing.map { ($0.sourceName, $0) }, uniquingKeysWith: { a, _ in a })

        // Upsert for every source that produced signals this cycle
        for sourceName in activeSources {
            let count = countsBySources[sourceName] ?? 0
            if let record = ledger[sourceName] {
                record.lastActiveAt = now
                record.isActive = true
                record.totalObservations += count
            } else {
                let record = SourceProvenance(sourceName: sourceName, firstSeenAt: now)
                record.totalObservations = count
                modelContext.insert(record)
                ledger[sourceName] = record
                logger.info("New source observed: \(sourceName)")
            }
        }

        // Mark previously-active sources as inactive if they produced nothing
        for (sourceName, record) in ledger where !activeSources.contains(sourceName) && record.isActive {
            record.isActive = false
            logger.info("Source went inactive: \(sourceName), last active \(record.lastActiveAt)")
        }
    }
}
