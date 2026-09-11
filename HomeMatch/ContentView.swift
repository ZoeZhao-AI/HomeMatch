import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            Text("AI Match")
                .tabItem { Label("AI Match", systemImage: "sparkles") }

            Text("Roommates")
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
