import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var didRunInitialFileImport = false
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
            await runInitialSyncFileImportIfNeeded()
            await runInitialReminderSyncIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .background else { return }
            persistConnectedSyncFileIfNeeded()
        }
    }

    @MainActor
    private func runInitialSyncFileImportIfNeeded() async {
        guard !didRunInitialFileImport else { return }
        didRunInitialFileImport = true

        do {
            _ = try PlannerSyncFileService.importFromConnectedFile(modelContext: modelContext, theme: theme)
        } catch PlannerSyncFileError.noConnectedFile {
            // Ignore when the user hasn't connected a file yet.
        } catch {
            // Ignore startup sync failures; manual sync remains available in Me.
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

    @MainActor
    private func persistConnectedSyncFileIfNeeded() {
        do {
            _ = try PlannerSyncFileService.exportToConnectedFile(modelContext: modelContext, theme: theme)
        } catch PlannerSyncFileError.noConnectedFile {
            // Ignore when the user hasn't connected a file yet.
        } catch {
            // Ignore background export failures.
        }
    }
}

#Preview {
    ContentView()
        .environment(ThemeManager())
}
