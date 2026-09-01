import Foundation
import GoogleSignIn
import Supabase
import UIKit

// NOTE: supabase-swift's and GoogleSignIn's APIs shift between versions —
// signInWithIdToken, GIDConfiguration, and GIDSignIn.signIn(withPresenting:)
// are written from current public docs, not verified against the exact
// resolved package versions. Check against autocomplete if these don't compile.
enum AuthService {
    enum AuthError: Error {
        case missingIdToken
    }

    // Must run once before any sign-in attempt (called from GameBasketApp.init).
    // GIDSignIn needs the app's own iOS client ID to present the sign-in
    // sheet. serverClientID is the separate Web client — without it, the
    // ID token's audience wouldn't match what Supabase's Google provider
    // is configured to accept, and signInWithIdToken would reject it.
    static func configureGoogleSignIn() {
        guard
            let clientId = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String,
            let serverClientId = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_SERVER_CLIENT_ID") as? String
        else {
            fatalError("Missing GOOGLE_CLIENT_ID / GOOGLE_SERVER_CLIENT_ID — set them in Secrets.xcconfig (see README).")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId, serverClientID: serverClientId)
    }

    // Face ID/biometrics only gate the locally cached session in Keychain
    // and never touch Supabase — that's handled entirely on-device,
    // separately from this flow.
    //
    // GoogleSignIn 7.x's signInWithPresentingViewController has no public
    // nonce parameter — it embeds one internally for its own OAuth request
    // and gives us no way to choose or retrieve the un-hashed original.
    // Supabase's nonce check compares a hash of whatever we send against
    // the token's nonce claim, so there is no value we could pass here
    // that would ever match. This requires "Skip nonce checks" enabled on
    // the Google provider in the Supabase dashboard — see README.
    @MainActor
    static func signInWithGoogle(presenting viewController: UIViewController) async throws {
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingIdToken
        }
        try await supabaseClient.auth.signInWithIdToken(
            credentials: .init(provider: .google, idToken: idToken, accessToken: result.user.accessToken.tokenString)
        )
    }

    static func signOut() async throws {
        GIDSignIn.sharedInstance.signOut()
        try await supabaseClient.auth.signOut()
    }
}
