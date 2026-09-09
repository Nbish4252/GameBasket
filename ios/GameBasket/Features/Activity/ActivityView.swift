import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var appState: AppState
    @State private var items: [ActivityItem] = []
    @State private var hasLoaded = false

    var body: some View {
        NavigationStack {
            Group {
                if !hasLoaded {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity)
                } else if items.isEmpty {
                    emptyState
                        .transition(.opacity)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                if index > 0 {
                                    Divider().background(Color.gbLine)
                                }
                                row(for: item)
                            }
                        }
                        .background(Color.gbSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding()
                    }
                    .refreshable {
                        await load()
                    }
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gbBackground)
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.gbBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            Task { await load() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bolt")
                .font(.system(size: 28))
                .foregroundStyle(Color.gbTextFaint)
            Text("No activity yet")
                .font(.balooSemiBold(15))
                .foregroundStyle(Color.gbText)
            Text("New followers and likes on your logs will show up here.")
                .font(.nunito(13))
                .foregroundStyle(Color.gbTextFaint)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func row(for item: ActivityItem) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: item.profile.avatarUrl.flatMap(URL.init)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gbSurface2.overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.gbTextFaint)
                }
            }
            .frame(width: 36, height: 36)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(message(for: item))
                    .font(.nunitoSemiBold(13))
                    .foregroundStyle(Color.gbText)
                Text(item.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.nunito(11))
                    .foregroundStyle(Color.gbTextFaint)
            }

            Spacer()

            Image(systemName: icon(for: item))
                .foregroundStyle(iconColor(for: item))
        }
        .padding(12)
    }

    private func message(for item: ActivityItem) -> String {
        let name = item.profile.displayName ?? item.profile.username
        switch item.kind {
        case .newFollower:
            return "\(name) started following you"
        case .like(let gameName):
            return "\(name) liked your \(gameName) log"
        }
    }

    private func icon(for item: ActivityItem) -> String {
        switch item.kind {
        case .newFollower: return "person.fill.badge.plus"
        case .like: return "heart.fill"
        }
    }

    private func iconColor(for item: ActivityItem) -> Color {
        switch item.kind {
        case .newFollower: return .gbGreen
        case .like: return .gbHeart
        }
    }

    // See JournalView.load()'s comment — a cancelled refresh must not
    // clobber good data with an empty result.
    private func load() async {
        guard let userId = appState.session?.userId else { return }
        do {
            let fetched = try await ActivityService.recentActivity(for: userId)
            withAnimation(.easeOut(duration: 0.25)) {
                items = fetched
                hasLoaded = true
            }
        } catch is CancellationError {
            // Leave existing state as-is.
        } catch {
            withAnimation(.easeOut(duration: 0.25)) {
                hasLoaded = true
            }
        }
    }
}
