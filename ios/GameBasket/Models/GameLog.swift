import Foundation

enum LogStatus: String, Codable, CaseIterable {
    case playing, completed, backlog, abandoned
}

struct GameLog: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var gameId: Int
    var rating: Int? // half-star units: 1...10 == 0.5...5.0 stars
    var review: String?
    var playedOn: Date?
    var status: LogStatus
    let createdAt: Date
    var updatedAt: Date

    var starRating: Double? {
        rating.map { Double($0) / 2 }
    }

    enum CodingKeys: String, CodingKey {
        case id, rating, review, status
        case userId = "user_id"
        case gameId = "game_id"
        case playedOn = "played_on"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
