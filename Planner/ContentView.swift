import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WeeklyView()
                .tabItem {
                    Label("Weekly", systemImage: "calendar.day.timeline.left")
                }

            MonthlyView()
                .tabItem {
                    Label("Monthly", systemImage: "calendar")
                }

            ListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }

            MeView()
                .tabItem {
                    Label("Me", systemImage: "person.circle")
                }
        }
    }
}

#Preview {
    ContentView()
}
