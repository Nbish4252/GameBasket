import SwiftUI

// Public logs with a written review, across all users — not filtered
// to friends (the schema has no "public but friends-first" ranking
// signal for this, and the mockup doesn't distinguish).
struct ReviewsView: View {
    @State private var reviews: [PostedLog] = []
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if !hasLoaded {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if reviews.isEmpty {
                VStack(spacing: 8) {
                    Text("No reviews yet")
                        .font(.balooSemiBold(15))
                        .foregroundStyle(Color.gbText)
                    Text("Written reviews from any player will show up here.")
                        .font(.nunito(13))
                        .foregroundStyle(Color.gbTextFaint)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(reviews) { log in
                            NavigationLink {
                                ReviewDetailView(log: log)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Text(log.profile.displayName ?? log.profile.username)
                                            .font(.nunitoBold(13))
                                            .foregroundStyle(Color.gbText)
                                        Text("on")
                                            .font(.nunito(12))
                                            .foregroundStyle(Color.gbTextFaint)
                                        Text(log.game.name)
                                            .font(.balooSemiBold(13))
                                            .foregroundStyle(Color.gbText)
                                        Spacer()
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
                                    if let review = log.review {
                                        Text(review)
                                            .font(.nunito(13))
                                            .foregroundStyle(Color.gbTextDim)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gbSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.gbBackground)
        .task {
            reviews = (try? await LogService.recentReviews()) ?? []
            hasLoaded = true
        }
    }
}
