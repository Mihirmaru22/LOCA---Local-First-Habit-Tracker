import SwiftData
import Foundation

// MARK: - SleepEntry

/// One sleep record per calendar day, captured in Journal → Collect.
///
/// Supports two input modes (stored as `inputModeRaw`):
/// - `.bedtimeWake` — user enters bedtime + wake time; `sleepHours` is computed
///    and stored. Past-midnight bedtimes (e.g. 11:20 PM → 6:50 AM) are handled
///    by checking whether bedtime > wakeTime and adding 24 h when so.
/// - `.totalHours` — user enters hours directly; `bedtime`/`wakeTime` are `nil`.
///
/// Both modes write a single `sleepHours: Double` value, which is the canonical
/// fact for the Analyse graph and stat card. The input mode is remembered via
/// `SleepEntry.lastInputModeRaw` in `UserDefaults` so the Collect view restores
/// the user's last choice on each visit.
///
/// CloudKit constraints: no `@Attribute(.unique)`, every property has a default.
@Model
final class SleepEntry {

    var id:           UUID    = UUID()
    /// The calendar day this entry covers (always `startOfDay`).
    var date:         Date    = Date()
    /// Canonical sleep duration in hours. Always set regardless of input mode.
    var sleepHours:   Double  = 0.0
    /// Raw storage for `SleepInputMode`. 0 = bedtimeWake, 1 = totalHours.
    var inputModeRaw: Int     = SleepInputMode.bedtimeWake.rawValue
    /// Set when inputMode == .bedtimeWake. Nil otherwise.
    var bedtime:      Date?   = nil
    /// Set when inputMode == .bedtimeWake. Nil otherwise.
    var wakeTime:     Date?   = nil
    var archivedAt:   Date?   = nil

    var isArchived: Bool { archivedAt != nil }

    var inputMode: SleepInputMode {
        get { SleepInputMode(rawValue: inputModeRaw) ?? .bedtimeWake }
        set { inputModeRaw = newValue.rawValue }
    }

    init(date: Date = Date(),
         sleepHours: Double,
         inputMode: SleepInputMode = .bedtimeWake,
         bedtime: Date? = nil,
         wakeTime: Date? = nil) {
        self.date         = Calendar.current.startOfDay(for: date)
        self.sleepHours   = sleepHours
        self.inputModeRaw = inputMode.rawValue
        self.bedtime      = bedtime
        self.wakeTime     = wakeTime
    }
}

// MARK: - SleepInputMode

extension SleepEntry {

    enum SleepInputMode: Int, CaseIterable {
        case bedtimeWake = 0
        case totalHours  = 1
    }

    // MARK: - sleepHours helper

    /// Computes sleep duration from `bedtime` and `wakeTime`, handling past-midnight
    /// crossings. Returns duration in hours based on time-of-day components.
    static func computeSleepHours(bedtime: Date, wakeTime: Date) -> Double {
        let cal = Calendar.current
        let bedMinutes = cal.component(.hour, from: bedtime) * 60 + cal.component(.minute, from: bedtime)
        let wakeMinutes = cal.component(.hour, from: wakeTime) * 60 + cal.component(.minute, from: wakeTime)
        var diff = wakeMinutes - bedMinutes
        if diff < 0 { diff += 24 * 60 }
        return Double(diff) / 60.0
    }

    // MARK: - UserDefaults persistence of last input mode

    private static let lastInputModeKey = "com.loca.sleep.lastInputMode"

    static var lastInputMode: SleepInputMode {
        get {
            let raw = UserDefaults.standard.integer(forKey: lastInputModeKey)
            return SleepInputMode(rawValue: raw) ?? .bedtimeWake
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: lastInputModeKey)
        }
    }
}
