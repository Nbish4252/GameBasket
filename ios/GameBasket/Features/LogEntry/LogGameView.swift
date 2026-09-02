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
            Section(
                header: Text(game.name)
                    .font(.balooSemiBold(15))
                    .foregroundStyle(Color.gbText)
            ) {
                Stepper(value: $rating, in: 0...5, step: 0.5) {
                    HStack(spacing: 6) {
                        PixelHeart()
                            .frame(width: 14, height: 14)
                        Text("Rating: \(rating, specifier: "%.1f")")
                            .font(.nunito(15))
                            .foregroundStyle(Color.gbText)
                    }
                }
                .listRowBackground(Color.gbSurface)

                Picker("Status", selection: $status) {
                    ForEach(LogStatus.allCases, id: \.self) { Text($0.rawValue.capitalized) }
                }
                .listRowBackground(Color.gbSurface)

                DatePicker("Played on", selection: $playedOn, displayedComponents: .date)
                    .listRowBackground(Color.gbSurface)

                TextField("Review (optional)", text: $review, axis: .vertical)
                    .listRowBackground(Color.gbSurface)
            }

            if !friends.isEmpty {
                Section(
                    header: Text("Played with")
                        .font(.balooSemiBold(13))
                        .foregroundStyle(Color.gbTextFaint)
                ) {
                    ForEach(friends) { friend in
                        Button {
                            toggle(friend.id)
                        } label: {
                            HStack {
                                Text(friend.displayName ?? friend.username)
                                    .font(.nunito(15))
                                    .foregroundStyle(Color.gbText)
                                Spacer()
                                if participantIds.contains(friend.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.gbGreen)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.gbSurface)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.gbBackground)
        .navigationTitle("Log Game")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Log Game")
                    .font(.balooBold(17))
                    .foregroundStyle(Color.gbText)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { Task { await save() } }
                    .disabled(isSaving)
                    .tint(Color.gbGreen)
            }
        }
        .toolbarBackground(Color.gbBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark)
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
