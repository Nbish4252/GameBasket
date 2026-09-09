import Foundation
import Supabase

enum CommentService {
    static func comments(for logId: UUID) async throws -> [PostedComment] {
        try await supabaseClient
            .from("log_comments")
            .select("id, body, created_at, profiles(*)")
            .eq("log_id", value: logId)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    static func addComment(logId: UUID, userId: UUID, body: String) async throws {
        struct NewComment: Encodable {
            let logId: UUID
            let userId: UUID
            let body: String

            enum CodingKeys: String, CodingKey {
                case body
                case logId = "log_id"
                case userId = "user_id"
            }
        }

        try await supabaseClient
            .from("log_comments")
            .insert(NewComment(logId: logId, userId: userId, body: body))
            .execute()
    }
}
