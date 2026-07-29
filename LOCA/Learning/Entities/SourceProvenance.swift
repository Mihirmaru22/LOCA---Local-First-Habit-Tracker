//
//  SourceProvenance.swift
//  LOCA
//
//  C3.4 — Provenance ledger for signal source availability.
//  Records when each SignalSource was first observed, when it was last
//  active, and whether it produced signals in the most recent collection
//  cycle. Beliefs formed under a richer instrument reference this ledger
//  so they remain legible — and non-invalidated — when that instrument
//  is later lost.
//

import Foundation
import SwiftData

@Model final class SourceProvenance {
    var id: UUID = UUID()

    /// `SignalSource.rawValue` — string keyed for CloudKit compatibility.
    var sourceName: String = ""

    /// When the first `SignalEvent` from this source was ever collected.
    var firstSeenAt: Date = Date()

    /// The most recent time signals from this source were successfully collected.
    var lastActiveAt: Date = Date()

    /// True when signals from this source were observed in the last collection cycle.
    /// Transitions to false the first cycle a previously-active source produces nothing.
    var isActive: Bool = true

    /// Running count of all `SignalEvent`s from this source ever collected.
    var totalObservations: Int = 0

    init(sourceName: String, firstSeenAt: Date = Date()) {
        self.id = UUID()
        self.sourceName = sourceName
        self.firstSeenAt = firstSeenAt
        self.lastActiveAt = firstSeenAt
        self.isActive = true
        self.totalObservations = 0
    }
}
