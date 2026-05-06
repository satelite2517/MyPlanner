import EventKit
import Foundation
import SwiftData

struct ReminderSyncResult {
    let importedCount: Int
    let removedCount: Int
    let skippedCount: Int
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
        var importedCount = 0
        var skippedCount = 0

        for reminder in reminders {
            let reminderID = syncIdentifier(for: reminder)
            let legacyReminderID = reminder.calendarItemIdentifier
            guard let due = resolvedDueDate(for: reminder) else {
                skippedCount += 1
                continue
            }

            seenIDs.insert(reminderID)

            let deadline = importedByID[reminderID] ?? importedByID[legacyReminderID] ?? Deadline(
                title: reminder.title.isEmpty ? "Reminder" : reminder.title,
                dueDate: due.date,
                hasTime: due.hasTime
            )

            apply(reminder: reminder, to: deadline)

            if importedByID[reminderID] == nil && importedByID[legacyReminderID] == nil {
                modelContext.insert(deadline)
            }

            importedCount += 1
        }

        var removedCount = 0
        for deadline in existingImported where deadline.reminderID.map({ !seenIDs.contains($0) }) ?? false {
            modelContext.delete(deadline)
            removedCount += 1
        }

        try modelContext.save()
        return ReminderSyncResult(
            importedCount: importedCount,
            removedCount: removedCount,
            skippedCount: skippedCount
        )
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

    private func syncIdentifier(for reminder: EKReminder) -> String {
        let externalID = reminder.calendarItemExternalIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let externalID, !externalID.isEmpty {
            return externalID
        }

        return reminder.calendarItemIdentifier
    }

    private func apply(reminder: EKReminder, to deadline: Deadline) {
        guard let due = resolvedDueDate(for: reminder) else { return }
        let start = resolvedStartDate(for: reminder)

        deadline.title = reminder.title.isEmpty ? "Reminder" : reminder.title
        deadline.notes = reminder.notes ?? ""
        deadline.dueDate = due.date
        deadline.hasTime = due.hasTime
        deadline.startDate = start
        deadline.isCompleted = reminder.isCompleted
        deadline.isImportant = reminder.priority > 0 && reminder.priority <= 4
        deadline.reminderID = syncIdentifier(for: reminder)
        deadline.links = reminder.url.map { [$0.absoluteString] } ?? []
    }

    private func resolvedDueDate(for reminder: EKReminder) -> (date: Date, hasTime: Bool)? {
        if let components = reminder.dueDateComponents,
           let date = Calendar.current.date(from: components) {
            return (date, hasExplicitTime(in: components))
        }

        if let components = reminder.startDateComponents,
           let date = Calendar.current.date(from: components) {
            return (date, hasExplicitTime(in: components))
        }

        if reminder.isCompleted, let completionDate = reminder.completionDate {
            return (Calendar.current.startOfDay(for: completionDate), false)
        }

        return nil
    }

    private func resolvedStartDate(for reminder: EKReminder) -> Date? {
        guard let components = reminder.startDateComponents else { return nil }
        return Calendar.current.date(from: components)
    }

    private func hasExplicitTime(in components: DateComponents) -> Bool {
        components.hour != nil || components.minute != nil || components.second != nil
    }
}
