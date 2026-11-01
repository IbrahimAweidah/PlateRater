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
    private(set) var friends: Friends?
    /// A photo the plate was scanned from, waiting to be attached when the rating is saved.
    var scannedPhotos: [String: UIImage] = [:]
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

    /// Saves a find. `needsCheck` is true when the photo doesn't match what was picked, false when it does,
    /// and nil when there was no photo to compare (the server then keeps the earlier check state).
    /// `checkPhoto` is the photo a friend gets to see, with the plate pixelated before it leaves the phone.
    func saveRating(comment: String, color: CarColor?, kind: CarKind?, brand: CarBrand?, needsCheck: Bool?,
                    photo: UIImage?, checkPhoto: UIImage?, for plate: String) async throws {
        let key = PlateNumber.normalize(plate)
        _ = try await api.saveRating(comment: comment, color: color, kind: kind, brand: brand, needsCheck: needsCheck, for: key)
        if let photo, let jpeg = Self.jpeg(photo) {
            try await api.uploadPhoto(jpeg, for: key)
            photos[key] = photo
        }
        if needsCheck == true, let checkPhoto, let hidden = await PlateScanner.hidingPlates(in: checkPhoto),
           let jpeg = Self.jpeg(hidden) {
            try? await api.uploadCheckPhoto(jpeg, for: key)
        }
        try await load(key)
        try? await loadMine()
    }

    func loadFriends() async throws {
        friends = try await api.friends()
    }

    /// The photo of a friend's find you are asked to check (plate pixelated).
    func checkPhoto(_ id: Int) async -> UIImage? {
        guard let data = try? await api.checkPhoto(id) else { return nil }
        return UIImage(data: data)
    }

    func answerCheck(_ id: Int, ok: Bool) async throws {
        try await api.answerCheck(id, ok: ok)
        try await loadFriends()
    }

    func addFriend(email: String) async throws {
        try await api.addFriend(email: email)
        try await loadFriends()
    }

    func acceptFriend(_ id: Int) async throws {
        try await api.acceptFriend(id)
        try await loadFriends()
    }

    func removeFriend(_ id: Int) async throws {
        try await api.removeFriend(id)
        try await loadFriends()
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
