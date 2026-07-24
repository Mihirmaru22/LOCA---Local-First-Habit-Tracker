//
//  CalendarManager.swift
//  LOCA
//
//  Calendar event ingestion
//

import Foundation
import EventKit

@MainActor
class CalendarManager: NSObject {
    private let eventStore = EKEventStore()
    private var isAuthorized = false

    override init() {
        super.init()
        requestAuthorization()
    }

    private func requestAuthorization() {
        eventStore.requestFullAccessToEvents { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }
        }
    }

    // MARK: - Calendar Collection

    func collectCalendarEvents() async throws -> [SignalEvent] {
        guard isAuthorized else { return [] }

        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        let now = Date()

        let predicate = eventStore.predicateForEvents(
            withStart: thirtyDaysAgo,
            end: now
        )

        let events = eventStore.events(matching: predicate)
        var signals: [SignalEvent] = []

        var eventsByHour: [Date: [EKEvent]] = [:]

        for event in events {
            guard !event.isAllDay else { continue }

            let hourStart = calendar.dateComponents([.year, .month, .day, .hour], from: event.startDate)
            guard let hourStartDate = calendar.date(from: hourStart) else { continue }

            if eventsByHour[hourStartDate] == nil {
                eventsByHour[hourStartDate] = []
            }
            eventsByHour[hourStartDate]?.append(event)
        }

        for (hourStart, hourEvents) in eventsByHour {
            let eventDensity = Double(hourEvents.count) / 5.0
            let normalized = min(1.0, eventDensity)

            let signal = SignalEvent(
                timestamp: hourStart,
                source: .calendar,
                value: normalized,
                uncertainty: 0.05,
                metadata: [
                    "event_count": String(hourEvents.count),
                    "event_titles": hourEvents.prefix(3).map { $0.title }.joined(separator: ", ")
                ]
            )
            signals.append(signal)
        }

        return signals
    }
}
