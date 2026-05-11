import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

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
        .onAppear {
            CarryOverService.carryOverIfNeeded(modelContext: modelContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                CarryOverService.carryOverIfNeeded(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(ThemeManager())
}
