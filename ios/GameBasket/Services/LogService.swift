import Foundation
import Supabase

enum LogService {
    static func create(_ log: GameLog) async throws {
        try await supabaseClient.from("logs").insert(log).execute()
    }

    // Embeds the related `games` row via PostgREST's FK-based join syntax
    // (unambiguous here since logs.game_id is the only FK to games) so the
    // feed can render a name/cover without a second round trip.
    static func feedItems(for userId: UUID) async throws -> [LogFeedItem] {
        try await supabaseClient
            .from("logs")
            .select("id, rating, status, created_at, games(id, name, cover_url, genres)")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    static func tagParticipants(logId: UUID, profileIds: [UUID]) async throws {
        guard !profileIds.isEmpty else { return }

        struct NewParticipant: Encodable {
            let logId: UUID
            let profileId: UUID

            enum CodingKeys: String, CodingKey {
                case logId = "log_id"
                case profileId = "profile_id"
            }
        }

        let rows = profileIds.map { NewParticipant(logId: logId, profileId: $0) }
        try await supabaseClient.from("log_participants").insert(rows).execute()
    }
}
