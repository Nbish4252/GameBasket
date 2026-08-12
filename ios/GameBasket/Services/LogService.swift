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
}
