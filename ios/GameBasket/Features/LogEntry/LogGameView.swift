import SwiftUI

struct LogGameView: View {
    let game: Game

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var rating: Double = 0
    @State private var review = ""
    @State private var status: LogStatus = .playing
    @State private var playedOn = Date()
    @State private var friends: [Profile] = []
    @State private var participantIds: Set<UUID> = []
    @State private var isSaving = false

    var body: some View {
        Form {
            Section(game.name) {
                Stepper(value: $rating, in: 0...5, step: 0.5) {
                    Text("Rating: \(rating, specifier: "%.1f")♥")
                }
                Picker("Status", selection: $status) {
                    ForEach(LogStatus.allCases, id: \.self) { Text($0.rawValue.capitalized) }
                }
                DatePicker("Played on", selection: $playedOn, displayedComponents: .date)
                TextField("Review (optional)", text: $review, axis: .vertical)
            }

            if !friends.isEmpty {
                Section("Played with") {
                    ForEach(friends) { friend in
                        Button {
                            toggle(friend.id)
                        } label: {
                            HStack {
                                Text(friend.displayName ?? friend.username)
                                Spacer()
                                if participantIds.contains(friend.id) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                    }
                }
            }
        }
        .navigationTitle("Log Game")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(isSaving)
            }
        }
        .task {
            guard let userId = appState.session?.userId else { return }
            friends = (try? await ProfileService.following(for: userId)) ?? []
        }
    }

    private func toggle(_ id: UUID) {
        if participantIds.contains(id) {
            participantIds.remove(id)
        } else {
            participantIds.insert(id)
        }
    }

    private func save() async {
        guard let userId = appState.session?.userId else { return }
        isSaving = true
        defer { isSaving = false }

        let log = GameLog(
            id: UUID(),
            userId: userId,
            gameId: game.id,
            rating: rating > 0 ? Int((rating * 2).rounded()) : nil,
            review: review.isEmpty ? nil : review,
            playedOn: playedOn,
            status: status,
            createdAt: Date(),
            updatedAt: Date()
        )

        do {
            try await LogService.create(log)
            try await LogService.tagParticipants(logId: log.id, profileIds: Array(participantIds))
            dismiss()
        } catch {
            // TODO: surface a user-facing error once we have a place to show it
        }
    }
}
