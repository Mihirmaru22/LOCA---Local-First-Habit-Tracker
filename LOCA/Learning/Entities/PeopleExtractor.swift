//
//  PeopleExtractor.swift
//  LOCA
//
//  Phase 5 — Mine calendar events and logged notes for recurring people
//  Salience = frequency of appearance in 30-day rolling window
//

import Foundation
import EventKit
import SwiftData
import os.log

@MainActor
class PeopleExtractor {
    static let shared = PeopleExtractor()

    private let logger = Logger(subsystem: "com.loca.entities", category: "people")
    private let eventStore = EKEventStore()
    private let windowDays = 30
    private let minimumAppearances = 3     // Person must appear ≥3× to be stored

    // Common words to exclude from name extraction
    private let stopWords: Set<String> = [
        "meeting", "with", "and", "call", "zoom", "teams", "lunch", "dinner",
        "coffee", "sync", "standup", "review", "interview", "workshop", "team",
        "the", "a", "an", "for", "at", "of", "to", "in", "on", "by", "from"
    ]

    // MARK: - Entry Point

    func extractPeople(modelContext: ModelContext) async throws {
        let windowStart = Calendar.current.date(byAdding: .day, value: -windowDays, to: Date())!

        // Mine calendar titles
        let calendarNames = await mineCalendarTitles(since: windowStart)

        // Mine explicit logs
        let logNames = try mineLoggedNotes(since: windowStart, modelContext: modelContext)

        // Merge and count appearances
        var nameCounts: [String: (count: Int, contexts: [RelationshipContext], sources: [String])] = [:]

        for (name, context) in calendarNames {
            let key = normalize(name)
            nameCounts[key, default: (0, [], [])].count += 1
            nameCounts[key]?.contexts.append(context)
            nameCounts[key]?.sources.append("calendar")
        }

        for name in logNames {
            let key = normalize(name)
            nameCounts[key, default: (0, [], [])].count += 1
            nameCounts[key]?.contexts.append(.unknown)
            nameCounts[key]?.sources.append("note")
        }

        // Persist only recurring people.
        // C2.3: primaryContext is subject-authoritative — only the user may set it.
        // Detected contexts from signals go to detectedContexts (sensor evidence only).
        for (name, data) in nameCounts where data.count >= minimumAppearances {
            upsertPerson(
                name: name,
                appearanceCount: data.count,
                detectedContexts: data.contexts,
                windowStart: windowStart,
                modelContext: modelContext
            )
        }

        try modelContext.save()
        logger.info("People extraction complete — \(nameCounts.count) candidates, \(nameCounts.filter { $0.value.count >= self.minimumAppearances }.count) stored")
    }

    // MARK: - Calendar Mining

    private func mineCalendarTitles(since start: Date) async -> [(String, RelationshipContext)] {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            return []
        }

        let predicate = eventStore.predicateForEvents(withStart: start, end: Date(), calendars: nil)
        let events = eventStore.events(matching: predicate)

        var results: [(String, RelationshipContext)] = []

        for event in events {
            let title = event.title ?? ""
            let names = extractNames(from: title)
            let context = classifyCalendarContext(event: event)
            for name in names {
                results.append((name, context))
            }

            // Also check attendees if available
            if let attendees = event.attendees {
                for attendee in attendees where attendee.participantType == .person {
                    let attendeeName = attendee.name ?? ""
                    if !attendeeName.isEmpty && attendeeName.split(separator: " ").count >= 2 {
                        results.append((attendeeName, context))
                    }
                }
            }
        }

        return results
    }

    // MARK: - Log Mining

    private func mineLoggedNotes(since start: Date, modelContext: ModelContext) throws -> [String] {
        let descriptor = FetchDescriptor<SignalEvent>(
            predicate: #Predicate { signal in
                signal.timestamp >= start
            }
        )

        let allSignals = try modelContext.fetch(descriptor)
        let logs = allSignals.filter { $0.source == .explicitLog }
        var names: [String] = []

        for log in logs {
            if let text = log.metadata["text"] {
                names.append(contentsOf: extractNames(from: text))
            }
        }

        return names
    }

    // MARK: - Name Extraction

    // Heuristic: capitalized multi-word tokens that aren't stop words
    private func extractNames(from text: String) -> [String] {
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted.union(.whitespaces).inverted)
            .flatMap { $0.components(separatedBy: .whitespaces) }
            .filter { !$0.isEmpty }

        var names: [String] = []
        var i = 0

        while i < words.count {
            let word = words[i]
            guard word.first?.isUppercase == true,
                  word.count > 1,
                  !stopWords.contains(word.lowercased()) else {
                i += 1
                continue
            }

            // Look ahead for a second capitalized word (first + last name pattern)
            if i + 1 < words.count {
                let next = words[i + 1]
                if next.first?.isUppercase == true,
                   next.count > 1,
                   !stopWords.contains(next.lowercased()) {
                    names.append("\(word) \(next)")
                    i += 2
                    continue
                }
            }

            i += 1
        }

        return names
    }

    // MARK: - Context Classification

    private func classifyCalendarContext(event: EKEvent) -> RelationshipContext {
        let hour = Calendar.current.component(.hour, from: event.startDate)
        let title = (event.title ?? "").lowercased()

        if title.contains("family") || title.contains("parents") || title.contains("kids") {
            return .family
        }

        let workKeywords = ["standup", "sync", "review", "interview", "sprint", "meeting", "call"]
        if workKeywords.contains(where: { title.contains($0) }) || (8...18).contains(hour) {
            return .work
        }

        let socialKeywords = ["lunch", "dinner", "drinks", "coffee", "birthday", "party", "catch up"]
        if socialKeywords.contains(where: { title.contains($0) }) {
            return .social
        }

        return .recurring
    }

    // MARK: - Helpers

    private func normalize(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }

    // MARK: - Upsert

    private func upsertPerson(
        name: String,
        appearanceCount: Int,
        detectedContexts: [RelationshipContext],
        windowStart: Date,
        modelContext: ModelContext
    ) {
        let descriptor = FetchDescriptor<Person>(
            predicate: #Predicate { person in
                person.name == name
            }
        )

        let salience = min(1.0, Double(appearanceCount) / 20.0)  // 20 appearances = max salience
        let uncertainty = max(0.15, 0.8 - Double(appearanceCount) * 0.05)
        let rawContexts = detectedContexts.map { $0.rawValue }

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.salience = existing.salience * 0.7 + salience * 0.3
            existing.salienceUncertainty = min(existing.salienceUncertainty, uncertainty)
            existing.appearanceCount += appearanceCount
            existing.lastSeenDate = Date()
            // C2.3: primaryContext is subject-authoritative — never overwritten by sensor inference.
            // Sensor-detected contexts are stored as evidence in detectedContexts only.
            existing.detectedContexts = rawContexts
            existing.updatedAt = Date()
        } else {
            let person = Person(name: name)
            person.salience = salience
            person.salienceUncertainty = uncertainty
            person.appearanceCount = appearanceCount
            person.detectedContexts = rawContexts
            modelContext.insert(person)
        }
    }
}
