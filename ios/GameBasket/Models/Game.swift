import Foundation

struct StoreLink: Codable, Identifiable, Hashable {
    let label: String
    let url: String

    var id: String { url }
}

struct Game: Codable, Identifiable {
    let id: Int
    var name: String
    var coverUrl: String?
    var firstReleaseDate: Date?
    var genres: [String]
    var steamAppId: Int?
    var summary: String?
    var platforms: [String]
    var developer: String?
    var playtimeEstimateMinutes: Int?
    var storeLinks: [StoreLink]

    enum CodingKeys: String, CodingKey {
        case id, name, genres, summary, platforms, developer
        case coverUrl = "cover_url"
        case firstReleaseDate = "first_release_date"
        case steamAppId = "steam_app_id"
        case playtimeEstimateMinutes = "playtime_estimate_minutes"
        case storeLinks = "store_links"
    }
}
