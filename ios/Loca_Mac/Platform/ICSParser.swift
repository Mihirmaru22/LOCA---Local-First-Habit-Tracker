import Foundation
import UniformTypeIdentifiers

// MARK: - ICSParser (RFC 5545 Compliant Calendar & Timeline Parser)

/// Robust parser for RFC 5545 iCalendar (`.ics`) files and drag-and-drop payloads from
/// Apple Calendar, Google Calendar, Outlook, and Mail.
enum ICSParser {

    struct ParsedCalendarEvent: Sendable, Identifiable {
        var id: UUID = UUID()
        var title: String
        var startDate: Date?
        var endDate: Date?
        var durationMinutes: Int
        var location: String?
        var notes: String?
    }

    /// Parses raw `.ics` file or string content into an array of structured calendar events.
    static func parseICS(content: String) -> [ParsedCalendarEvent] {
        var events: [ParsedCalendarEvent] = []
        let rawLines = content.components(separatedBy: .newlines)
        
        // 1. Unfold RFC 5545 continuation lines (lines starting with space or tab)
        var unfoldedLines: [String] = []
        for line in rawLines {
            if (line.hasPrefix(" ") || line.hasPrefix("\t")), let lastIndex = unfoldedLines.indices.last {
                unfoldedLines[lastIndex].append(String(line.dropFirst()))
            } else {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    unfoldedLines.append(trimmed)
                }
            }
        }

        var inEvent = false
        var currentTitle: String = "Calendar Event"
        var currentStart: Date? = nil
        var currentEnd: Date? = nil
        var currentLocation: String? = nil
        var currentDescription: String? = nil

        for line in unfoldedLines {
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
                        title: unescapeText(currentTitle),
                        startDate: currentStart,
                        endDate: currentEnd,
                        durationMinutes: dur,
                        location: currentLocation.map(unescapeText),
                        notes: currentDescription.map(unescapeText)
                    ))
                }
                inEvent = false
            } else if inEvent {
                if line.hasPrefix("SUMMARY:") || line.hasPrefix("SUMMARY;") {
                    currentTitle = extractValuePart(from: line)
                } else if line.hasPrefix("DTSTART") {
                    currentStart = parseDate(from: line)
                } else if line.hasPrefix("DTEND") {
                    currentEnd = parseDate(from: line)
                } else if line.hasPrefix("LOCATION:") || line.hasPrefix("LOCATION;") {
                    currentLocation = extractValuePart(from: line)
                } else if line.hasPrefix("DESCRIPTION:") || line.hasPrefix("DESCRIPTION;") {
                    currentDescription = extractValuePart(from: line)
                }
            }
        }

        return events
    }

    private static func extractValuePart(from line: String) -> String {
        if let colonIndex = line.firstIndex(of: ":") {
            return String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
        }
        return line
    }

    private static func parseDate(from line: String) -> Date? {
        let value = extractValuePart(from: line)
        let isUTC = value.hasSuffix("Z")
        let clean = value.replacingOccurrences(of: "Z", with: "")

        // Extract custom TZID if specified in DTSTART;TZID=America/New_York:...
        var targetTimeZone: TimeZone = isUTC ? (TimeZone(secondsFromGMT: 0) ?? .current) : .current
        if line.contains("TZID="),
           let tzidRange = line.range(of: "TZID="),
           let semiOrColon = line[tzidRange.upperBound...].firstIndex(where: { $0 == ":" || $0 == ";" }) {
            let tzidString = String(line[tzidRange.upperBound..<semiOrColon])
            if let customTZ = TimeZone(identifier: tzidString) {
                targetTimeZone = customTZ
            }
        }

        let formatters: [DateFormatter] = [
            {
                let f = DateFormatter()
                f.dateFormat = "yyyyMMdd'T'HHmmss"
                f.timeZone = targetTimeZone
                f.locale = Locale(identifier: "en_US_POSIX")
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyyMMdd"
                f.timeZone = targetTimeZone
                f.locale = Locale(identifier: "en_US_POSIX")
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

    private static func unescapeText(_ text: String) -> String {
        text.replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\N", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
