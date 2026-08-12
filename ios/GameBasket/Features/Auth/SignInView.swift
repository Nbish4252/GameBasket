import SwiftUI

struct SignInView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("GameBasket")
                .font(.largeTitle.bold())
            Text("Log and rate the games you play.")
                .foregroundStyle(.secondary)
            // TODO: drop in your existing GoogleSignIn button here, then
            // call AuthService.signInWithGoogle(idToken:accessToken:).
        }
        .padding()
    }
}
