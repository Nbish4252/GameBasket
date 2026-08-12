import Foundation

struct Game: Codable, Identifiable {
    let id: Int
    var name: String
    var coverUrl: String?
    var firstReleaseDate: Date?
    var genres: [String]
    var steamAppId: Int?
    var summary: String?

    enum CodingKeys: String, CodingKey {
        case id, name, genres, summary
        case coverUrl = "cover_url"
        case firstReleaseDate = "first_release_date"
        case steamAppId = "steam_app_id"
    }
}
