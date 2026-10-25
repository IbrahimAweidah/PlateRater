import SwiftUI

struct SignInView: View {
    var auth: AuthManager

    @State private var errorMessage: String?
    @State private var isSigningIn = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "car.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Plate Rater")
                .font(.largeTitle.bold())

            Text("Sign in to see and leave driver ratings.")
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
                        errorMessage = "Sign-in failed. Please try again."
                    }
                }
            } label: {
                Label("Sign in with Google", systemImage: "person.crop.circle")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
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
