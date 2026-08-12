import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if appState.isSignedIn {
            FeedView()
        } else {
            SignInView()
        }
    }
}
