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
                } else {
                    ProgressView()
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
        }
        .preferredColorScheme(.dark)
        .onAppear {
            Task { await load() }
        }
    }

    private func load() async {
        guard let userId = appState.session?.userId else { return }
        async let profileFetch = ProfileService.profile(for: userId)
        async let logsFetch = LogService.feedItems(for: userId)
        profile = try? await profileFetch
        logs = (try? await logsFetch) ?? []
    }
}
