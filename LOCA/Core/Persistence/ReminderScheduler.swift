//
//  ReminderScheduler.swift
//  LOCA
//
//  Phase 3.1 — Smart reminder delivery via LocalNotifications.
//
//  Schedules and manages local notifications for habits with
//  preferredReminderTime set. Handles permission requests, scheduling,
//  and cleanup when habits are archived.
//

import UserNotifications
import Foundation

/// A `Sendable` snapshot of the reminder-relevant fields of a habit.
///
/// `HabitBoard` is a SwiftData `@Model` and is not `Sendable`, so it cannot
/// cross the `ReminderScheduler` actor boundary without risking a data race.
/// Callers extract these plain value fields on the MainActor and hand the
/// scheduler this immutable, `Sendable` struct instead.
struct ReminderRequest: Sendable {
    let id: UUID
    let name: String
    /// Time in HH:MM format (e.g., "06:30").
    let time: String
}

actor ReminderScheduler {

    static let shared = ReminderScheduler()

    /// Request notification permission from the user.
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    /// Schedule a daily reminder for a habit.
    /// - Parameter request: The `Sendable` reminder snapshot for the habit.
    func scheduleReminder(_ request: ReminderRequest) async {
        guard let (hour, minute) = parseTime(request.time) else { return }

        let center = UNUserNotificationCenter.current()
        let identifier = request.id.uuidString

        // Remove any existing reminder for this habit
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        // Create the notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to log"
        content.body = "\(request.name) — tap to log your progress"
        content.sound = .default

        // Attach the habit ID so we can navigate to it
        content.userInfo = ["habitID": identifier]

        // Create a daily trigger at the specified time
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create and schedule the request
        let notificationRequest = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(notificationRequest)
        } catch {
            // Silent fail; reminder scheduler is non-critical
        }
    }

    /// Cancel a reminder for a habit.
    func cancelReminder(id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [id.uuidString]
        )
    }

    /// Cancel all reminders.
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Reschedule all reminders (e.g., on app launch).
    /// Called from LOCAApp to ensure reminders persist across app updates.
    /// - Parameter requests: `Sendable` snapshots for the active habits that
    ///   have a reminder time set. The caller is responsible for filtering out
    ///   archived habits and those without a `preferredReminderTime`.
    func rescheduleAllReminders(_ requests: [ReminderRequest]) async {
        cancelAllReminders()
        for request in requests {
            await scheduleReminder(request)
        }
    }

    // MARK: - Private

    private func parseTime(_ timeString: String) -> (hour: Int, minute: Int)? {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]),
              (0..<24).contains(hour),
              (0..<60).contains(minute)
        else {
            return nil
        }
        return (hour, minute)
    }
}
