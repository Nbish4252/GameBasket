import Foundation

struct LogParticipant: Codable {
    var logId: UUID
    var profileId: UUID
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case logId = "log_id"
        case profileId = "profile_id"
        case createdAt = "created_at"
    }
}
