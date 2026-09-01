import GoogleSignIn
import SwiftUI

@main
struct GameBasketApp: App {
    @StateObject private var appState = AppState()

    init() {
        AuthService.configureGoogleSignIn()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .task {
                    await appState.observeAuthChanges()
                }
        }
    }
}
