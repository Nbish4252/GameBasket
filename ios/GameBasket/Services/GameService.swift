import Foundation
import Supabase

// igdb-search returns first_release_date as a plain "yyyy-MM-dd" string
// (unlike the full ISO8601 timestamps Postgres returns elsewhere), so this
// needs its own decoder rather than the default one or SupabaseService's
// postgresDecoder.
private let igdbDecoder: JSONDecoder = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(identifier: "UTC")

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(formatter)
    return decoder
}()

enum GameService {
    static func search(query: String) async throws -> [Game] {
        return try await supabaseClient.functions.invoke(
            "igdb-search",
            options: .init(body: ["query": query]),
            decoder: igdbDecoder
        )
    }
}
