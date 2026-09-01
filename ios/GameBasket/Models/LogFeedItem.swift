import Foundation

// Read-only shape for feed display — joins in just enough of `games` via
// a PostgREST embed so the feed can show a name/cover instead of a raw
// game_id. Deliberately separate from GameLog, which is the write model
// for creating/editing a log entry.
struct LogFeedItem: Decodable, Identifiable {
    let id: UUID
    let rating: Int?
    let status: LogStatus
    let createdAt: Date
    let game: Game

    var heartRating: Double? {
        rating.map { Double($0) / 2 }
    }

    enum CodingKeys: String, CodingKey {
        case id, rating, status
        case createdAt = "created_at"
        case game = "games"
    }
}
