import Foundation

enum APIError: LocalizedError {
    case signedOut
    case notFound
    case server(String)

    var errorDescription: String? {
        switch self {
        case .signedOut: "Du är utloggad."
        case .notFound: "Hittades inte."
        case .server(let message): message
        }
    }
}

/// Talks to PlateRaterAPI. The base URL comes from PlateRaterAPIBaseURL in Info.plist (set in Config.xcconfig).
struct APIClient {
    let auth: AuthManager

    private var baseURL: URL {
        let value = Bundle.main.object(forInfoDictionaryKey: "PlateRaterAPIBaseURL") as? String ?? ""
        return URL(string: value)!
    }

    func plate(_ plate: String) async throws -> PlateSummary {
        try await decode(send("GET", "api/plates/\(plate)"))
    }

    func saveRating(score: Int, comment: String, color: CarColor?, for plate: String) async throws -> Rating {
        let body: [String: Any] = ["score": score, "comment": comment, "color": color.map { $0.rawValue as Any } ?? NSNull()]
        return try await decode(send("PUT", "api/plates/\(plate)/rating", json: body))
    }

    func myRatings() async throws -> MyRatings {
        try await decode(send("GET", "api/me/ratings"))
    }

    /// The photo on your own rating of this plate, or nil if there is none.
    func photo(for plate: String) async throws -> Data? {
        do {
            return try await send("GET", "api/plates/\(plate)/rating/photo")
        } catch APIError.notFound {
            return nil
        }
    }

    func uploadPhoto(_ jpeg: Data, for plate: String) async throws {
        _ = try await send("PUT", "api/plates/\(plate)/rating/photo", body: jpeg, contentType: "image/jpeg")
    }

    func deletePhoto(for plate: String) async throws {
        _ = try await send("DELETE", "api/plates/\(plate)/rating/photo")
    }

    private func send(_ method: String, _ path: String, json: [String: Any]) async throws -> Data {
        try await send(method, path, body: JSONSerialization.data(withJSONObject: json), contentType: "application/json")
    }

    private func send(_ method: String, _ path: String, body: Data? = nil, contentType: String? = nil) async throws -> Data {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("Bearer \(try await auth.idToken())", forHTTPHeaderField: "Authorization")
        if let body, let contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            if status == 401 { throw APIError.server("Inloggningen har gått ut. Logga in igen.") }
            if status == 404 { throw APIError.notFound }
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw APIError.server(message ?? "Servern svarade med ett fel (\(status)).")
        }
        return data
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        try Self.decoder.decode(T.self, from: data)
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        decoder.dateDecodingStrategy = .custom { decoder in
            let text = try decoder.singleValueContainer().decode(String.self)
            if let date = withFraction.date(from: text) ?? plain.date(from: text) { return date }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Bad date: \(text)"))
        }
        return decoder
    }()
}
