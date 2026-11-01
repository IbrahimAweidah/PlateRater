import AuthenticationServices
import GoogleSignIn
import Observation
import Security
import UIKit

/// Sign-in with Google or Apple.
/// Google: the client ID comes from GIDClientID in Info.plist (set in Config.xcconfig), and the Google ID token is
/// sent to the API. Apple: Apple's identity token is swapped once for a Biljakt token (POST /api/auth/apple),
/// which is kept in the Keychain and lasts 180 days.
@Observable
@MainActor
final class AuthManager {
    private(set) var user: GIDGoogleUser?
    private(set) var apple: AppleSession?
    private(set) var isRestoring = true

    var isSignedIn: Bool { user != nil || apple != nil }
    var email: String? { user?.profile?.email ?? apple?.email }

    func restore() async {
        if let saved = AppleSession.load() {
            let state = try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: saved.appleUserID)
            if state == .authorized, saved.expires > .now {
                apple = saved
            } else {
                AppleSession.clear()
            }
        }
        if apple == nil {
            user = try? await GIDSignIn.sharedInstance.restorePreviousSignIn()
        }
        isRestoring = false
    }

    func signIn() async throws {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
            .first
        else { return }
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
        user = result.user
    }

    /// Finishes "Logga in med Apple": sends Apple's token to the API and keeps the Biljakt token it returns.
    func signInWithApple(_ authorization: ASAuthorization) async throws {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8)
        else { throw APIError.signedOut }
        // Apple only gives the name the first time; the API remembers it.
        let name = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }.joined(separator: " ")
        let reply = try await APIClient.signInWithApple(identityToken: identityToken, name: name.isEmpty ? nil : name)
        let session = AppleSession(appleUserID: credential.user, token: reply.token, email: reply.email,
                                   expires: .now.addingTimeInterval(170 * 24 * 3600))
        session.save()
        GIDSignIn.sharedInstance.signOut()
        user = nil
        apple = session
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        user = nil
        AppleSession.clear()
        apple = nil
    }

    /// A current token for the API: the Google ID token (Google refreshes it when needed) or the Biljakt token.
    func idToken() async throws -> String {
        if let apple {
            guard apple.expires > .now else { signOut(); throw APIError.signedOut }
            return apple.token
        }
        guard let user else { throw APIError.signedOut }
        let refreshed = try await user.refreshTokensIfNeeded()
        guard let token = refreshed.idToken?.tokenString else { throw APIError.signedOut }
        return token
    }
}

/// An Apple sign-in, saved in the Keychain so you stay signed in.
struct AppleSession: Codable {
    let appleUserID: String
    let token: String
    let email: String?
    let expires: Date

    private static let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "Biljakt",
        kSecAttrAccount as String: "apple-session",
    ]

    static func load() -> AppleSession? {
        var item: CFTypeRef?
        var search = query
        search[kSecReturnData as String] = true
        guard SecItemCopyMatching(search as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(AppleSession.self, from: data)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        Self.clear()
        var add = Self.query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(add as CFDictionary, nil)
    }

    static func clear() {
        SecItemDelete(query as CFDictionary)
    }
}
