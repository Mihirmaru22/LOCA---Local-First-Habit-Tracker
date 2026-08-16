import SwiftData
import Foundation

// MARK: - FocusSession (SwiftData Model)

@Model
final class FocusSession {
    var id: UUID = UUID()
    var startTime: Date = Date()
    var endTime: Date? = nil
    var durationSeconds: Int = 0
    var sessionTag: String = "Study Stream"
    var backgroundCategory: String = "City"
    
    @Relationship(deleteRule: .cascade)
    var goals: [FocusGoal] = []

    init(id: UUID = UUID(), startTime: Date = Date(), sessionTag: String = "Study Stream", backgroundCategory: String = "City") {
        self.id = id
        self.startTime = startTime
        self.endTime = nil
        self.durationSeconds = 0
        self.sessionTag = sessionTag
        self.backgroundCategory = backgroundCategory
        self.goals = []
    }
}

// MARK: - FocusGoal (SwiftData Model)

@Model
final class FocusGoal {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var sessionDate: Date = Date()

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, createdAt: Date = Date(), sessionDate: Date = Date()) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.sessionDate = sessionDate
    }
}
