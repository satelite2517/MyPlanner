import SwiftUI
import SwiftData

@main
struct PlannerApp: App {
    private static let cloudKitContainerID = "iCloud.sjlee6100.personal.Planner"

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TodoItem.self,
            Deadline.self,
            PlannerLabel.self,
            TodoHistory.self,
        ])
        do {
            let modelConfiguration = ModelConfiguration(
                cloudKitDatabase: .private(Self.cloudKitContainerID)
            )
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            do {
                let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                return try ModelContainer(for: schema, configurations: [fallbackConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
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
}
