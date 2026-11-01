import Foundation

struct Rating: Identifiable, Decodable, Equatable {
    let id: Int
    let score: Int
    let comment: String
    let color: String?
    let hasPhoto: Bool
    let updatedAt: Date
}

/// What the API returns for a plate. Ratings are private, so this only ever holds your own rating.
struct PlateSummary: Decodable {
    let plate: String
    let myRating: Rating?
}

/// One of the signed-in user's own ratings, as listed on "Mina betyg".
struct MyRating: Identifiable, Decodable, Equatable {
    let plate: String
    let score: Int
    let comment: String
    let color: String?
    let hasPhoto: Bool
    let updatedAt: Date

    var id: String { plate }
}

struct MyRatings: Decodable {
    let count: Int
    let ratings: [MyRating]
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
