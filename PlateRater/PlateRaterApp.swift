import GoogleSignIn
import SwiftUI

@main
struct PlateRaterApp: App {
    @State private var auth = AuthManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isRestoring {
                    ProgressView()
                } else if auth.isSignedIn {
                    ContentView(auth: auth)
                } else {
                    SignInView(auth: auth)
                }
            }
            .task { await auth.restore() }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
