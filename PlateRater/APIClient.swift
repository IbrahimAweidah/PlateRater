import Foundation

enum APIError: LocalizedError {
    case signedOut
    case server(String)

    var errorDescription: String? {
        switch self {
        case .signedOut: "You are signed out."
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
        try await send("GET", "api/plates/\(plate)")
    }

    func saveRating(score: Int, comment: String, for plate: String) async throws -> Rating {
        try await send("PUT", "api/plates/\(plate)/rating", body: ["score": score, "comment": comment] as [String: Any])
    }

    private func send<T: Decodable>(_ method: String, _ path: String, body: [String: Any]? = nil) async throws -> T {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("Bearer \(try await auth.idToken())", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            if status == 401 { throw APIError.server("Your sign-in expired. Please sign in again.") }
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw APIError.server(message ?? "The server returned an error (\(status)).")
        }
        return try Self.decoder.decode(T.self, from: data)
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
