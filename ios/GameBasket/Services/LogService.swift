import Foundation
import Supabase

enum LogService {
    static func create(_ log: GameLog) async throws {
        try await supabaseClient.from("logs").insert(log).execute()
    }

    static func logs(for userId: UUID) async throws -> [GameLog] {
        try await supabaseClient
            .from("logs")
            .select()
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
