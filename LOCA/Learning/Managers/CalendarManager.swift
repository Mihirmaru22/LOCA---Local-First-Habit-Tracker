//
//  CalendarManager.swift
//  LOCA
//
//  C3.2 — Calendar context ingestion
//  Event density, type classification, and attendee count → SignalEvents.
//  Authorization is checked via EKEventStore.authorizationStatus (queryable,
//  unlike HealthKit read auth). Removed eager auth from init; the coordinator
//  and ContextPermissionView handle the permission flow.
//

import Foundation
import EventKit

@MainActor
class CalendarManager: NSObject {
    private let eventStore = EKEventStore()

    // MARK: - Calendar Collection

    func collectCalendarEvents() async -> [SignalEvent] {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else { return [] }

        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        let now = Date()

        let predicate = eventStore.predicateForEvents(
            withStart: thirtyDaysAgo,
            end: now,
            calendars: nil
        )

        let events = eventStore.events(matching: predicate)
        var eventsByHour: [Date: [EKEvent]] = [:]

        for event in events {
            guard !event.isAllDay, let startDate = event.startDate else { continue }
            let hourComponents = calendar.dateComponents([.year, .month, .day, .hour], from: startDate)
            guard let hourStart = calendar.date(from: hourComponents) else { continue }
            eventsByHour[hourStart, default: []].append(event)
        }

        return eventsByHour.map { (hourStart, hourEvents) in
            let density = min(1.0, Double(hourEvents.count) / 5.0)
            let attendeeCount = hourEvents.compactMap { $0.attendees?.count }.reduce(0, +)
            let eventType = dominantEventType(hourEvents)

            return SignalEvent(
                timestamp: hourStart,
                source: .calendar,
                value: density,
                uncertainty: 0.05,
                metadata: [
                    "event_count":    String(hourEvents.count),
                    "attendee_count": String(attendeeCount),
                    "event_type":     eventType,
                    "titles":         hourEvents.prefix(3).compactMap { $0.title }.joined(separator: ", "),
                ]
            )
        }
    }

    // MARK: - Event Type Classification

    private func dominantEventType(_ events: [EKEvent]) -> String {
        var counts: [String: Int] = ["work": 0, "social": 0, "focus": 0, "personal": 0]

        for event in events {
            let title = (event.title ?? "").lowercased()
            let hour = Calendar.current.component(.hour, from: event.startDate)

            if ["standup", "sync", "review", "interview", "sprint", "meeting", "call", "1:1"].contains(where: { title.contains($0) })
                || (8...18).contains(hour) && (event.attendees?.count ?? 0) > 1 {
                counts["work", default: 0] += 1
            } else if ["focus", "deep work", "writing", "coding", "study", "heads down"].contains(where: { title.contains($0) }) {
                counts["focus", default: 0] += 1
            } else if ["lunch", "dinner", "drinks", "coffee", "birthday", "party", "catch up", "brunch"].contains(where: { title.contains($0) }) {
                counts["social", default: 0] += 1
            } else {
                counts["personal", default: 0] += 1
            }
        }

        return counts.max(by: { $0.value < $1.value })?.key ?? "personal"
    }
}
