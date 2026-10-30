import GoogleSignIn
import Observation
import UIKit

/// Google sign-in. The client ID comes from GIDClientID in Info.plist (set in Config.xcconfig).
@Observable
@MainActor
final class AuthManager {
    private(set) var user: GIDGoogleUser?
    private(set) var isRestoring = true

    var isSignedIn: Bool { user != nil }
    var email: String? { user?.profile?.email }

    func restore() async {
        user = try? await GIDSignIn.sharedInstance.restorePreviousSignIn()
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

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        user = nil
    }

    /// A current Google ID token for the API. Google refreshes it when it is about to expire.
    func idToken() async throws -> String {
        guard let user else { throw APIError.signedOut }
        let refreshed = try await user.refreshTokensIfNeeded()
        guard let token = refreshed.idToken?.tokenString else { throw APIError.signedOut }
        return token
    }
}
