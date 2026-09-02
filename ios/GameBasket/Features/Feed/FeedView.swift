import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var appState: AppState
    @State private var items: [LogFeedItem] = []
    @State private var isPresentingSearch = false
    @State private var isPresentingSteamSyncTest = false

    var body: some View {
        NavigationStack {
            List(items) { item in
                NavigationLink {
                    GameDetailView(game: item.game)
                } label: {
                    HStack(spacing: 12) {
                        AsyncImage(url: item.game.coverUrl.flatMap(URL.init)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gbSurface2
                        }
                        .frame(width: 40, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.game.name)
                                .font(.balooSemiBold(15))
                                .foregroundStyle(Color.gbText)
                            HStack(spacing: 4) {
                                PixelHeart()
                                    .frame(width: 12, height: 12)
                                Text(item.heartRating.map { String(format: "%.1f", $0) } ?? "unrated")
                                    .font(.nunitoBold(11))
                                    .foregroundStyle(Color.gbTextDim)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.gbSurface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.gbBackground)
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Feed")
                        .font(.balooBold(20))
                        .foregroundStyle(Color.gbText)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingSearch = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Color.gbGreen)
                }
                // TEMPORARY: only for testing steam-sync end to end. Remove
                // once real profile/settings UI owns Steam linking.
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isPresentingSteamSyncTest = true
                    } label: {
                        Image(systemName: "ladybug")
                    }
                    .tint(Color.gbGold)
                }
            }
            .toolbarBackground(Color.gbBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
        .preferredColorScheme(.dark)
    }

    private func loadItems() async {
        guard let userId = appState.session?.userId else { return }
        items = (try? await LogService.feedItems(for: userId)) ?? []
    }
}
