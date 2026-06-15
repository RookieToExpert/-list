import Foundation

struct Goal: Identifiable, Codable, Equatable {
    var id: UUID
    var planListId: UUID
    var parentId: UUID?
    var title: String
    var note: String
    var level: GoalLevel
    var isCompleted: Bool
    var completedAt: Date?
    var isUrgent: Bool
    var createdAt: Date
    var updatedAt: Date
    var sortOrder: Double

    init(
        id: UUID = UUID(),
        planListId: UUID,
        parentId: UUID? = nil,
        title: String,
        note: String = "",
        level: GoalLevel,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        isUrgent: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        sortOrder: Double
    ) {
        self.id = id
        self.planListId = planListId
        self.parentId = parentId
        self.title = title
        self.note = note
        self.level = level
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.isUrgent = isUrgent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortOrder = sortOrder
    }
}
