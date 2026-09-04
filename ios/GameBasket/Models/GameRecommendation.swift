import Foundation

struct GameRecommendation: Decodable, Identifiable {
    let title: String
    let reason: String

    var id: String { title }
}

// Matches recommend-games' RESPONSE_SCHEMA exactly, guaranteed by the
// Edge Function's use of Claude's structured outputs (output_config.format).
struct RecommendationResponse: Decodable {
    let recommendations: [GameRecommendation]
}
