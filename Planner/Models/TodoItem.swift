import Foundation
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var notes: String
    var dueDate: Date            // 시작 날짜 (+ 시간, hasTime이 true일 때만 표시)
    var endDate: Date?           // 여러 날짜에 걸친 경우 종료 날짜
    var hasTime: Bool            // 특정 시간이 설정됐는지
    var isCompleted: Bool
    var isImportant: Bool
    var autoCarryOver: Bool      // 미완료 시 다음날 자동 이동 여부
    var reminderID: String?      // 미리 알림 앱 연동 식별자
    var labels: [PlannerLabel]
    var links: [String]

    // 연결된 마감일 (이 할일이 어떤 deadline의 세부 작업인지)
    @Relationship(inverse: \Deadline.todos)
    var deadline: Deadline?

    // 이 할일의 완료/이월 이력
    @Relationship(deleteRule: .cascade)
    var history: [TodoHistory]

    init(
        title: String,
        dueDate: Date,
        endDate: Date? = nil,
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
        self.endDate = endDate
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

    var labelList: [PlannerLabel] {
        labels
    }

    var effectiveEndDate: Date {
        endDate ?? dueDate
    }

    var isMultiDay: Bool {
        Calendar.current.startOfDay(for: dueDate) != Calendar.current.startOfDay(for: effectiveEndDate)
    }

    func includes(_ day: Date, calendar: Calendar = .current) -> Bool {
        let targetDay = calendar.startOfDay(for: day)
        let startDay = calendar.startOfDay(for: dueDate)
        let endDay = calendar.startOfDay(for: effectiveEndDate)
        let lowerBound = min(startDay, endDay)
        let upperBound = max(startDay, endDay)
        return targetDay >= lowerBound && targetDay <= upperBound
    }

    func visibleDays(startingAt lowerBound: Date? = nil, calendar: Calendar = .current) -> [Date] {
        let startDay = calendar.startOfDay(for: dueDate)
        let endDay = calendar.startOfDay(for: effectiveEndDate)
        let firstDay = max(min(startDay, endDay), lowerBound.map { calendar.startOfDay(for: $0) } ?? min(startDay, endDay))
        let lastDay = max(startDay, endDay)

        guard firstDay <= lastDay else { return [] }

        var days: [Date] = []
        var cursor = firstDay

        while cursor <= lastDay {
            days.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return days
    }
}
