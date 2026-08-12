import Foundation
import Supabase

// NOTE: supabase-swift's API surface shifts between versions — once the
// package is resolved in Xcode, check these calls against autocomplete /
// the current docs rather than trusting this file blindly.

enum SupabaseConfig {
    static let url: URL = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let url = URL(string: raw) else {
            fatalError("Missing SUPABASE_URL — set it in GameBasket/Secrets.xcconfig (see README).")
        }
        return url
    }()

    static let anonKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            fatalError("Missing SUPABASE_ANON_KEY — set it in GameBasket/Secrets.xcconfig (see README).")
        }
        return key
    }()
}

// Postgres timestamptz comes back as ISO 8601, sometimes with fractional
// seconds — the default JSONDecoder can't parse Date from that alone.
private let postgresDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    let withFraction = ISO8601DateFormatter()
    withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let withoutFraction = ISO8601DateFormatter()
    withoutFraction.formatOptions = [.withInternetDateTime]

    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        if let date = withFraction.date(from: string) ?? withoutFraction.date(from: string) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
    }
    return decoder
}()

private let postgresEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}()

let supabaseClient = SupabaseClient(
    supabaseURL: SupabaseConfig.url,
    supabaseKey: SupabaseConfig.anonKey,
    options: SupabaseClientOptions(
        db: .init(encoder: postgresEncoder, decoder: postgresDecoder)
    )
)
