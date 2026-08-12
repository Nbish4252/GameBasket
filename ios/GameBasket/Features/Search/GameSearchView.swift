import SwiftUI

struct GameSearchView: View {
    @State private var query = ""
    @State private var results: [Game] = []

    var body: some View {
        NavigationStack {
            List(results) { game in
                NavigationLink(game.name) {
                    LogGameView(game: game)
                }
            }
            .searchable(text: $query)
            .onSubmit(of: .search) {
                Task {
                    results = (try? await GameService.search(query: query)) ?? []
                }
            }
            .navigationTitle("Search")
        }
    }
}
