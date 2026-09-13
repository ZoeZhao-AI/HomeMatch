import SwiftUI

enum AppTab: Hashable {
    case home, aiMatch, roommates, profile
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(AppTab.home)

            PreferencesView()
                .tabItem { Label("AI Match", systemImage: "sparkles") }
                .tag(AppTab.aiMatch)

            NavigationStack {
                RoommateMatchResultsView()
            }
            .tabItem { Label("Roommates", systemImage: "person.2.fill") }
            .tag(AppTab.roommates)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(AppTab.profile)
        }
        .tint(DesignTokens.primary)
    }
}

#Preview {
    ContentView()
}
