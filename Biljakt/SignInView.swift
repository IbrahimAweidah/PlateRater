import AuthenticationServices
import SwiftUI

struct SignInView: View {
    var auth: AuthManager

    @State private var errorMessage: String?
    @State private var isSigningIn = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🚗🔎")
                .font(.system(size: 72))

            Text("Biljakt")
                .font(AppStyle.title(56))
                .foregroundStyle(AppStyle.pink)

            Text("Jaga bilar i alla färger, sorter och märken och samla poäng!")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task {
                    isSigningIn = true
                    defer { isSigningIn = false }
                    do {
                        try await auth.signInWithApple(result.get())
                        errorMessage = nil
                    } catch let error as ASAuthorizationError where error.code == .canceled {
                        // The user closed the Apple sheet.
                    } catch {
                        errorMessage = "Inloggningen med Apple misslyckades. Försök igen."
                    }
                }
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 50)
            .disabled(isSigningIn)
            .padding(.horizontal, 40)

            Button {
                Task {
                    isSigningIn = true
                    defer { isSigningIn = false }
                    do {
                        try await auth.signIn()
                        errorMessage = nil
                    } catch {
                        errorMessage = "Inloggningen misslyckades. Försök igen."
                    }
                }
            } label: {
                Label("Logga in med Google", systemImage: "person.crop.circle")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppStyle.pink)
            .controlSize(.large)
            .frame(height: 50)
            .disabled(isSigningIn)
            .padding(.horizontal, 40)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Text("En produkt av Ibrax AB")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 40)
    }
}

#Preview {
    SignInView(auth: AuthManager())
}
