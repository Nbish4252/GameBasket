import Foundation
import Supabase

enum LogService {
    static func create(_ log: GameLog) async throws {
        try await supabaseClient.from("logs").insert(log).execute()
    }

    // Embeds the related `games` row via PostgREST's FK-based join syntax
    // (unambiguous here since logs.game_id is the only FK to games) so the
    // feed can render a name/cover without a second round trip. games(*)
    // rather than an explicit column list so callers relying on the
    // embedded Game (e.g. GameDetailView needing steam_app_id) don't
    // silently get nil fields the select forgot to ask for.
    static func feedItems(for userId: UUID) async throws -> [LogFeedItem] {
        try await supabaseClient
            .from("logs")
            .select("id, rating, status, created_at, games(*)")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    // Both discovery-row queries below share this shape (a log embedding
    // its game and poster). games(*) is unambiguous (logs.game_id is the
    // only path PostgREST finds between logs and games), but plain
    // profiles(*) is NOT: log_likes and log_participants each carry a
    // second FK pair connecting logs to profiles as a many-to-many
    // junction, so PostgREST sees 3 candidate paths and 400s asking for
    // profiles!logs_user_id_fkey(*) — confirmed by hitting the REST API
    // directly. profiles(*) alone would build and even pass typechecking,
    // then fail at runtime, so this is worth getting right up front.

    // Bounded to a recent window rather than "all of a friend's history"
    // — this is a discovery feed, not an archive, and it keeps both the
    // "new" ordering and the "popular" tally (computed client-side from
    // this same array) cheap at any realistic friend-count.
    static func friendActivity(followingIds: [UUID], limit: Int = 50) async throws -> [PostedLog] {
        guard !followingIds.isEmpty else { return [] }
        return try await supabaseClient
            .from("logs")
            .select("id, rating, review, created_at, games(*), profiles!logs_user_id_fkey(*)")
            .in("user_id", value: followingIds)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    static func recentReviews(limit: Int = 30) async throws -> [PostedLog] {
        try await supabaseClient
            .from("logs")
            .select("id, rating, review, created_at, games(*), profiles!logs_user_id_fkey(*)")
            .not("review", operator: .is, value: "null")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    // Site-wide, not scoped to the caller's follows — tallied client-side
    // (same pattern as friendActivity's "popular" tally) from a bounded
    // recent window rather than a server-side GROUP BY, since a real
    // aggregate query would need a Postgres function + migration and
    // this stays a plain SELECT. gte's String value (ISO8601) is the
    // documented approach for supabase-swift's date filters — verified:
    // reliable both hit directly and from a non-cancelled caller. If this
    // ever comes back empty when data should exist, check for
    // CancellationError at the call site before suspecting this query —
    // that's what an empty result from here turned out to mean once.
    static func recentlyLoggedGames(sinceDays: Int = 7, limit: Int = 300) async throws -> [Game] {
        struct Row: Decodable {
            let game: Game
            enum CodingKeys: String, CodingKey { case game = "games" }
        }
        let cutoff = Calendar.current.date(byAdding: .day, value: -sinceDays, to: Date()) ?? Date()
        let rows: [Row] = try await supabaseClient
            .from("logs")
            .select("games(*)")
            .gte("created_at", value: ISO8601DateFormatter().string(from: cutoff))
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        return rows.map(\.game)
    }

    // Every rating for a game, site-wide — the raw 1-10 half-heart values,
    // for the caller to average/bucket as needed (GameDetailView uses
    // this for both the community average and the histogram).
    static func ratings(forGameId gameId: Int) async throws -> [Int] {
        struct RatingRow: Decodable { let rating: Int? }
        let rows: [RatingRow] = try await supabaseClient
            .from("logs")
            .select("rating")
            .eq("game_id", value: gameId)
            .execute()
            .value
        return rows.compactMap(\.rating)
    }

    // "Friends who rated this" — reuses PostedLog/the fixed
    // profiles!logs_user_id_fkey embed from friendActivity above, just
    // filtered to one game instead of a recent window.
    static func friendRatings(gameId: Int, followingIds: [UUID]) async throws -> [PostedLog] {
        guard !followingIds.isEmpty else { return [] }
        return try await supabaseClient
            .from("logs")
            .select("id, rating, review, created_at, games(*), profiles!logs_user_id_fkey(*)")
            .eq("game_id", value: gameId)
            .in("user_id", value: followingIds)
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

    // logs has no uniqueness constraint on (user_id, game_id) — a user
    // could log the same game more than once over time. "The" log for a
    // game detail page is the most recent one.
    static func mostRecentLog(for userId: UUID, gameId: Int) async throws -> GameLog? {
        let logs: [GameLog] = try await supabaseClient
            .from("logs")
            .select()
            .eq("user_id", value: userId)
            .eq("game_id", value: gameId)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return logs.first
    }

    // profiles(*) rather than an explicit column list — log_participants
    // has exactly one FK to profiles (profile_id), so the embed is
    // unambiguous, and selecting the full row avoids re-declaring every
    // Profile field here just to satisfy its non-optional properties.
    static func participants(for logId: UUID) async throws -> [Profile] {
        struct ParticipantRow: Decodable {
            let profile: Profile

            enum CodingKeys: String, CodingKey {
                case profile = "profiles"
            }
        }

        let rows: [ParticipantRow] = try await supabaseClient
            .from("log_participants")
            .select("profiles(*)")
            .eq("log_id", value: logId)
            .execute()
            .value
        return rows.map(\.profile)
    }
}
