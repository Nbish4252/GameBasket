import Foundation

// A log plus its game and poster — the shape both "New from friends" and
// the Reviews tab need. See LogService.friendActivity's comment: the
// `profiles` embed needs the FK-qualified form (profiles!logs_user_id_fkey)
// since log_likes/log_participants make plain profiles(*) ambiguous —
// this struct's shape doesn't change, only the select string that fills it.
struct PostedLog: Decodable, Identifiable {
    let id: UUID
    let rating: Int?
    let review: String?
    let createdAt: Date
    let game: Game
    let profile: Profile

    var heartRating: Double? {
        rating.map { Double($0) / 2 }
    }

    enum CodingKeys: String, CodingKey {
        case id, rating, review
        case createdAt = "created_at"
        case game = "games"
        case profile = "profiles"
    }
}
