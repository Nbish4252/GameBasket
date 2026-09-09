import SwiftUI

// The signed-in user's own logs, chronological — what FeedView used to
// be before it split into the Games/Reviews/Lists/Journal tab row.
struct JournalView: View {
    @EnvironmentObject private var appState: AppState
    @State private var items: [LogFeedItem] = []
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if !hasLoaded {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            } else if items.isEmpty {
                VStack(spacing: 8) {
                    Text("No logs yet")
                        .font(.balooSemiBold(15))
                        .foregroundStyle(Color.gbText)
                    Text("Games you log will show up here.")
                        .font(.nunito(13))
                        .foregroundStyle(Color.gbTextFaint)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            if index > 0 {
                                Divider().background(Color.gbLine)
                            }
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
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.gbSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                }
                .transition(.opacity)
            }
        }
        .background(Color.gbBackground)
        // .onAppear rather than .task: a log created from the Search tab
        // doesn't recreate this view — .task would only fire once, before
        // that log exists.
        .onAppear {
            Task { await load() }
        }
    }

    private func load() async {
        guard let userId = appState.session?.userId else { return }
        items = (try? await LogService.feedItems(for: userId)) ?? []
        withAnimation(.easeOut(duration: 0.25)) {
            hasLoaded = true
        }
    }
}
