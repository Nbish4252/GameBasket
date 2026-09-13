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
                    shimmerRow
                        .transition(.opacity)
                } else if popularThisWeek.isEmpty {
                    emptyCard("Nothing logged this week yet.")
                        .transition(.opacity)
                } else {
                    coverRow(popularThisWeek)
                        .transition(.opacity)
                }

                sectionHeader("New from friends")
                    .padding(.top, 14)
                if !hasLoadedFriendData {
                    shimmerRow
                        .transition(.opacity)
                } else if !isFollowingAnyone {
                    emptyCard("Follow people to see what they're playing.")
                        .transition(.opacity)
                } else if newFromFriends.isEmpty {
                    emptyCard("Your friends haven't logged anything yet.")
                        .transition(.opacity)
                } else {
                    friendRow(newFromFriends)
                        .transition(.opacity)
                }

                sectionHeader("Popular with friends")
                    .padding(.top, 14)
                if !hasLoadedFriendData {
                    shimmerRow
                        .transition(.opacity)
                } else if !isFollowingAnyone {
                    emptyCard("Follow people to see what's popular in your circle.")
                        .transition(.opacity)
                } else if popularWithFriends.isEmpty {
                    emptyCard("Your friends haven't logged anything yet.")
                        .transition(.opacity)
                } else {
                    coverRow(popularWithFriends)
                        .transition(.opacity)
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
            await loadRecommendations()
        }
        .task {
            await loadTrending()
        }
        .refreshable {
            await loadFriendData()
            await loadTrending()
            await loadRecommendations()
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.balooSemiBold(16))
            .foregroundStyle(Color.gbText)
            .padding(.horizontal, 18)
    }

    // A row of pulsing cover-sized placeholders rather than a lone
    // spinner — this is the one section where a bare ProgressView left
    // the biggest visual gap against the real content's shape.
    private var shimmerRow: some View {
        HStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                ShimmerPlaceholder()
                    .frame(width: 88, height: 118)
            }
        }
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
                        GameCoverCard(url: log.game.coverUrl, title: log.game.name)
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
                    GameCoverCard(url: game.coverUrl, title: game.name)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }

    // All three load functions below share one rule, found the hard way:
    // never let a cancelled load overwrite good on-screen data with an
    // empty result. `.refreshable`'s Task gets cancelled if the pull
    // gesture ends before the async work finishes (confirmed via a
    // CancellationError caught here during testing — not a network or
    // query bug, the exact same Supabase call is 100% reliable when hit
    // directly). A plain `try?` treats cancellation exactly like "got no
    // data" and clears the section to empty; catching CancellationError
    // explicitly and simply not writing state instead leaves whatever
    // was already showing untouched, which is the correct behavior for
    // both an interrupted refresh and (defensively) an interrupted first
    // load.
    private func loadFriendData() async {
        guard let userId = appState.session?.userId else { return }
        do {
            let following = try await ProfileService.following(for: userId)
            let followingAnyone = !following.isEmpty
            let activity = followingAnyone
                ? try await LogService.friendActivity(followingIds: following.map(\.id))
                : []
            withAnimation(.easeOut(duration: 0.25)) {
                isFollowingAnyone = followingAnyone
                friendActivity = activity
                hasLoadedFriendData = true
            }
        } catch is CancellationError {
            // Leave existing state as-is.
        } catch {
            withAnimation(.easeOut(duration: 0.25)) {
                hasLoadedFriendData = true
            }
        }
    }

    private func loadTrending() async {
        do {
            let games = try await LogService.recentlyLoggedGames()
            withAnimation(.easeOut(duration: 0.25)) {
                trendingLogs = games
                hasLoadedTrending = true
            }
        } catch is CancellationError {
            // Leave existing state as-is.
        } catch {
            withAnimation(.easeOut(duration: 0.25)) {
                hasLoadedTrending = true
            }
        }
    }

    private func loadRecommendations() async {
        do {
            recommendations = try await RecommendationService.recommendations()
        } catch {
            // Leave existing state as-is, cancellation or otherwise —
            // recommendations have no loading/empty-state UI of their
            // own (the section just doesn't render until non-empty), so
            // there's nothing to fall back to here either way.
        }
    }
}
