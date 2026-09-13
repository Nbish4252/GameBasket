import SwiftUI

struct GameSearchView: View {
    @State private var query = ""
    @State private var results: [Game] = []
    @State private var trending: [Game] = []
    @State private var hasSearched = false

    var body: some View {
        NavigationStack {
            Group {
                if hasSearched {
                    List(results) { game in
                        NavigationLink(game.name) {
                            LogGameView(game: game)
                        }
                    }
                    .transition(.opacity)
                } else {
                    trendingPrompt
                        .transition(.opacity)
                }
            }
            .searchable(text: $query)
            .onSubmit(of: .search) {
                Task {
                    let fetched = (try? await GameService.search(query: query)) ?? []
                    withAnimation(.easeOut(duration: 0.2)) {
                        results = fetched
                        hasSearched = true
                    }
                }
            }
            .onChange(of: query) { _, newValue in
                if newValue.isEmpty {
                    withAnimation(.easeOut(duration: 0.2)) {
                        hasSearched = false
                    }
                }
            }
            .navigationTitle("Search")
        }
        .task {
            // Reuses the same trending query GamesDiscoveryView's
            // "Popular this week" section is built on, rather than a
            // second endpoint — this is the same content, just also
            // shown here so the tab isn't a blank search bar the moment
            // it opens.
            trending = (try? await LogService.recentlyLoggedGames()) ?? []
        }
    }

    private var trendingPrompt: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if trending.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.gbTextFaint)
                        Text("Search for a game to log it")
                            .font(.balooSemiBold(15))
                            .foregroundStyle(Color.gbText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    Text("Trending")
                        .font(.balooSemiBold(16))
                        .foregroundStyle(Color.gbText)
                        .padding(.horizontal, 18)
                        .padding(.top, 12)

                    // Trending covers link into LogGameView directly (not
                    // GameDetailView, unlike GamesDiscoveryView's rows) —
                    // this tab's whole purpose is logging a game, so a
                    // trending cover here should do exactly what tapping
                    // a search result does.
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 12)], spacing: 16) {
                        ForEach(trending) { game in
                            NavigationLink {
                                LogGameView(game: game)
                            } label: {
                                GameCoverCard(url: game.coverUrl, title: game.name)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color.gbBackground)
    }
}
