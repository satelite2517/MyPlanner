import SwiftUI

struct MonthlyView: View {
    var body: some View {
        NavigationStack {
            Text("Monthly")
                .navigationTitle("Monthly")
                .largeNavigationTitle()
        }
    }
}

#Preview {
    MonthlyView()
}
