import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var appState: AppState
    @State private var logs: [GameLog] = []

    var body: some View {
        NavigationStack {
            List(logs) { log in
                Text("Game #\(log.gameId) — \(log.starRating.map { String($0) } ?? "unrated")")
            }
            .navigationTitle("Feed")
            .task {
                guard let userId = appState.session?.userId else { return }
                logs = (try? await LogService.logs(for: userId)) ?? []
            }
        }
    }
}
