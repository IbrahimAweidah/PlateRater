import SwiftUI

struct ContentView: View {
    var auth: AuthManager

    @State private var store: RatingStore

    init(auth: AuthManager) {
        self.auth = auth
        _store = State(initialValue: RatingStore(auth: auth))
    }

    var body: some View {
        TabView {
            SpotView(auth: auth, store: store)
                .tabItem { Label("Spana", systemImage: "binoculars.fill") }
            MyRatingsView(store: store)
                .tabItem { Label("Mina betyg", systemImage: "star.fill") }
            ColorHuntView(store: store)
                .tabItem { Label("Färgjakt", systemImage: "paintpalette.fill") }
        }
        .tint(Galen.pink)
        .task { try? await store.loadMine() }
    }
}

/// Type a plate and go rate it.
struct SpotView: View {
    var auth: AuthManager
    var store: RatingStore

    @State private var plateInput = ""

    private var isValidPlate: Bool { PlateNumber.isValid(plateInput) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("🚗💨")
                    .font(.system(size: 56))
                Text("Såg du en galen förare? Skriv in registreringsnumret!")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 0) {
                    Text("S")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 64)
                        .background(Galen.blue)
                    TextField("ABC123", text: $plateInput)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(size: 34, weight: .bold, design: .monospaced))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .frame(height: 64)
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.black, lineWidth: 3))
                .padding(.horizontal, 40)

                if !plateInput.isEmpty && !isValidPlate {
                    Text("Hmm, det ser inte ut som en svensk skylt. 🤔")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                NavigationLink(value: PlateNumber.normalize(plateInput)) {
                    Text("Kör! 🏁")
                        .font(Galen.title(20))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 40)
                .disabled(!isValidPlate)

                Text("\(SpotterRank.title(for: store.mine.count)) · \(store.mine.count) bilar spanade")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("Galen")
            .navigationDestination(for: String.self) { plate in
                PlateDetailView(plate: plate, store: store)
            }
            .toolbar {
                Menu {
                    if let email = auth.email {
                        Text(email)
                    }
                    Button("Logga ut", role: .destructive) { auth.signOut() }
                } label: {
                    Image(systemName: "person.crop.circle")
                }
            }
        }
    }
}

#Preview {
    ContentView(auth: AuthManager())
}
