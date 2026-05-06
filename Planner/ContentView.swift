import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var didRunInitialFileImport = false
    @State private var didRunInitialReminderSync = false
    @Query private var allTodosForExport: [TodoItem]
    @Query private var allDeadlinesForExport: [Deadline]
    @Query private var allLabelsForExport: [PlannerLabel]
    @State private var pendingExportTask: Task<Void, Never>?

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
            await connectICloudDriveFileIfNeeded()
            await runInitialSyncFileImportIfNeeded()
            await runInitialReminderSyncIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            Task {
                await handleScenePhaseChange(newPhase)
            }
        }
        .onChange(of: allTodosForExport) { _, _ in scheduleAutoExport() }
        .onChange(of: allDeadlinesForExport) { _, _ in scheduleAutoExport() }
        .onChange(of: allLabelsForExport) { _, _ in scheduleAutoExport() }
    }

    @MainActor
    private func connectICloudDriveFileIfNeeded() async {
        #if os(macOS)
        do {
            _ = try PlannerSyncFileService.promptToCreateICloudDriveSyncFileIfNeeded(
                modelContext: modelContext,
                theme: theme
            )
        } catch {
            // Fall back to the local default sync file if the user cancels or save fails.
        }
        #endif
    }

    @MainActor
    private func runInitialSyncFileImportIfNeeded() async {
        guard !didRunInitialFileImport else { return }
        didRunInitialFileImport = true

        do {
            _ = try PlannerSyncFileService.ensureActiveSyncFileExists(
                modelContext: modelContext,
                theme: theme
            )
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
    private func handleScenePhaseChange(_ newPhase: ScenePhase) async {
        switch newPhase {
        case .active:
            guard didRunInitialFileImport else { return }
            pullFromConnectedSyncFileIfNeeded()
        case .inactive, .background:
            persistConnectedSyncFileIfNeeded()
        @unknown default:
            break
        }
    }

    @MainActor
    private func pullFromConnectedSyncFileIfNeeded() {
        do {
            _ = try PlannerSyncFileService.importFromConnectedFile(
                modelContext: modelContext,
                theme: theme
            )
        } catch PlannerSyncFileError.noConnectedFile {
            // Ignore when the user hasn't connected a file yet.
        } catch {
            // Ignore foreground pull failures.
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

    @MainActor
    private func scheduleAutoExport() {
        guard didRunInitialFileImport else { return }
        pendingExportTask?.cancel()
        pendingExportTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            persistConnectedSyncFileIfNeeded()
        }
    }
}

#Preview {
    ContentView()
        .environment(ThemeManager())
}
