import Foundation
import SwiftData

@Model
final class Deadline {
    var id: UUID
    var title: String
    var notes: String
    var dueDate: Date            // 마감 날짜 (+ 시간, hasTime이 true일 때만 표시)
    var hasTime: Bool            // 특정 시간이 설정됐는지
    var startDate: Date?         // 기간의 시작일 (span 표시용)
    var isCompleted: Bool
    var isImportant: Bool
    var calendarEventID: String? // 캘린더 앱 연동 식별자
    var reminderID: String?      // 미리 알림 앱 연동 식별자
    var labels: [PlannerLabel]
    var links: [String]

    // 이 마감일에 연결된 할일 목록 (inverse relationship)
    @Relationship(deleteRule: .nullify, inverse: \TodoItem.deadline)
    var todos: [TodoItem]

    init(
        title: String,
        dueDate: Date,
        hasTime: Bool = false,
        startDate: Date? = nil,
        notes: String = "",
        isImportant: Bool = false,
        labels: [PlannerLabel] = [],
        links: [String] = []
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.hasTime = hasTime
        self.startDate = startDate
        self.isCompleted = false
        self.isImportant = isImportant
        self.calendarEventID = nil
        self.reminderID = nil
        self.labels = labels
        self.links = links
        self.todos = []
    }

    var labelList: [PlannerLabel] {
        labels
    }

    var todoList: [TodoItem] {
        todos
    }
}
