import SwiftUI

struct ListView: View {
    var body: some View {
        NavigationStack {
            Text("List")
                .navigationTitle("List")
                .largeNavigationTitle()
        }
    }
}

#Preview {
    ListView()
}
