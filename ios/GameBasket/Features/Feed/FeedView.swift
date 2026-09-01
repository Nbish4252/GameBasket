import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var appState: AppState
    @State private var items: [LogFeedItem] = []
    @State private var isPresentingSearch = false
    @State private var isPresentingSteamSyncTest = false

    var body: some View {
        NavigationStack {
            List(items) { item in
                HStack {
                    AsyncImage(url: item.game.coverUrl.flatMap(URL.init)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 40, height: 54)
                    .clipped()

                    VStack(alignment: .leading) {
                        Text(item.game.name)
                        Text(item.heartRating.map { String(format: "%.1f♥", $0) } ?? "unrated")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingSearch = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                // TEMPORARY: only for testing steam-sync end to end. Remove
                // once real profile/settings UI owns Steam linking.
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isPresentingSteamSyncTest = true
                    } label: {
                        Image(systemName: "ladybug")
                    }
                }
            }
            // Plain functional entry point into Search → Log Game — no nav
            // chrome/tab bar yet, that's deferred second-phase work.
            .sheet(isPresented: $isPresentingSearch, onDismiss: { Task { await loadItems() } }) {
                GameSearchView()
            }
            .sheet(isPresented: $isPresentingSteamSyncTest) {
                NavigationStack {
                    SteamSyncTestView()
                }
            }
            .task {
                await loadItems()
            }
        }
    }

    private func loadItems() async {
        guard let userId = appState.session?.userId else { return }
        items = (try? await LogService.feedItems(for: userId)) ?? []
    }
}
