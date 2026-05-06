import Foundation
import SwiftData
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

enum PlannerSyncFileError: LocalizedError {
    case noConnectedFile
    case invalidFile

    var errorDescription: String? {
        switch self {
        case .noConnectedFile:
            return "No sync file is connected."
        case .invalidFile:
            return "The selected sync file is invalid."
        }
    }
}

enum PlannerSyncBookmarkStore {
    private static let bookmarkKey = "plannerSyncFileBookmark"

    static func save(url: URL) throws {
        let bookmark = try url.bookmarkData(
            options: bookmarkCreationOptions,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
    }

    static func resolvedURL() throws -> URL? {
        guard let bookmark = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }

        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmark,
            options: bookmarkResolutionOptions,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        if isStale {
            try save(url: url)
        }

        return url
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }

    private static var bookmarkCreationOptions: URL.BookmarkCreationOptions {
        #if os(macOS)
        return [.withSecurityScope]
        #else
        return []
        #endif
    }

    private static var bookmarkResolutionOptions: URL.BookmarkResolutionOptions {
        #if os(macOS)
        return [.withSecurityScope]
        #else
        return []
        #endif
    }
}

private struct PlannerSyncPreferencesSnapshot: Codable {
    let displayName: String
    let notificationsEnabled: Bool
    let selectedAccentID: String
    let selectedBackgroundID: String
    let selectedTodoColorHex: String
    let selectedDeadlineColorHex: String
    let languageRaw: String
}

private struct PlannerLabelSnapshot: Codable {
    let id: UUID
    let name: String
    let emoji: String?
    let colorHex: String
}

private struct DeadlineSnapshot: Codable {
    let id: UUID
    let title: String
    let notes: String
    let dueDate: Date
    let hasTime: Bool
    let startDate: Date?
    let isCompleted: Bool
    let isImportant: Bool
    let calendarEventID: String?
    let reminderID: String?
    let labelIDs: [UUID]
    let links: [String]
}

private struct TodoSnapshot: Codable {
    let id: UUID
    let title: String
    let notes: String
    let dueDate: Date
    let endDate: Date?
    let hasTime: Bool
    let isCompleted: Bool
    let isImportant: Bool
    let autoCarryOver: Bool
    let reminderID: String?
    let labelIDs: [UUID]
    let links: [String]
    let deadlineID: UUID?
}

private struct TodoHistorySnapshot: Codable {
    let id: UUID
    let originalDate: Date
    let wasCompleted: Bool
    let carriedOverTo: Date?
    let recordedAt: Date
    let todoID: UUID?
}

private struct PlannerSyncSnapshot: Codable {
    let version: Int
    let exportedAt: Date
    let preferences: PlannerSyncPreferencesSnapshot
    let labels: [PlannerLabelSnapshot]
    let deadlines: [DeadlineSnapshot]
    let todos: [TodoSnapshot]
    let histories: [TodoHistorySnapshot]
}

