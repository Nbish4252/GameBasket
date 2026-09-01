import Foundation
import Supabase

@MainActor
final class AppState: ObservableObject {
    @Published var session: UserSession?

    var isSignedIn: Bool { session != nil }

    // Runs for the life of the app. authStateChanges fires immediately with
    // the restored session (if any) on launch, then again on every sign-in/
    // sign-out — this is the only place that writes `session`, so
    // AuthService never has to touch AppState directly.
    func observeAuthChanges() async {
        for await (_, session) in supabaseClient.auth.authStateChanges {
            self.session = session.map { UserSession(userId: $0.user.id) }
        }
    }
}

struct UserSession {
    let userId: UUID
}
