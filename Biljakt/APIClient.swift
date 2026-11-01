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

/// Talks to BiljaktAPI. The base URL comes from BiljaktAPIBaseURL in Info.plist (set in Config.xcconfig).
struct APIClient {
    let auth: AuthManager

    private var baseURL: URL { Self.baseURL }

    private static var baseURL: URL {
        let value = Bundle.main.object(forInfoDictionaryKey: "BiljaktAPIBaseURL") as? String ?? ""
        return URL(string: value)!
    }

    struct AppleReply: Decodable {
        let token: String
        let email: String?
        let name: String?
    }

    /// Swaps Apple's identity token for a Biljakt token. Called before you are signed in, so no bearer token.
    static func signInWithApple(identityToken: String, name: String?) async throws -> AppleReply {
        var request = URLRequest(url: baseURL.appending(path: "api/auth/apple"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["identityToken": identityToken, "name": name.map { $0 as Any } ?? NSNull()]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.server("Inloggningen med Apple misslyckades. Försök igen.")
        }
        return try JSONDecoder().decode(AppleReply.self, from: data)
    }

    func plate(_ plate: String) async throws -> PlateSummary {
        try await decode(send("GET", "api/plates/\(plate)"))
    }

    func saveRating(comment: String, color: CarColor?, kind: CarKind?, brand: CarBrand?, needsCheck: Bool?, for plate: String) async throws -> Rating {
        let body: [String: Any] = [
            "needsCheck": needsCheck.map { $0 as Any } ?? NSNull(),
            "comment": comment,
            "color": color.map { $0.rawValue as Any } ?? NSNull(),
            "kind": kind.map { $0.rawValue as Any } ?? NSNull(),
            "brand": brand.map { $0.rawValue as Any } ?? NSNull(),
        ]
        return try await decode(send("PUT", "api/plates/\(plate)/rating", json: body))
    }

    func myRatings() async throws -> MyRatings {
        try await decode(send("GET", "api/me/ratings"))
    }

    /// A copy of your photo with the plate pixelated, for the friend who checks the find.
    func uploadCheckPhoto(_ jpeg: Data, for plate: String) async throws {
        _ = try await send("PUT", "api/plates/\(plate)/rating/checkphoto", body: jpeg, contentType: "image/jpeg")
    }

    func checkPhoto(_ id: Int) async throws -> Data? {
        do {
            return try await send("GET", "api/friends/checks/\(id)/photo")
        } catch APIError.notFound {
            return nil
        }
    }

    func answerCheck(_ id: Int, ok: Bool) async throws {
        _ = try await send("POST", "api/friends/checks/\(id)", json: ["ok": ok])
    }

    func friends() async throws -> Friends {
        try await decode(send("GET", "api/friends"))
    }

    func addFriend(email: String) async throws {
        _ = try await send("POST", "api/friends", json: ["email": email])
    }

    func acceptFriend(_ id: Int) async throws {
        _ = try await send("POST", "api/friends/\(id)/accept")
    }

    /// Declines a request, takes back your own request, or removes a friend.
    func removeFriend(_ id: Int) async throws {
        _ = try await send("DELETE", "api/friends/\(id)")
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
