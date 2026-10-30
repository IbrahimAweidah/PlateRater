import SwiftUI

struct SignInView: View {
    var auth: AuthManager

    @State private var errorMessage: String?
    @State private var isSigningIn = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🤪🚗")
                .font(.system(size: 72))

            Text("Galen")
                .font(Galen.title(56))
                .foregroundStyle(Galen.pink)

            Text("Spana in galna förare, jaga bilar i alla färger och samla poäng!")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

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
            .tint(Galen.pink)
            .controlSize(.large)
            .disabled(isSigningIn)
            .padding(.horizontal, 40)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.bottom, 40)
    }
}

#Preview {
    SignInView(auth: AuthManager())
}
