import Foundation
import Supabase

enum SteamSyncService {
    struct SyncResult: Decodable {
        let synced: Int
    }

    // SupabaseClient keeps the signed-in user's access token synced into
    // functions.invoke automatically (it listens to auth.authStateChanges
    // internally), so the steam-sync function sees a real Authorization
    // header with no extra wiring needed here.
    static func sync() async throws -> Int {
        let result: SyncResult = try await supabaseClient.functions.invoke("steam-sync")
        return result.synced
    }

    static func library(for userId: UUID) async throws -> [SteamLibraryEntry] {
        try await supabaseClient
            .from("steam_library")
            .select("steam_app_id, playtime_minutes")
            .eq("user_id", value: userId)
            .execute()
            .value
    }
}
