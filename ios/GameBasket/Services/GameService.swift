import Foundation
import Supabase

enum GameService {
    static func search(query: String) async throws -> [Game] {
        let response = try await supabaseClient.functions.invoke(
            "igdb-search",
            options: .init(body: ["query": query])
        )
        return try JSONDecoder().decode([Game].self, from: response.data)
    }
}
