import SwiftUI

enum MainTab: Hashable {
    case feed, search, quickLog, activity, profile
}

// Real nav chrome replacing the old toolbar-button/sheet approach to
// reach Search. Matches the mockup's bottomnav shape: library, search,
// a raised "+" quick-log action, a bolt/activity glyph, profile.
struct MainTabView: View {
    @State private var selectedTab: MainTab = .feed
    @State private var previousTab: MainTab = .feed
    @State private var isPresentingQuickLog = false

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem { Label("Feed", systemImage: "square.stack") }
                .tag(MainTab.feed)

            GameSearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(MainTab.search)

            // Never actually shown — SwiftUI's TabView has no API for a
            // non-navigating "action" tab item, so this is the standard
            // workaround: give it real tag/selection like any other tab,
            // then intercept the selection change below, revert it, and
            // present the quick-log flow as a sheet instead.
            Color.clear
                .tabItem { Image(systemName: "plus.circle.fill") }
                .tag(MainTab.quickLog)

            ActivityView()
                .tabItem { Label("Activity", systemImage: "bolt.fill") }
                .tag(MainTab.activity)

            ProfileTabView()
                .tabItem { Label("Profile", systemImage: "person.circle") }
                .tag(MainTab.profile)
        }
        .tint(Color.gbGreen)
        .toolbarBackground(Color.gbSurface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .quickLog {
                selectedTab = previousTab
                isPresentingQuickLog = true
            } else {
                previousTab = newValue
            }
        }
        // GameSearchView wraps its own NavigationStack already, so it's
        // reused here as-is rather than wrapped again. No auto-dismiss
        // wiring after a save: LogGameView's dismiss() pops back to the
        // search results within this same sheet (the correct behavior
        // when GameSearchView is the persistent Search tab too, and
        // changing that just for this entry point would special-case a
        // view used two different ways) — closing the sheet itself is a
        // plain swipe-down after logging.
        .sheet(isPresented: $isPresentingQuickLog) {
            GameSearchView()
        }
    }
}
