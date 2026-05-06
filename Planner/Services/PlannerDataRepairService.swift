import Foundation
import SwiftData

enum PlannerDataRepairService {
    static func repair(modelContext: ModelContext) throws {
        var didChange = false

        let labels = try modelContext.fetch(FetchDescriptor<PlannerLabel>())
        didChange = repairDuplicateUUIDs(in: labels, id: \.id) || didChange

        let deadlines = try modelContext.fetch(FetchDescriptor<Deadline>())
        didChange = repairDuplicateUUIDs(in: deadlines, id: \.id) || didChange
        didChange = normalizeReminderIDs(in: deadlines) || didChange

        let todos = try modelContext.fetch(FetchDescriptor<TodoItem>())
        didChange = repairDuplicateUUIDs(in: todos, id: \.id) || didChange

        let histories = try modelContext.fetch(FetchDescriptor<TodoHistory>())
        didChange = repairDuplicateUUIDs(in: histories, id: \.id) || didChange

        if didChange {
            try modelContext.save()
        }
    }

    private static func repairDuplicateUUIDs<T: AnyObject>(
        in items: [T],
        id: ReferenceWritableKeyPath<T, UUID>
    ) -> Bool where T: PersistentModel {
        var didChange = false

        for group in Dictionary(grouping: items, by: { $0[keyPath: id] }).values where group.count > 1 {
            for duplicate in group.dropFirst() {
                duplicate[keyPath: id] = UUID()
                didChange = true
            }
        }

        return didChange
    }

    private static func normalizeReminderIDs(in deadlines: [Deadline]) -> Bool {
        var didChange = false
        var seen = Set<String>()

        for deadline in deadlines {
            let trimmed = deadline.reminderID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if trimmed.isEmpty {
                if deadline.reminderID != nil {
                    deadline.reminderID = nil
                    didChange = true
                }
                continue
            }

            if deadline.reminderID != trimmed {
                deadline.reminderID = trimmed
                didChange = true
            }

            if seen.contains(trimmed) {
                deadline.reminderID = nil
                didChange = true
                continue
            }

            seen.insert(trimmed)
        }

        return didChange
    }
}
