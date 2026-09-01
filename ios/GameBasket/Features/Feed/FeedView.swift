import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var appState: AppState
    @State private var logs: [GameLog] = []
    @State private var isPresentingSearch = false

    var body: some View {
        NavigationStack {
            List(logs) { log in
                Text("Game #\(log.gameId) — \(log.heartRating.map { String($0) } ?? "unrated")")
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingSearch = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // Plain functional entry point into Search → Log Game — no nav
            // chrome/tab bar yet, that's deferred second-phase work.
            .sheet(isPresented: $isPresentingSearch, onDismiss: { Task { await loadLogs() } }) {
                GameSearchView()
            }
            .task {
                await loadLogs()
            }
        }
    }

    private func loadLogs() async {
        guard let userId = appState.session?.userId else { return }
        logs = (try? await LogService.logs(for: userId)) ?? []
    }
}
