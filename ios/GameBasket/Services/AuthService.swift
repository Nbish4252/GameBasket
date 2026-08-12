import Foundation
import Supabase

// Bridges your existing GoogleSignIn flow into a Supabase session — call
// this after GIDSignIn.sharedInstance.signIn succeeds, passing the
// resulting ID token. Face ID/biometrics stay entirely local (gating
// access to the cached session in Keychain) and don't touch Supabase.
enum AuthService {
    static func signInWithGoogle(idToken: String, accessToken: String) async throws {
        try await supabaseClient.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: idToken, accessToken: accessToken)
        )
    }

    static func signOut() async throws {
        try await supabaseClient.auth.signOut()
    }
}
