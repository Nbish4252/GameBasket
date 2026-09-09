import SwiftUI

// Scoped to what the schema actually supports today: name/cover/release
// date/genres, the signed-in user's own most recent log for this game
// (with played-with tags), and Steam playtime if a steam_app_id match
// exists. Deliberately NOT included, since we have no real data behind
// them: rating-distribution histogram, "friends who rated this" avatar
// strip, store links — those need a real social graph / external
// linking this app doesn't have yet, and faking them would be dishonest.
struct GameDetailView: View {
    let game: Game

    @EnvironmentObject private var appState: AppState
    @State private var log: GameLog?
    @State private var participants: [Profile] = []
    @State private var steamEntry: SteamLibraryEntry?

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

                if let summary = game.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.nunito(13))
                        .foregroundStyle(Color.gbTextDim)
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
    }
}
