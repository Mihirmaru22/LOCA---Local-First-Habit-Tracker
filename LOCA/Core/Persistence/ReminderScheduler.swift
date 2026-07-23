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
    /// - Parameters:
    ///   - board: The habit to remind about
    ///   - time: Time in HH:MM format (e.g., "06:30")
    func scheduleReminder(for board: HabitBoard, time: String) async {
        guard let (hour, minute) = parseTime(time) else { return }

        let center = UNUserNotificationCenter.current()

        // Remove any existing reminder for this habit
        center.removePendingNotificationRequests(withIdentifiers: [board.id.uuidString])

        // Create the notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to log"
        content.body = "\(board.name) — tap to log your progress"
        content.sound = .default
        content.badge = NSNumber(value: (UIApplication.shared.applicationIconBadgeNumber) + 1)

        // Attach the habit ID so we can navigate to it
        content.userInfo = ["habitID": board.id.uuidString]

        // Create a daily trigger at the specified time
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create and schedule the request
        let request = UNNotificationRequest(
            identifier: board.id.uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            // Silent fail; reminder scheduler is non-critical
        }
    }

    /// Cancel a reminder for a habit.
    func cancelReminder(for board: HabitBoard) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [board.id.uuidString]
        )
    }

    /// Cancel all reminders.
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    /// Reschedule all reminders (e.g., on app launch).
    /// Called from LOCAApp to ensure reminders persist across app updates.
    func rescheduleAllReminders(boards: [HabitBoard]) async {
        cancelAllReminders()
        for board in boards where board.preferredReminderTime != nil && board.archivedAt == nil {
            if let time = board.preferredReminderTime {
                await scheduleReminder(for: board, time: time)
            }
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
