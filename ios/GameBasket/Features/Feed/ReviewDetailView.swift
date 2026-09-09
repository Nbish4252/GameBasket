import SwiftUI

// A real detail screen for one posted review/log, matching the
// mockup's dedicated Review screen: reviewer identity, "Logged X ago",
// the game it's about, played-with tags, the review text, like/comment
// counts, and a share action. "hrs played" from the mockup's meta line
// is left out — we only have that for Steam-linked games via the
// signed-in user's own library sync, not as a general per-review stat,
// and this screen is about whoever wrote the review, not the viewer.
struct ReviewDetailView: View {
    let log: PostedLog

    @EnvironmentObject private var appState: AppState
    @State private var participants: [Profile] = []
    @State private var likerIds: [UUID] = []
    @State private var comments: [PostedComment] = []
    @State private var newCommentText = ""
    @State private var isPostingComment = false
    @State private var isTogglingLike = false

    private var isLikedByMe: Bool {
        guard let userId = appState.session?.userId else { return false }
        return likerIds.contains(userId)
    }

    private var shareText: String {
        "\(log.profile.displayName ?? log.profile.username) logged \(log.game.name) on GameBasket"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                reviewerHeader

                NavigationLink {
                    GameDetailView(game: log.game)
                } label: {
                    gameChip
                }
                .buttonStyle(.plain)

                if !participants.isEmpty {
                    playedWithRow
                }

                if let review = log.review, !review.isEmpty {
                    Text(review)
                        .font(.nunito(14))
                        .foregroundStyle(Color.gbTextDim)
                }

                footerActions

                Divider().background(Color.gbLine)

                commentsSection
            }
            .padding()
        }
        .background(Color.gbBackground)
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.gbBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
        .task {
            await load()
        }
    }

    private var reviewerHeader: some View {
        HStack(spacing: 10) {
            AsyncImage(url: log.profile.avatarUrl.flatMap(URL.init)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gbSurface2.overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Color.gbTextFaint)
                }
            }
            .frame(width: 42, height: 42)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(log.profile.displayName ?? log.profile.username)
                    .font(.balooSemiBold(15))
                    .foregroundStyle(Color.gbText)
                Text("Logged \(relativeTime(log.createdAt))")
                    .font(.nunitoSemiBold(11))
                    .foregroundStyle(Color.gbTextFaint)
            }
        }
    }

    private var gameChip: some View {
        HStack(spacing: 12) {
            AsyncImage(url: log.game.coverUrl.flatMap(URL.init)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gbSurface2
            }
            .frame(width: 44, height: 58)
            .clipShape(RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 4) {
                Text(log.game.name)
                    .font(.balooSemiBold(14))
                    .foregroundStyle(Color.gbText)
                if let heartRating = log.heartRating {
                    HStack(spacing: 3) {
                        PixelHeart()
                            .frame(width: 13, height: 13)
                        Text(String(format: "%.1f", heartRating))
                            .font(.nunitoExtraBold(12))
                            .foregroundStyle(Color.gbHeart)
                    }
                }
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(Color.gbTextFaint)
        }
        .padding(10)
        .background(Color.gbSurface2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var playedWithRow: some View {
        HStack(spacing: 8) {
            Text("PLAYED WITH")
                .font(.nunitoExtraBold(11))
                .foregroundStyle(Color.gbGreen)
            Text(participants.map { $0.displayName ?? $0.username }.joined(separator: ", "))
                .font(.nunitoSemiBold(11))
                .foregroundStyle(Color.gbTextDim)
        }
        .padding(10)
        .background(Color.gbSurface2)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var footerActions: some View {
        HStack(spacing: 20) {
            Button {
                Task { await toggleLike() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isLikedByMe ? "heart.fill" : "heart")
                    Text("\(likerIds.count)")
                }
            }
            .disabled(isTogglingLike)
            .foregroundStyle(isLikedByMe ? Color.gbHeart : Color.gbTextFaint)

            HStack(spacing: 6) {
                Image(systemName: "bubble.left")
                Text("\(comments.count)")
            }
            .foregroundStyle(Color.gbTextFaint)

            ShareLink(item: shareText) {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .foregroundStyle(Color.gbTextFaint)
            }
        }
        .font(.nunitoExtraBold(12))
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Comments")
                .font(.balooSemiBold(14))
                .foregroundStyle(Color.gbText)

            if comments.isEmpty {
                Text("No comments yet.")
                    .font(.nunito(12))
                    .foregroundStyle(Color.gbTextFaint)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(comments) { comment in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(comment.profile.displayName ?? comment.profile.username)
                                .font(.nunitoBold(12))
                                .foregroundStyle(Color.gbText)
                            Text(comment.body)
                                .font(.nunito(13))
                                .foregroundStyle(Color.gbTextDim)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Add a comment…", text: $newCommentText)
                    .font(.nunito(13))
                    .foregroundStyle(Color.gbText)
                    .padding(10)
                    .background(Color.gbSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("Post") {
                    Task { await postComment() }
                }
                .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPostingComment)
                .font(.nunitoBold(13))
                .foregroundStyle(Color.gbGreen)
            }
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func load() async {
        participants = (try? await LogService.participants(for: log.id)) ?? []
        likerIds = (try? await LikeService.likes(for: log.id)) ?? []
        comments = (try? await CommentService.comments(for: log.id)) ?? []
    }

    private func toggleLike() async {
        guard let userId = appState.session?.userId else { return }
        isTogglingLike = true
        defer { isTogglingLike = false }
        do {
            if isLikedByMe {
                try await LikeService.unlike(logId: log.id, userId: userId)
                likerIds.removeAll { $0 == userId }
            } else {
                try await LikeService.like(logId: log.id, userId: userId)
                likerIds.append(userId)
            }
        } catch {
            // Best-effort — UI state simply doesn't change if this fails.
        }
    }

    private func postComment() async {
        guard let userId = appState.session?.userId else { return }
        let body = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        isPostingComment = true
        defer { isPostingComment = false }
        do {
            try await CommentService.addComment(logId: log.id, userId: userId, body: body)
            newCommentText = ""
            comments = (try? await CommentService.comments(for: log.id)) ?? []
        } catch {
            // Best-effort — leave the typed text in place so the user can retry.
        }
    }
}
