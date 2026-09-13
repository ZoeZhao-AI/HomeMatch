import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            PreferencesView()
                .tabItem { Label("AI Match", systemImage: "sparkles") }

            NavigationStack {
                RoommateMatchResultsView()
            }
            .tabItem { Label("Roommates", systemImage: "person.2.fill") }

            Text("Profile")
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(DesignTokens.primary)
    }
}

#Preview {
    ContentView()
}
