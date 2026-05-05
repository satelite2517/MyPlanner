import EventKit
import Foundation
import SwiftData

struct ReminderSyncResult {
    let importedCount: Int
    let removedCount: Int
}

enum ReminderSyncError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Reminders access was denied."
        }
    }
}

@MainActor
struct ReminderSyncService {
    private let store = EKEventStore()

    func syncDeadlines(from modelContext: ModelContext) async throws -> ReminderSyncResult {
        let granted = try await requestAccess()
        guard granted else {
            throw ReminderSyncError.accessDenied
        }

        let reminders = try await fetchReminders()
        let fetchedDeadlines = try modelContext.fetch(FetchDescriptor<Deadline>())
        let existingImported = fetchedDeadlines.filter { $0.reminderID != nil }
        let importedByID = Dictionary(uniqueKeysWithValues: existingImported.compactMap { deadline in
            deadline.reminderID.map { ($0, deadline) }
        })

        var seenIDs = Set<String>()

        for reminder in reminders {
            let reminderID = reminder.calendarItemIdentifier
            seenIDs.insert(reminderID)
            let due = resolvedDueDate(for: reminder)

            let deadline = importedByID[reminderID] ?? Deadline(
                title: reminder.title.isEmpty ? "Reminder" : reminder.title,
                dueDate: due.date,
                hasTime: due.hasTime
            )

            apply(reminder: reminder, to: deadline)

            if importedByID[reminderID] == nil {
                modelContext.insert(deadline)
            }
        }

        var removedCount = 0
        for deadline in existingImported where deadline.reminderID.map({ !seenIDs.contains($0) }) ?? false {
            modelContext.delete(deadline)
            removedCount += 1
        }

        try modelContext.save()
        return ReminderSyncResult(importedCount: reminders.count, removedCount: removedCount)
    }

    private func requestAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            store.requestFullAccessToReminders { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func fetchReminders() async throws -> [EKReminder] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = store.predicateForReminders(in: nil)
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    private func apply(reminder: EKReminder, to deadline: Deadline) {
        let due = resolvedDueDate(for: reminder)
        let start = resolvedStartDate(for: reminder)

        deadline.title = reminder.title.isEmpty ? "Reminder" : reminder.title
        deadline.notes = reminder.notes ?? ""
        deadline.dueDate = due.date
        deadline.hasTime = due.hasTime
        deadline.startDate = start
        deadline.isCompleted = reminder.isCompleted
        deadline.isImportant = reminder.priority > 0 && reminder.priority <= 4
        deadline.reminderID = reminder.calendarItemIdentifier
        deadline.links = reminder.url.map { [$0.absoluteString] } ?? []
    }

    private func resolvedDueDate(for reminder: EKReminder) -> (date: Date, hasTime: Bool) {
        if let components = reminder.dueDateComponents,
           let date = Calendar.current.date(from: components) {
            return (date, hasExplicitTime(in: components))
        }

        if let components = reminder.startDateComponents,
           let date = Calendar.current.date(from: components) {
            return (date, hasExplicitTime(in: components))
        }

        return (Calendar.current.startOfDay(for: Date()), false)
    }

    private func resolvedStartDate(for reminder: EKReminder) -> Date? {
        guard let components = reminder.startDateComponents else { return nil }
        return Calendar.current.date(from: components)
    }

    private func hasExplicitTime(in components: DateComponents) -> Bool {
        components.hour != nil || components.minute != nil || components.second != nil
    }
}
