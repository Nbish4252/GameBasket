import SwiftUI

// Owns loading the signed-in user's own profile row so ProfileView
// itself can stay a plain, testable "given a Profile, render it" view.
struct ProfileTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var profile: Profile?
    @State private var logs: [LogFeedItem] = []
    @State private var isPresentingSteamSyncTest = false

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    ProfileView(profile: profile, logs: logs)
                        .transition(.opacity)
                } else {
                    ProgressView()
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gbBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // TEMPORARY: only for testing steam-sync end to end. Remove
                // once real Steam-linking UI (a settings screen) exists.
                ToolbarItem(placement: .topBarTrailing) {
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
            .sheet(isPresented: $isPresentingSteamSyncTest) {
                NavigationStack {
                    SteamSyncTestView()
                }
            }
            // Attached here rather than on ProfileView's internal
            // ScrollView directly, since ProfileTabView (not ProfileView)
            // owns load() — .refreshable propagates down via environment
            // to whichever ScrollView/List is in the content, so this
            // still reaches ProfileView's scroll view correctly.
            .refreshable {
                await load()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            Task { await load() }
        }
    }

    // See JournalView.load()'s comment (Features/Feed) — a cancelled
    // refresh must not clobber good data with an empty/nil result.
    private func load() async {
        guard let userId = appState.session?.userId else { return }
        do {
            async let profileFetch = ProfileService.profile(for: userId)
            async let logsFetch = LogService.feedItems(for: userId)
            let (fetchedProfile, fetchedLogs) = try await (profileFetch, logsFetch)
            withAnimation(.easeOut(duration: 0.25)) {
                profile = fetchedProfile
                logs = fetchedLogs
            }
        } catch is CancellationError {
            // Leave existing state as-is.
        } catch {
            // Both fetches are independently fallible; nothing useful to
            // do here beyond leaving prior state in place, same as above.
        }
    }
}
