import SwiftUI

// Real nav chrome replacing the old toolbar-button/sheet approach to
// reach Search. The mockup's bottomnav has 5 icons (feed, search, a
// center "+" quick-log action, a bolt/activity glyph, profile) —
// "+" is still skipped since Search is a real destination and a
// separate quick-log button would just duplicate it, but the bolt
// icon now has a real Activity screen behind it.
struct MainTabView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("Feed", systemImage: "square.stack") }

            GameSearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            ActivityView()
                .tabItem { Label("Activity", systemImage: "bolt.fill") }

            ProfileTabView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
        }
        .tint(Color.gbGreen)
        .toolbarBackground(Color.gbSurface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}
