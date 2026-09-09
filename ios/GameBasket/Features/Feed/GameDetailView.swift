import SwiftUI

// Scoped to what the schema actually supports today: name/cover/release
// date/genres/platforms/developer, description, an IGDB-sourced
// playtime estimate and storefront links, the signed-in user's own most
// recent log (with played-with tags), community rating distribution +
// average (site-wide, from every log on this game), "friends who rated
// this" (via `follows`), and Steam playtime if a steam_app_id match
// exists.
struct GameDetailView: View {
    let game: Game

    @EnvironmentObject private var appState: AppState
    @State private var log: GameLog?
    @State private var participants: [Profile] = []
    @State private var steamEntry: SteamLibraryEntry?
    @State private var communityRatings: [Int] = []
    @State private var friendRatings: [PostedLog] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    AsyncImage(url: game.coverUrl.flatMap(URL.init)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gbSurface2
                    }
                    .frame(width: 84, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.name)
                            .font(.balooBold(19))
                            .foregroundStyle(Color.gbText)
                        if let releaseYear {
                            Text(releaseYear)
                                .font(.nunitoSemiBold(12))
                                .foregroundStyle(Color.gbTextDim)
                        }
                        if !game.genres.isEmpty {
                            Text(game.genres.joined(separator: ", "))
                                .font(.nunito(12))
                                .foregroundStyle(Color.gbTextFaint)
                        }
                    }
                }

                if hasMetaStripContent {
                    metaStrip
                }

                if let summary = game.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.nunito(13))
                        .foregroundStyle(Color.gbTextDim)
                }

                if !game.storeLinks.isEmpty {
                    storeLinksRow
                }

                if !communityRatings.isEmpty {
                    Divider().background(Color.gbLine)
                    ratingSummary
                }

                if let steamEntry {
                    sectionCard(title: "Playtime") {
                        Text(playtimeText(steamEntry.playtimeMinutes))
                            .font(.nunitoBold(14))
                            .foregroundStyle(Color.gbText)
                    }
                }

                sectionCard(title: "Your Log") {
                    if let log {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                PixelHeart()
                                    .frame(width: 14, height: 14)
                                Text(log.heartRating.map { String(format: "%.1f", $0) } ?? "unrated")
                                    .font(.nunitoBold(14))
                                    .foregroundStyle(Color.gbText)
                                Text(log.status.rawValue.capitalized)
                                    .font(.nunitoSemiBold(12))
                                    .foregroundStyle(Color.gbGreen)
                            }
                            if let review = log.review, !review.isEmpty {
                                Text(review)
                                    .font(.nunito(13))
                                    .foregroundStyle(Color.gbTextDim)
                            }
                            if !participants.isEmpty {
                                Text("Played with \(participants.map { $0.displayName ?? $0.username }.joined(separator: ", "))")
                                    .font(.nunitoSemiBold(11))
                                    .foregroundStyle(Color.gbGreen)
                            }
                        }
                    } else {
                        Text("You haven't logged this game yet.")
                            .font(.nunito(13))
                            .foregroundStyle(Color.gbTextFaint)
                    }
                }

                if !friendRatings.isEmpty {
                    friendsWhoRatedSection
                }
            }
            .padding()
        }
        .background(Color.gbBackground)
        .navigationTitle(game.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.gbBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        .task {
            await load()
        }
    }

    private var releaseYear: String? {
        guard let date = game.firstReleaseDate else { return nil }
        return String(Calendar.current.component(.year, from: date))
    }

    private var hasMetaStripContent: Bool {
        game.playtimeEstimateMinutes != nil || !game.platforms.isEmpty || game.developer != nil
    }

    // "~X hrs to beat" rather than "X hrs played" — deliberately distinct
    // wording from the Steam Playtime card below, since these are two
    // different numbers: this one is IGDB's site-wide "time to beat"
    // estimate, that one is the signed-in user's own tracked playtime.
    private var metaStrip: some View {
        HStack(spacing: 14) {
            if let minutes = game.playtimeEstimateMinutes {
                HStack(spacing: 4) {
                    Image(systemName: "gamecontroller")
                    Text("~\(minutes / 60) hrs to beat")
                }
            }
            if !game.platforms.isEmpty {
                Text(game.platforms.joined(separator: " · "))
            }
            if let developer = game.developer {
                Text(developer)
            }
        }
        .font(.nunitoSemiBold(11))
        .foregroundStyle(Color.gbTextFaint)
    }

    private var storeLinksRow: some View {
        HStack(spacing: 8) {
            ForEach(game.storeLinks) { link in
                if let url = URL(string: link.url) {
                    Link(destination: url) {
                        Text(link.label)
                            .font(.nunitoSemiBold(11))
                            .foregroundStyle(Color.gbText)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.gbSurface2)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // 10 buckets matching our real granularity (half-heart units, 1...10)
    // rather than force-fitting the mockup's 7 decorative bars — this
    // reads the app's actual rating scale honestly instead of copying an
    // arbitrary placeholder bar count.
    private var ratingDistribution: [Int] {
        var counts = Array(repeating: 0, count: 10)
        for rating in communityRatings where (1...10).contains(rating) {
            counts[rating - 1] += 1
        }
        return counts
    }

    private var communityAverage: Double? {
        guard !communityRatings.isEmpty else { return nil }
        return Double(communityRatings.reduce(0, +)) / Double(communityRatings.count) / 2
    }

    private var ratingSummary: some View {
        HStack(alignment: .bottom, spacing: 16) {
            let maxCount = max(ratingDistribution.max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<10, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(colors: [Color.gbHeart, Color.gbHeartDim], startPoint: .top, endPoint: .bottom))
                        .frame(width: 8, height: max(4, 44 * CGFloat(ratingDistribution[index]) / CGFloat(maxCount)))
                }
            }
            VStack(spacing: 2) {
                HStack(spacing: 5) {
                    PixelHeart()
                        .frame(width: 20, height: 20)
                    Text(String(format: "%.1f", communityAverage ?? 0))
                        .font(.balooBold(26))
                        .foregroundStyle(Color.gbText)
                }
                Text("\(communityRatings.count) rating\(communityRatings.count == 1 ? "" : "s")")
                    .font(.nunitoSemiBold(10))
                    .foregroundStyle(Color.gbTextFaint)
                    .textCase(.uppercase)
            }
        }
    }

    private var friendsWhoRatedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Friends who rated this")
                .font(.balooSemiBold(13))
                .foregroundStyle(Color.gbTextFaint)
            HStack(spacing: 12) {
                ForEach(friendRatings) { entry in
                    VStack(spacing: 4) {
                        AsyncImage(url: entry.profile.avatarUrl.flatMap(URL.init)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gbSurface2.overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.gbTextFaint)
                            }
                        }
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())

                        if let heartRating = entry.heartRating {
                            HStack(spacing: 2) {
                                PixelHeart()
                                    .frame(width: 8, height: 8)
                                Text(String(format: "%.1f", heartRating))
                                    .font(.nunitoExtraBold(9))
                                    .foregroundStyle(Color.gbGold)
                            }
                        }
                    }
                }
            }
        }
    }

    private func playtimeText(_ minutes: Int) -> String {
        String(format: "%.0f hrs played", Double(minutes) / 60)
    }

    @ViewBuilder
    private func sectionCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.balooSemiBold(13))
                .foregroundStyle(Color.gbTextFaint)
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gbSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func load() async {
        guard let userId = appState.session?.userId else { return }

        log = try? await LogService.mostRecentLog(for: userId, gameId: game.id)
        if let log {
            participants = (try? await LogService.participants(for: log.id)) ?? []
        }
        if let steamAppId = game.steamAppId {
            steamEntry = try? await SteamSyncService.libraryEntry(for: userId, steamAppId: steamAppId)
        }

        communityRatings = (try? await LogService.ratings(forGameId: game.id)) ?? []

        let following = (try? await ProfileService.following(for: userId)) ?? []
        if !following.isEmpty {
            friendRatings = (try? await LogService.friendRatings(gameId: game.id, followingIds: following.map(\.id))) ?? []
        }
    }
}
