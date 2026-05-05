import SwiftUI

struct MeView: View {
    var body: some View {
        NavigationStack {
            Text("Me")
                .navigationTitle("Me")
                .largeNavigationTitle()
        }
    }
}

#Preview {
    MeView()
}
