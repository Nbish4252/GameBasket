import Foundation
import Supabase

enum ProfileService {
    // .first instead of PostgREST's .single() modifier — same reasoning
    // as the two-query split below, this avoids relying on a
    // supabase-swift call shape that hasn't been checked against the
    // resolved package version.
    static func profile(for userId: UUID) async throws -> Profile? {
        let profiles: [Profile] = try await supabaseClient
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
            .value
        return profiles.first
    }

    // Two queries instead of a single embedded-resource select: supabase-swift's
    // join syntax needs the exact foreign key constraint name, which hasn't
    // been verified against a resolved package — this is the safer version
    // until that's confirmed.
    static func following(for userId: UUID) async throws -> [Profile] {
        struct FollowRow: Decodable {
            let followingId: UUID

            enum CodingKeys: String, CodingKey {
                case followingId = "following_id"
            }
        }

        let follows: [FollowRow] = try await supabaseClient
            .from("follows")
            .select("following_id")
            .eq("follower_id", value: userId)
            .execute()
            .value

        guard !follows.isEmpty else { return [] }

        return try await supabaseClient
            .from("profiles")
            .select()
            .in("id", value: follows.map(\.followingId))
            .execute()
            .value
    }

    static func updateSteamId(userId: UUID, steamId: String) async throws {
        try await supabaseClient
            .from("profiles")
            .update(["steam_id": steamId])
            .eq("id", value: userId)
            .execute()
    }
}
