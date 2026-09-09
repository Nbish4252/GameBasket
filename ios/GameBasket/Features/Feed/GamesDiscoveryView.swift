import SwiftUI

struct GamesDiscoveryView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isFollowingAnyone = false
    @State private var friendActivity: [PostedLog] = []
    @State private var recommendations: [GameRecommendation] = []
    @State private var trendingLogs: [Game] = []
    @State private var hasLoadedFriendData = false
    @State private var hasLoadedTrending = false

    private var newFromFriends: [PostedLog] {
        Array(friendActivity.prefix(10))
    }

    // Ranked by how many friends logged each game (not by rating — the
    // mockup's "Popular with friends" covers carry no per-item metric,
    // just the games themselves), computed from the same bounded window
    // friendActivity already fetched rather than a second query.
    private var popularWithFriends: [Game] {
        var counts: [Int: Int] = [:]
        var gamesById: [Int: Game] = [:]
        for log in friendActivity {
            counts[log.game.id, default: 0] += 1
            gamesById[log.game.id] = log.game
        }
        return counts.sorted { $0.value > $1.value }
            .prefix(8)
            .compactMap { gamesById[$0.key] }
    }

    // Site-wide trending (last 7 days), independent of the signed-in
    // user's follows — tallied client-side from LogService's bounded
    // recent-window fetch, same approach as popularWithFriends above.
    private var popularThisWeek: [Game] {
        var counts: [Int: Int] = [:]
        var gamesById: [Int: Game] = [:]
        for game in trendingLogs {
            counts[game.id, default: 0] += 1
            gamesById[game.id] = game
        }
        return counts.sorted { $0.value > $1.value }
            .prefix(8)
            .compactMap { gamesById[$0.key] }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                sectionHeader("Popular this week")
                if !hasLoadedTrending {
                    loadingRow
                } else if popularThisWeek.isEmpty {
                    emptyCard("Nothing logged this week yet.")
                } else {
                    coverRow(popularThisWeek)
                }

                sectionHeader("New from friends")
                    .padding(.top, 14)
                if !hasLoadedFriendData {
                    loadingRow
                } else if !isFollowingAnyone {
                    emptyCard("Follow people to see what they're playing.")
                } else if newFromFriends.isEmpty {
                    emptyCard("Your friends haven't logged anything yet.")
                } else {
                    friendRow(newFromFriends)
                }

                sectionHeader("Popular with friends")
                    .padding(.top, 14)
                if !hasLoadedFriendData {
                    loadingRow
                } else if !isFollowingAnyone {
                    emptyCard("Follow people to see what's popular in your circle.")
                } else if popularWithFriends.isEmpty {
                    emptyCard("Your friends haven't logged anything yet.")
                } else {
                    coverRow(popularWithFriends)
                }

                if !recommendations.isEmpty {
                    sectionHeader("Recommended For You")
                        .padding(.top, 14)
                    VStack(spacing: 0) {
                        ForEach(recommendations) { rec in
                            if rec.id != recommendations.first?.id {
                                Divider().background(Color.gbLine)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rec.title)
                                    .font(.balooSemiBold(14))
                                    .foregroundStyle(Color.gbText)
                                Text(rec.reason)
                                    .font(.nunito(12))
                                    .foregroundStyle(Color.gbTextDim)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(12)
                    .background(Color.gbSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 18)
                }
            }
            .padding(.vertical, 18)
        }
        .background(Color.gbBackground)
        .onAppear {
            Task { await loadFriendData() }
        }
        .task {
            recommendations = (try? await RecommendationService.recommendations()) ?? []
        }
        .task {
            trendingLogs = (try? await LogService.recentlyLoggedGames()) ?? []
            hasLoadedTrending = true
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.balooSemiBold(16))
            .foregroundStyle(Color.gbText)
            .padding(.horizontal, 18)
    }

    private var loadingRow: some View {
        ProgressView()
            .padding(.horizontal, 18)
            .padding(.top, 8)
    }

    @ViewBuilder
    private func emptyCard(_ message: String) -> some View {
        Text(message)
            .font(.nunito(13))
            .foregroundStyle(Color.gbTextFaint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.gbSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 18)
            .padding(.top, 8)
    }

    private func friendRow(_ logs: [PostedLog]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(logs) { log in
                    VStack(alignment: .leading, spacing: 3) {
                        cover(url: log.game.coverUrl, title: log.game.name)
                        Text(log.profile.displayName ?? log.profile.username)
                            .font(.nunitoBold(11))
                            .foregroundStyle(Color.gbTextDim)
                        if let heartRating = log.heartRating {
                            HStack(spacing: 3) {
                                PixelHeart()
                                    .frame(width: 11, height: 11)
                                Text(String(format: "%.1f", heartRating))
                                    .font(.nunitoExtraBold(11))
                                    .foregroundStyle(Color.gbHeart)
                            }
                        }
                    }
                    .frame(width: 88)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }

    private func coverRow(_ games: [Game]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(games) { game in
                    cover(url: game.coverUrl, title: game.name)
                        .frame(width: 88)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func cover(url: String?, title: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: url.flatMap(URL.init)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gbSurface2
            }
            .frame(width: 88, height: 118)
            .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(width: 88, height: 118)

            Text(title)
                .font(.balooSemiBold(11))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(8)
        }
        .frame(width: 88, height: 118)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func loadFriendData() async {
        guard let userId = appState.session?.userId else { return }
        let following = (try? await ProfileService.following(for: userId)) ?? []
        isFollowingAnyone = !following.isEmpty
        if isFollowingAnyone {
            friendActivity = (try? await LogService.friendActivity(followingIds: following.map(\.id))) ?? []
        }
        hasLoadedFriendData = true
    }
}
