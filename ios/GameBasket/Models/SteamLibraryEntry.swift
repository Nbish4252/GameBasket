import Foundation

struct SteamLibraryEntry: Decodable {
    let steamAppId: Int
    let playtimeMinutes: Int

    enum CodingKeys: String, CodingKey {
        case steamAppId = "steam_app_id"
        case playtimeMinutes = "playtime_minutes"
    }
}