@MainActor
struct PlannerSyncFileService {
    #if os(macOS)
    static func promptToCreateICloudDriveSyncFileIfNeeded(
        modelContext: ModelContext,
        theme: ThemeManager
    ) throws -> String? {
        guard try PlannerSyncBookmarkStore.resolvedURL() == nil else {
            return nil
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "PlannerSync.json"
        panel.canCreateDirectories = true
        panel.directoryURL = preferredICloudDriveDirectoryURL()

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        try export(modelContext: modelContext, theme: theme, to: url)
        try PlannerSyncBookmarkStore.save(url: url)
        return url.lastPathComponent
    }

    private static func preferredICloudDriveDirectoryURL() -> URL? {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs", isDirectory: true)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    #endif

    static func defaultLocalFileURL() throws -> URL {
        let directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sync", isDirectory: true)

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        return directory.appendingPathComponent("PlannerSync.json")
    }

    static func activeSyncFileURL() throws -> URL {
        if let connected = try PlannerSyncBookmarkStore.resolvedURL() {
            return connected
        }
        return try defaultLocalFileURL()
    }

    static func connectedFileURL() -> URL? {
        try? PlannerSyncBookmarkStore.resolvedURL()
    }

    static func connectedFileName() -> String? {
        connectedFileURL()?.lastPathComponent
    }

    static func activeSyncFileName() -> String? {
        try? activeSyncFileURL().lastPathComponent
    }

    static func ensureActiveSyncFileExists(modelContext: ModelContext, theme: ThemeManager) throws -> String {
        let url = try activeSyncFileURL()
        guard !FileManager.default.fileExists(atPath: url.path) else {
            return url.lastPathComponent
        }

        try export(modelContext: modelContext, theme: theme, to: url)
        return url.lastPathComponent
    }

    static func exportToConnectedFile(modelContext: ModelContext, theme: ThemeManager) throws -> String {
        let url = try activeSyncFileURL()
        try export(modelContext: modelContext, theme: theme, to: url)
        return url.lastPathComponent
    }

    static func importFromConnectedFile(modelContext: ModelContext, theme: ThemeManager) throws -> String {
        let url = try activeSyncFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PlannerSyncFileError.noConnectedFile
        }

        try `import`(from: url, modelContext: modelContext, theme: theme)
        return url.lastPathComponent
    }

    static func export(modelContext: ModelContext, theme: ThemeManager, to url: URL) throws {
        let started = url.startAccessingSecurityScopedResource()
        defer {
            if started {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let snapshot = try makeSnapshot(modelContext: modelContext, theme: theme)
        let data = try encodedData(for: snapshot)
        try data.write(to: url, options: .atomic)
    }

    static func `import`(from url: URL, modelContext: ModelContext, theme: ThemeManager) throws {
        let started = url.startAccessingSecurityScopedResource()
        defer {
            if started {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(PlannerSyncSnapshot.self, from: data)
        try apply(snapshot: snapshot, modelContext: modelContext, theme: theme)
    }

    private static func encodedData(for snapshot: PlannerSyncSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot)
    }

    private static func makeSnapshot(modelContext: ModelContext, theme: ThemeManager) throws -> PlannerSyncSnapshot {
        let labels = try modelContext.fetch(FetchDescriptor<PlannerLabel>())
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let deadlines = try modelContext.fetch(FetchDescriptor<Deadline>())
            .sorted { $0.dueDate < $1.dueDate }
        let todos = try modelContext.fetch(FetchDescriptor<TodoItem>())
            .sorted { $0.dueDate < $1.dueDate }
        let histories = try modelContext.fetch(FetchDescriptor<TodoHistory>())
            .sorted { $0.recordedAt < $1.recordedAt }

        return PlannerSyncSnapshot(
            version: 1,
            exportedAt: Date(),
            preferences: PlannerSyncPreferencesSnapshot(
                displayName: UserDefaults.standard.string(forKey: "displayName") ?? "",
                notificationsEnabled: UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true,
                selectedAccentID: theme.selectedAccentID,
                selectedBackgroundID: theme.selectedBackgroundID,
                selectedTodoColorHex: theme.selectedTodoColorHex,
                selectedDeadlineColorHex: theme.selectedDeadlineColorHex,
                languageRaw: theme.languageRaw
            ),
            labels: labels.map {
                PlannerLabelSnapshot(
                    id: $0.id,
                    name: $0.name,
                    emoji: $0.emoji,
                    colorHex: $0.colorHex
                )
            },
            deadlines: deadlines.map {
                DeadlineSnapshot(
                    id: $0.id,
                    title: $0.title,
                    notes: $0.notes,
                    dueDate: $0.dueDate,
                    hasTime: $0.hasTime,
                    startDate: $0.startDate,
                    isCompleted: $0.isCompleted,
                    isImportant: $0.isImportant,
                    calendarEventID: $0.calendarEventID,
                    reminderID: $0.reminderID,
                    labelIDs: $0.labelList.map(\.id),
                    links: $0.links
                )
            },
            todos: todos.map {
                TodoSnapshot(
                    id: $0.id,
                    title: $0.title,
                    notes: $0.notes,
                    dueDate: $0.dueDate,
                    endDate: $0.endDate,
                    hasTime: $0.hasTime,
                    isCompleted: $0.isCompleted,
                    isImportant: $0.isImportant,
                    autoCarryOver: $0.autoCarryOver,
                    reminderID: $0.reminderID,
                    labelIDs: $0.labelList.map(\.id),
                    links: $0.links,
                    deadlineID: $0.deadline?.id
                )
            },
            histories: histories.map {
                TodoHistorySnapshot(
                    id: $0.id,
                    originalDate: $0.originalDate,
                    wasCompleted: $0.wasCompleted,
                    carriedOverTo: $0.carriedOverTo,
                    recordedAt: $0.recordedAt,
                    todoID: $0.todo?.id
                )
            }
        )
    }

    private static func apply(snapshot: PlannerSyncSnapshot, modelContext: ModelContext, theme: ThemeManager) throws {
        guard snapshot.version == 1 else {
            throw PlannerSyncFileError.invalidFile
        }

        let existingHistories = try modelContext.fetch(FetchDescriptor<TodoHistory>())
        let existingTodos = try modelContext.fetch(FetchDescriptor<TodoItem>())
        let existingDeadlines = try modelContext.fetch(FetchDescriptor<Deadline>())
        let existingLabels = try modelContext.fetch(FetchDescriptor<PlannerLabel>())

        for history in existingHistories {
            modelContext.delete(history)
        }
        for todo in existingTodos {
            modelContext.delete(todo)
        }
        for deadline in existingDeadlines {
            modelContext.delete(deadline)
        }
        for label in existingLabels {
            modelContext.delete(label)
        }

        try modelContext.save()

        var labelsByID: [UUID: PlannerLabel] = [:]
        for item in snapshot.labels {
            let label = PlannerLabel(name: item.name, emoji: item.emoji, colorHex: item.colorHex)
            label.id = item.id
            modelContext.insert(label)
            labelsByID[item.id] = label
        }

        var deadlinesByID: [UUID: Deadline] = [:]
        for item in snapshot.deadlines {
            let deadline = Deadline(
                title: item.title,
                dueDate: item.dueDate,
                hasTime: item.hasTime,
                startDate: item.startDate,
                notes: item.notes,
                isImportant: item.isImportant,
                labels: [],
                links: item.links
            )
            deadline.id = item.id
            deadline.isCompleted = item.isCompleted
            deadline.calendarEventID = item.calendarEventID
            deadline.reminderID = item.reminderID
            modelContext.insert(deadline)
            deadlinesByID[item.id] = deadline
        }

        var todosByID: [UUID: TodoItem] = [:]
        for item in snapshot.todos {
            let todo = TodoItem(
                title: item.title,
                dueDate: item.dueDate,
                endDate: item.endDate,
                hasTime: item.hasTime,
                notes: item.notes,
                isImportant: item.isImportant,
                autoCarryOver: item.autoCarryOver,
                labels: [],
                links: item.links
            )
            todo.id = item.id
            todo.isCompleted = item.isCompleted
            todo.reminderID = item.reminderID
            modelContext.insert(todo)
            todosByID[item.id] = todo
        }

        var historiesByTodoID: [UUID: [TodoHistory]] = [:]
        for item in snapshot.histories {
            let history = TodoHistory(
                originalDate: item.originalDate,
                wasCompleted: item.wasCompleted,
                carriedOverTo: item.carriedOverTo
            )
            history.id = item.id
            history.recordedAt = item.recordedAt
            if let todoID = item.todoID, let todo = todosByID[todoID] {
                history.todo = todo
                historiesByTodoID[todoID, default: []].append(history)
            }
            modelContext.insert(history)
        }

        for item in snapshot.deadlines {
            guard let deadline = deadlinesByID[item.id] else { continue }
            deadline.labels = item.labelIDs.compactMap { labelsByID[$0] }
        }

        for item in snapshot.todos {
            guard let todo = todosByID[item.id] else { continue }
            todo.labels = item.labelIDs.compactMap { labelsByID[$0] }
            todo.deadline = item.deadlineID.flatMap { deadlinesByID[$0] }
            todo.history = historiesByTodoID[item.id] ?? []
        }

        theme.selectedAccentID = snapshot.preferences.selectedAccentID
        theme.selectedBackgroundID = snapshot.preferences.selectedBackgroundID
        theme.selectedTodoColorHex = snapshot.preferences.selectedTodoColorHex
        theme.selectedDeadlineColorHex = snapshot.preferences.selectedDeadlineColorHex
        theme.languageRaw = snapshot.preferences.languageRaw

        UserDefaults.standard.set(snapshot.preferences.displayName, forKey: "displayName")
        UserDefaults.standard.set(snapshot.preferences.notificationsEnabled, forKey: "notificationsEnabled")

        try modelContext.save()
    }
}
