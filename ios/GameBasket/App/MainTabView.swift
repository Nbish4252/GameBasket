import SwiftUI

// Real nav chrome replacing the old toolbar-button/sheet approach to
// reach Search. The mockup's bottomnav has 5 icons (feed, search, a
// center "+" quick-log action, an unused "activity" glyph, profile) —
// simplified to 3 tabs since there's no Activity feature yet and "+"
// is just Search's job now that it's a real destination.
struct MainTabView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("Feed", systemImage: "square.stack") }

            GameSearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            ProfileTabView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
        }
        .tint(Color.gbGreen)
        .toolbarBackground(Color.gbSurface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }
}
