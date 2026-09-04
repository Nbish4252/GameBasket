import SwiftUI

// Scoped to what a signed-in user can see about themselves without a real
// social graph: identity (avatar/name/bio), simple stats derived from
// their own logs, and the logs themselves. No followers/following counts —
// follows exists in the schema but showing counts honestly would need
// profile-lookup and mutual-follow UI this app doesn't have yet.
struct ProfileView: View {
    let profile: Profile
    let logs: [LogFeedItem]

    private var averageHeartRating: Double? {
        let rated = logs.compactMap(\.heartRating)
        guard !rated.isEmpty else { return nil }
        return rated.reduce(0, +) / Double(rated.count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    AsyncImage(url: profile.avatarUrl.flatMap(URL.init)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gbSurface2.overlay {
                            Image(systemName: "person.fill")
                                .foregroundStyle(Color.gbTextFaint)
                        }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.displayName ?? profile.username)
                            .font(.balooBold(19))
                            .foregroundStyle(Color.gbText)
                        Text("@\(profile.username)")
                            .font(.nunitoSemiBold(12))
                            .foregroundStyle(Color.gbTextDim)
                    }
                }

                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.nunito(13))
                        .foregroundStyle(Color.gbTextDim)
                }

                HStack(spacing: 12) {
                    statCard(title: "Games Logged", value: "\(logs.count)")
                    statCard(
                        title: "Avg Rating",
                        value: averageHeartRating.map { String(format: "%.1f", $0) } ?? "—",
                        showsHeart: averageHeartRating != nil
                    )
                }

                Text("Your Games")
                    .font(.balooSemiBold(15))
                    .foregroundStyle(Color.gbText)
                    .padding(.top, 4)

                if logs.isEmpty {
                    Text("You haven't logged any games yet.")
                        .font(.nunito(13))
                        .foregroundStyle(Color.gbTextFaint)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(logs.enumerated()), id: \.element.id) { index, item in
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
                    .padding(.horizontal, 12)
                    .background(Color.gbSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func statCard(title: String, value: String, showsHeart: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.balooSemiBold(11))
                .foregroundStyle(Color.gbTextFaint)
            HStack(spacing: 4) {
                if showsHeart {
                    PixelHeart()
                        .frame(width: 14, height: 14)
                }
                Text(value)
                    .font(.nunitoBold(18))
                    .foregroundStyle(Color.gbText)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gbSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
