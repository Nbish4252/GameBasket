import Foundation
import Supabase

enum RecommendationService {
    // Same auth pattern as SteamSyncService.sync(): supabaseClient keeps
    // the signed-in user's access token synced into functions.invoke
    // automatically, so recommend-games sees a real Authorization header
    // with no extra wiring needed here.
    static func recommendations() async throws -> [GameRecommendation] {
        let response: RecommendationResponse = try await supabaseClient.functions.invoke("recommend-games")
        return response.recommendations
    }
}
