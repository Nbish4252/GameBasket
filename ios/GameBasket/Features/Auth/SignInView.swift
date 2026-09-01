import SwiftUI

struct SignInView: View {
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("GameBasket")
                .font(.largeTitle.bold())
            Text("Log and rate the games you play.")
                .foregroundStyle(.secondary)

            Button("Sign in with Google") {
                Task { await signIn() }
            }
            .disabled(isSigningIn)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }

    @MainActor
    private func signIn() async {
        guard let rootViewController else {
            errorMessage = "Couldn't find a window to present sign-in from."
            return
        }
        isSigningIn = true
        defer { isSigningIn = false }
        do {
            try await AuthService.signInWithGoogle(presenting: rootViewController)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // AppState updates itself via AppState.observeAuthChanges() once
    // signInWithGoogle succeeds — nothing here touches AppState directly.
    private var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: \.isKeyWindow)?.rootViewController
    }
}
