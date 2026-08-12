import SwiftUI

struct LogGameView: View {
    let game: Game

    @State private var rating: Double = 0
    @State private var review = ""
    @State private var status: LogStatus = .completed
    @State private var playedOn = Date()

    var body: some View {
        Form {
            Section(game.name) {
                Stepper(value: $rating, in: 0...5, step: 0.5) {
                    Text("Rating: \(rating, specifier: "%.1f")★")
                }
                Picker("Status", selection: $status) {
                    ForEach(LogStatus.allCases, id: \.self) { Text($0.rawValue.capitalized) }
                }
                DatePicker("Played on", selection: $playedOn, displayedComponents: .date)
                TextField("Review (optional)", text: $review, axis: .vertical)
            }
        }
        .navigationTitle("Log Game")
        // TODO: save via LogService.create(...) once appState exposes the
        // signed-in user id here.
    }
}
