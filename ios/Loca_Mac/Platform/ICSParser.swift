import Foundation
import UniformTypeIdentifiers

// MARK: - ICSParser (Apple Calendar .ics & Drag-to-Timeline Parser)

/// Parses RFC 5545 iCalendar (`.ics`) data from Apple Calendar, Mail, Outlook, or Finder drops
/// into structured time-block events for LOCA's Day Planner.
enum ICSParser {

    struct ParsedCalendarEvent {
        var title: String
        var startDate: Date?
        var endDate: Date?
        var durationMinutes: Int
        var location: String?
        var notes: String?
    }

    /// Parses raw `.ics` file or string content into an array of calendar events.
    static func parseICS(content: String) -> [ParsedCalendarEvent] {
        var events: [ParsedCalendarEvent] = []
        let lines = content.components(separatedBy: .newlines)

        var inEvent = false
        var currentTitle: String = "Calendar Event"
        var currentStart: Date? = nil
        var currentEnd: Date? = nil
        var currentLocation: String? = nil
        var currentDescription: String? = nil

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line == "BEGIN:VEVENT" {
                inEvent = true
                currentTitle = "Calendar Event"
                currentStart = nil
                currentEnd = nil
                currentLocation = nil
                currentDescription = nil
            } else if line == "END:VEVENT" {
                if inEvent {
                    let dur: Int
                    if let s = currentStart, let e = currentEnd {
                        dur = max(15, Int(e.timeIntervalSince(s) / 60.0))
                    } else {
                        dur = 30
                    }

                    events.append(ParsedCalendarEvent(
                        title: currentTitle,
                        startDate: currentStart,
                        endDate: currentEnd,
                        durationMinutes: dur,
                        location: currentLocation,
                        notes: currentDescription
                    ))
                }
                inEvent = false
            } else if inEvent {
                if line.hasPrefix("SUMMARY:") {
                    currentTitle = String(line.dropFirst("SUMMARY:".count))
                } else if line.hasPrefix("DTSTART") {
                    let datePart = extractDatePart(from: line)
                    currentStart = parseDate(datePart)
                } else if line.hasPrefix("DTEND") {
                    let datePart = extractDatePart(from: line)
                    currentEnd = parseDate(datePart)
                } else if line.hasPrefix("LOCATION:") {
                    currentLocation = String(line.dropFirst("LOCATION:".count))
                } else if line.hasPrefix("DESCRIPTION:") {
                    currentDescription = String(line.dropFirst("DESCRIPTION:".count))
                }
            }
        }

        return events
    }

    private static func extractDatePart(from line: String) -> String {
        if let colonIndex = line.firstIndex(of: ":") {
            return String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
        }
        return line
    }

    private static func parseDate(_ raw: String) -> Date? {
        let clean = raw.replacingOccurrences(of: "Z", with: "")

        let formatters: [DateFormatter] = [
            {
                let f = DateFormatter()
                f.dateFormat = "yyyyMMdd'T'HHmmss"
                f.timeZone = TimeZone.current
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyyMMdd"
                f.timeZone = TimeZone.current
                return f
            }()
        ]

        for f in formatters {
            if let d = f.date(from: clean) {
                return d
            }
        }
        return nil
    }
}
