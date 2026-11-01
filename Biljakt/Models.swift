import Foundation

struct Rating: Identifiable, Decodable, Equatable {
    let id: Int
    let score: Int?
    let comment: String
    let color: String?
    let kind: String?
    let brand: String?
    let hasPhoto: Bool
    let updatedAt: Date
    let checkStatus: CheckStatus?
}

/// When the photo doesn't match what you picked, a friend has to check the find before it gives points.
enum CheckStatus: String, Decodable {
    case pending, confirmed, rejected

    var label: String {
        switch self {
        case .pending: "❗ Väntar på att en kompis kontrollerar"
        case .confirmed: "✅ Kontrollerad av en kompis"
        case .rejected: "❌ En kompis tyckte inte att det stämde"
        }
    }

    var mark: String {
        switch self {
        case .pending: "❗"
        case .confirmed: "✅"
        case .rejected: "❌"
        }
    }
}

/// What the API returns for a plate. Ratings are private, so this only ever holds your own rating.
struct PlateSummary: Decodable {
    let plate: String
    let myRating: Rating?
}

/// One of the signed-in user's own ratings, as listed on "Mina bilar".
struct MyRating: Identifiable, Decodable, Equatable {
    let plate: String
    let score: Int?
    let comment: String
    let color: String?
    let kind: String?
    let brand: String?
    let hasPhoto: Bool
    let updatedAt: Date
    let checkStatus: CheckStatus?

    var id: String { plate }
    /// Whether this find gives points now (not waiting for, or rejected by, a friend's check).
    var counts: Bool { checkStatus == nil || checkStatus == .confirmed }
}

struct MyRatings: Decodable {
    let count: Int
    let ratings: [MyRating]
}

/// You or a friend on the leaderboard. Friends only ever see which colors, kinds and brands of car you found.
struct Player: Identifiable, Decodable, Equatable {
    let friendshipId: Int?
    let name: String
    let isMe: Bool
    let cars: Int
    let colors: [String]
    let kinds: [String]
    let brands: [String]

    var id: String { isMe ? "me" : "friend-\(friendshipId ?? 0)" }
    var foundColors: [CarColor] { colors.compactMap { CarColor(key: $0) } }
    var foundKinds: [CarKind] { kinds.compactMap { CarKind(key: $0) } }
    var foundBrands: [CarBrand] { brands.compactMap { CarBrand(key: $0) } }
    var points: Int { HuntScore.points(colors: foundColors, kinds: foundKinds, brands: foundBrands) }
}

struct FriendRequest: Identifiable, Decodable, Equatable {
    let id: Int
    let name: String
    let email: String?
}

/// A friend's find that you are asked to check. Never includes the plate; the photo has the plate pixelated.
struct FriendCheck: Identifiable, Decodable, Equatable {
    let id: Int
    let friendName: String
    let color: String?
    let kind: String?
    let brand: String?
    let hasPhoto: Bool
}

struct Friends: Decodable {
    let players: [Player]
    let incoming: [FriendRequest]
    let outgoing: [FriendRequest]
    let checks: [FriendCheck]
}

enum PlateNumber {
    static func normalize(_ raw: String) -> String {
        raw.uppercased().filter { !$0.isWhitespace }
    }

    /// Swedish plates: 3 letters + 3 digits (old format), or 3 letters + 2 digits + 1 letter (format since 2019).
    static func isValid(_ raw: String) -> Bool {
        let plate = normalize(raw)
        let pattern = "^[A-ZÅÄÖ]{3}[0-9]{2}[0-9A-ZÅÄÖ]$"
        return plate.range(of: pattern, options: .regularExpression) != nil
    }
}
