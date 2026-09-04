import Foundation

// Client-side merge of two different Postgres rows (a new follower, a
// like on one of your logs) into one chronological feed — see
// ActivityService for why this can't be a single query.
struct ActivityItem: Identifiable {
    enum Kind {
        case newFollower
        case like(gameName: String)
    }

    let id: String
    let profile: Profile
    let kind: Kind
    let createdAt: Date
}
