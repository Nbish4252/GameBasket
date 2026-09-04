import SwiftUI

// Owns loading the signed-in user's own profile row so ProfileView
// itself can stay a plain, testable "given a Profile, render it" view.
struct ProfileTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var profile: Profile?

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    ProfileView(profile: profile)
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gbBackground)
            .navigationTitle("Profile")
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

    private func load() async {
        guard let userId = appState.session?.userId else { return }
        profile = try? await ProfileService.profile(for: userId)
    }
}
