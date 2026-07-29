//
//  SignalSourceConsent.swift
//  LOCA
//
//  C3.4 — The consent ledger.
//  A durable, per-source record of what the user allows LOCA to ingest,
//  revocable at any time. Distinct from SourceProvenance (which records what
//  was *observed*); this records what is *permitted*. Backed by UserDefaults
//  so a toggle survives relaunch and takes effect on the very next collection
//  cycle — no schema, no CloudKit surface for a device-local permission.
//
//  "Done when: toggling a source off immediately stops its ingestion" — the
//  collection loop consults `isEnabled(_:)` before invoking each collector.
//

import Foundation

/// The set of passive sources the user can individually revoke.
/// `explicitLog` is intentionally excluded — habit logs are the user's own
/// authoritative acts, not a passive sensor to consent to.
enum ConsentableSource: String, CaseIterable, Identifiable {
    case sleep
    case heartRate
    case heartRateVariability
    case steps
    case workout
    case mindfulSession
    case calendar
    case location
    case motionActivity
    case daylight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sleep:                return "Sleep"
        case .heartRate:            return "Heart Rate"
        case .heartRateVariability: return "HRV"
        case .steps:                return "Steps"
        case .workout:              return "Workouts"
        case .mindfulSession:       return "Mindful Minutes"
        case .calendar:             return "Calendar"
        case .location:             return "Location"
        case .motionActivity:       return "Motion"
        case .daylight:             return "Daylight"
        }
    }
}

/// The durable consent ledger. Every source defaults to enabled; the user may
/// revoke any of them, and the choice persists.
@MainActor
final class SignalSourceConsent: ObservableObject {
    static let shared = SignalSourceConsent()

    private let defaults = UserDefaults.standard
    private static func key(for source: ConsentableSource) -> String {
        "com.loca.consent.\(source.rawValue)"
    }

    /// Whether the user permits ingestion from this source. Absent key = enabled
    /// (opt-out model — a granted OS permission is the real gate; this is the
    /// user's finer-grained override).
    func isEnabled(_ source: ConsentableSource) -> Bool {
        defaults.object(forKey: Self.key(for: source)) as? Bool ?? true
    }

    func setEnabled(_ enabled: Bool, for source: ConsentableSource) {
        defaults.set(enabled, forKey: Self.key(for: source))
        objectWillChange.send()
    }
}
