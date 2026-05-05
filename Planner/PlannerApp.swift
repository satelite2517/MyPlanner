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
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
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
