import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var notes: String
    var dueDate: Date            // 귀속 날짜 (+ 시간, hasTime이 true일 때만 표시)
    var hasTime: Bool            // 특정 시간이 설정됐는지
    var isCompleted: Bool
    var isImportant: Bool
    var autoCarryOver: Bool      // 미완료 시 다음날 자동 이동 여부
    var reminderID: String?      // 미리 알림 앱 연동 식별자
    var labels: [PlannerLabel]
    var links: [String]

    // 연결된 마감일 (이 할일이 어떤 deadline의 세부 작업인지)
    var deadline: Deadline?

    // 이 할일의 완료/이월 이력
    @Relationship(deleteRule: .cascade)
    var history: [TodoHistory]

    init(
        title: String,
        dueDate: Date,
        hasTime: Bool = false,
        notes: String = "",
        isImportant: Bool = false,
        autoCarryOver: Bool = true,
        deadline: Deadline? = nil,
        labels: [PlannerLabel] = [],
        links: [String] = []
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.hasTime = hasTime
        self.isCompleted = false
        self.isImportant = isImportant
        self.autoCarryOver = autoCarryOver
        self.reminderID = nil
        self.deadline = deadline
        self.labels = labels
        self.links = links
        self.history = []
    }
}
