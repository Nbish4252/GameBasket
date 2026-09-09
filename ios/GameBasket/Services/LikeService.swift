import Foundation
import Supabase

enum LikeService {
    // Returns every liker's user_id for a log rather than a separate
    // count+isLiked pair of queries — like counts are small at this
    // scale, and the caller can derive both (count, "did I like this")
    // from one array, same client-side-derivation approach used
    // elsewhere (friendActivity's popular tally, ProfileView's stats).
    static func likes(for logId: UUID) async throws -> [UUID] {
        struct Row: Decodable {
            let userId: UUID
            enum CodingKeys: String, CodingKey { case userId = "user_id" }
        }
        let rows: [Row] = try await supabaseClient
            .from("log_likes")
            .select("user_id")
            .eq("log_id", value: logId)
            .execute()
            .value
        return rows.map(\.userId)
    }

    static func like(logId: UUID, userId: UUID) async throws {
        struct NewLike: Encodable {
            let logId: UUID
            let userId: UUID
            enum CodingKeys: String, CodingKey {
                case logId = "log_id"
                case userId = "user_id"
            }
        }
        try await supabaseClient
            .from("log_likes")
            .insert(NewLike(logId: logId, userId: userId))
            .execute()
    }

    static func unlike(logId: UUID, userId: UUID) async throws {
        try await supabaseClient
            .from("log_likes")
            .delete()
            .eq("log_id", value: logId)
            .eq("user_id", value: userId)
            .execute()
    }
}
