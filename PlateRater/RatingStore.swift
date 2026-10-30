import Foundation
import Observation
import UIKit

/// Ratings are stored on the server; this keeps the last loaded summary for each plate,
/// the user's own ratings, and the photos the user has taken.
@Observable
@MainActor
final class RatingStore {
    private(set) var summaries: [String: PlateSummary] = [:]
    private(set) var mine: [MyRating] = []
    private(set) var photos: [String: UIImage] = [:]
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

    func loadMine() async throws {
        mine = try await api.myRatings().ratings
    }

    func saveRating(score: Int, comment: String, color: CarColor?, photo: UIImage?, for plate: String) async throws {
        let key = PlateNumber.normalize(plate)
        _ = try await api.saveRating(score: score, comment: comment, color: color, for: key)
        if let photo, let jpeg = Self.jpeg(photo) {
            try await api.uploadPhoto(jpeg, for: key)
            photos[key] = photo
        }
        try await load(key)
        try? await loadMine()
    }

    /// The photo on your own rating, fetched once and then kept in memory.
    func photo(for plate: String) async -> UIImage? {
        let key = PlateNumber.normalize(plate)
        if let cached = photos[key] { return cached }
        guard let data = try? await api.photo(for: key), let image = UIImage(data: data) else { return nil }
        photos[key] = image
        return image
    }

    func deletePhoto(for plate: String) async throws {
        let key = PlateNumber.normalize(plate)
        try await api.deletePhoto(for: key)
        photos[key] = nil
        try await load(key)
        try? await loadMine()
    }

    /// Scales the photo down so it stays well under the API's 3 MB limit.
    private static func jpeg(_ image: UIImage) -> Data? {
        let maxSide: CGFloat = 1600
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.7)
    }
}
