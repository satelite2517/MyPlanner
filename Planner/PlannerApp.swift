import SwiftUI
import SwiftData

@main
struct PlannerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TodoItem.self,
            Deadline.self,
            PlannerLabel.self,
            TodoHistory.self,
        ])
        let storeURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Planner.store")

        do {
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let modelConfiguration = ModelConfiguration(
                "Planner",
                schema: schema,
                url: storeURL,
                allowsSave: true,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            try repairStoreIfNeeded(container)
            return container
        } catch {
            do {
                try removeStoreArtifacts(at: storeURL)
                let resetConfiguration = ModelConfiguration(
                    "Planner",
                    schema: schema,
                    url: storeURL,
                    allowsSave: true,
                    cloudKitDatabase: .none
                )
                let container = try ModelContainer(for: schema, configurations: [resetConfiguration])
                try repairStoreIfNeeded(container)
                return container
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
            }
        }
    }()

    @State private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
                .environment(\.locale, themeManager.locale)
                #if os(macOS)
                .frame(minWidth: 390, minHeight: 700)
                #endif
        }
        .modelContainer(sharedModelContainer)
    }

    private static func removeStoreArtifacts(at storeURL: URL) throws {
        let fileManager = FileManager.default
        let candidates = [
            storeURL,
            storeURL.appendingPathExtension("sqlite"),
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal"),
            URL(fileURLWithPath: storeURL.path + ".sqlite-shm"),
            URL(fileURLWithPath: storeURL.path + ".sqlite-wal"),
        ]

        for candidate in candidates where fileManager.fileExists(atPath: candidate.path) {
            try fileManager.removeItem(at: candidate)
        }
    }

    private static func repairStoreIfNeeded(_ container: ModelContainer) throws {
        let modelContext = ModelContext(container)
        try PlannerDataRepairService.repair(modelContext: modelContext)
    }
}
