import Foundation

// log_comments has exactly one FK to profiles (user_id) — unlike logs,
// nothing else joins this table to profiles, so the plain profiles(*)
// embed is unambiguous (no !fkey qualifier needed here).
struct PostedComment: Decodable, Identifiable {
    let id: UUID
    let body: String
    let createdAt: Date
    let profile: Profile

    enum CodingKeys: String, CodingKey {
        case id, body
        case createdAt = "created_at"
        case profile = "profiles"
    }
}
