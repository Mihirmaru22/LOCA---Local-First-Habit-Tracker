//
//  ChapterModel.swift
//  LOCA
//
//  Phase 5 — Chapter entity
//  Chapters are intervals between Life Events.
//  The event is the door; the chapter is the room.
//

import Foundation
import SwiftData

// MARK: - Chapter

@Model
final class Chapter {
    var id: UUID = UUID()

    // Temporal bounds
    var startDate: Date              // Day of opening Life Event (or app install)
    var endDate: Date?               // Day of closing Life Event; nil = current chapter

    // Identity
    var name: String                 // User-editable label e.g. "The Internship"
    var userDescription: String?     // Free-form reflection

    // Bookend events
    var openingEventId: UUID?        // The Life Event that started this chapter
    var closingEventId: UUID?        // The Life Event that ended this chapter

    // Learned baseline for this chapter (mean state values)
    var baselineEnergy: Double       // Chapter's typical energy level
    var baselineStress: Double
    var baselineFocus: Double
    var baselineMood: Double

    // Characterization
    var dominantEventType: String?   // Most common event type during chapter
    var activityLevel: Double        // 0–1 normalized step/motion average
    var socialEngagement: Double     // 0–1 normalized social signal average
    var scheduleRegularity: Double   // 0–1 how consistent daily patterns were

    // Quality signal (derived, not prescribed)
    var volatility: Double           // Std-dev of mood across chapter; high = turbulent

    // Metadata
    var createdAt: Date = Date()
    var isCurrentChapter: Bool       // True for the open (latest) chapter

    init(
        startDate: Date,
        name: String,
        openingEventId: UUID? = nil
    ) {
        self.startDate = startDate
        self.name = name
        self.openingEventId = openingEventId
        self.baselineEnergy = 0.5
        self.baselineStress = 0.5
        self.baselineFocus = 0.5
        self.baselineMood = 0.5
        self.activityLevel = 0.5
        self.socialEngagement = 0.5
        self.scheduleRegularity = 0.5
        self.volatility = 0.2
        self.endDate = nil
        self.isCurrentChapter = true
    }

    var duration: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate)
    }

    var durationInDays: Int {
        Int(duration / 86400)
    }

    var isClosed: Bool {
        endDate != nil
    }
}
