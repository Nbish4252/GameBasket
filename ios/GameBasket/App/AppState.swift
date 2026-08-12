import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published var session: UserSession?

    var isSignedIn: Bool { session != nil }
}

struct UserSession {
    let userId: UUID
    let username: String
}
