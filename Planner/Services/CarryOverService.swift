import Foundation
import SwiftData

enum CarryOverService {
    private static let lastRunKey = "carryOverLastRunDate"

    static func carryOverIfNeeded(modelContext: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastRun = UserDefaults.standard.object(forKey: lastRunKey) as? Date,
           calendar.startOfDay(for: lastRun) >= today {
            return
        }

        do {
            let todos = try modelContext.fetch(FetchDescriptor<TodoItem>())
            var didChange = false

            for todo in todos {
                guard !todo.isCompleted,
                      todo.autoCarryOver,
                      !todo.isMultiDay,
                      calendar.startOfDay(for: todo.dueDate) < today
                else { continue }

                let history = TodoHistory(
                    originalDate: todo.dueDate,
                    wasCompleted: false,
                    carriedOverTo: today,
                    todo: todo
                )
                modelContext.insert(history)
                todo.history.append(history)

                todo.dueDate = todo.hasTime
                    ? calendar.date(
                        bySettingHour: calendar.component(.hour, from: todo.dueDate),
                        minute: calendar.component(.minute, from: todo.dueDate),
                        second: 0,
                        of: today
                      ) ?? today
                    : today

                todo.touchForSync()
                didChange = true
            }

            if didChange {
                try modelContext.save()
            }

            UserDefaults.standard.set(Date(), forKey: lastRunKey)
        } catch {
            // carry-over는 부가 기능이므로 실패해도 앱 동작에 영향 없음
        }
    }
}
