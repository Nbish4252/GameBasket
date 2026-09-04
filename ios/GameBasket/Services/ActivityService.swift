import Foundation
import Supabase

enum ActivityService {
    // Two hand-joined queries per activity type rather than embedded
    // selects: `follows` has two FKs to `profiles` (follower_id and
    // following_id), so `profiles(*)` on it is ambiguous without a
    // constraint-name-qualified embed we haven't verified against the
    // resolved supabase-swift version (same reasoning as
    // ProfileService.following). `log_likes` needs a two-hop join
    // (log_likes -> logs -> whether logs.user_id == me) that a single
    // embedded select can't express at all. Bounded to a recent window
    // per type, then merged and sorted client-side — this is a small
    // per-user feed, not an archive.
    static func recentActivity(for userId: UUID, limit: Int = 30) async throws -> [ActivityItem] {
        async let followers = recentFollowers(for: userId, limit: limit)
        async let likes = recentLikes(for: userId, limit: limit)
        let items = try await followers + likes
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    private static func recentFollowers(for userId: UUID, limit: Int) async throws -> [ActivityItem] {
        struct FollowRow: Decodable {
            let followerId: UUID
            let createdAt: Date

            enum CodingKeys: String, CodingKey {
                case followerId = "follower_id"
                case createdAt = "created_at"
            }
        }

        let rows: [FollowRow] = try await supabaseClient
            .from("follows")
            .select("follower_id, created_at")
            .eq("following_id", value: userId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        guard !rows.isEmpty else { return [] }

        let profiles: [Profile] = try await supabaseClient
            .from("profiles")
            .select()
            .in("id", value: rows.map(\.followerId))
            .execute()
            .value
        let profilesById = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })

        return rows.compactMap { row in
            guard let profile = profilesById[row.followerId] else { return nil }
            return ActivityItem(id: "follow-\(row.followerId)-\(row.createdAt)", profile: profile, kind: .newFollower, createdAt: row.createdAt)
        }
    }

    private static func recentLikes(for userId: UUID, limit: Int) async throws -> [ActivityItem] {
        struct OwnLog: Decodable {
            let id: UUID
            let game: Game

            enum CodingKeys: String, CodingKey {
                case id
                case game = "games"
            }
        }
        let ownLogs: [OwnLog] = try await supabaseClient
            .from("logs")
            .select("id, games(*)")
            .eq("user_id", value: userId)
            .execute()
            .value
        guard !ownLogs.isEmpty else { return [] }
        let gameNameByLogId = Dictionary(uniqueKeysWithValues: ownLogs.map { ($0.id, $0.game.name) })

        struct LikeRow: Decodable {
            let logId: UUID
            let userId: UUID
            let createdAt: Date

            enum CodingKeys: String, CodingKey {
                case logId = "log_id"
                case userId = "user_id"
                case createdAt = "created_at"
            }
        }
        let likeRows: [LikeRow] = try await supabaseClient
            .from("log_likes")
            .select("log_id, user_id, created_at")
            .in("log_id", value: Array(gameNameByLogId.keys))
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        guard !likeRows.isEmpty else { return [] }

        let likerProfiles: [Profile] = try await supabaseClient
            .from("profiles")
            .select()
            .in("id", value: likeRows.map(\.userId))
            .execute()
            .value
        let profilesById = Dictionary(uniqueKeysWithValues: likerProfiles.map { ($0.id, $0) })

        return likeRows.compactMap { row in
            guard let profile = profilesById[row.userId], let gameName = gameNameByLogId[row.logId] else { return nil }
            return ActivityItem(
                id: "like-\(row.logId)-\(row.userId)",
                profile: profile,
                kind: .like(gameName: gameName),
                createdAt: row.createdAt
            )
        }
    }
}
