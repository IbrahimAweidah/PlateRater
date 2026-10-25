import Foundation
import Observation

/// Ratings are stored on the server; this keeps the last loaded summary for each plate.
@Observable
@MainActor
final class RatingStore {
    private(set) var summaries: [String: PlateSummary] = [:]
    private let api: APIClient

    init(auth: AuthManager) {
        api = APIClient(auth: auth)
    }

    func summary(for plate: String) -> PlateSummary? {
        summaries[PlateNumber.normalize(plate)]
    }

    func load(_ plate: String) async throws {
        let key = PlateNumber.normalize(plate)
        summaries[key] = try await api.plate(key)
    }

    func saveRating(score: Int, comment: String, for plate: String) async throws {
        let key = PlateNumber.normalize(plate)
        _ = try await api.saveRating(score: score, comment: comment, for: key)
        try await load(key)
    }
}
