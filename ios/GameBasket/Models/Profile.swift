import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    var username: String
    var displayName: String?
    var avatarUrl: String?
    var bio: String?
    var steamId: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, username, bio
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case steamId = "steam_id"
        case createdAt = "created_at"
    }
}
