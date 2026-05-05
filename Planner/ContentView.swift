import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @State private var didRunInitialReminderSync = false

    var body: some View {
        TabView {
            WeeklyView()
                .tabItem {
                    Label(theme.str.weeklyTitle, systemImage: "calendar.day.timeline.left")
                }

            MonthlyView()
                .tabItem {
                    Label(theme.str.monthlyTitle, systemImage: "calendar")
                }

            ListView()
                .tabItem {
                    Label(theme.str.listTitle, systemImage: "list.bullet")
                }

            MeView()
                .tabItem {
                    Label(theme.str.meTitle, systemImage: "person.circle")
                }
        }
        .task {
            await runInitialReminderSyncIfNeeded()
        }
    }

    @MainActor
    private func runInitialReminderSyncIfNeeded() async {
        guard !didRunInitialReminderSync else { return }
        didRunInitialReminderSync = true

        do {
            _ = try await ReminderSyncService().syncDeadlines(from: modelContext)
        } catch {
            // Ignore startup sync failures; the manual sync entry point in Me remains available.
        }
    }
}

#Preview {
    ContentView()
        .environment(ThemeManager())
}
