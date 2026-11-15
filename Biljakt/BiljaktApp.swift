import GoogleSignIn
import SwiftUI

@main
struct BiljaktApp: App {
    @State private var auth = AuthManager()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash || auth.isRestoring {
                    SplashView()
                } else if auth.isSignedIn {
                    ContentView(auth: auth)
                } else {
                    SignInView(auth: auth)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: showSplash)
            .task {
                let start = Date()
                await auth.restore()
                let left = 1.5 - Date().timeIntervalSince(start)
                if left > 0 { try? await Task.sleep(for: .seconds(left)) }
                showSplash = false
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}

/// Shown for a moment at start, so it's easy to see this is Biljakt.
struct SplashView: View {
    @State private var wobble = false

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppStyle.pink, .orange], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Image("BiljaktLogo")
                    .resizable()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                    .shadow(radius: 12)
                    .rotationEffect(.degrees(wobble ? 6 : -6))
                    .animation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true), value: wobble)
                Text("Biljakt")
                    .font(AppStyle.title(64))
                    .foregroundStyle(.white)
                Text("Spana · Fota · Jaga bilar")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                Text("En produkt av Ibrax AB")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Version \(version)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .onAppear { wobble = true }
    }
}
