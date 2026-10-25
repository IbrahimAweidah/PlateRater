import SwiftUI

struct ContentView: View {
    var auth: AuthManager

    @State private var store: RatingStore
    @State private var plateInput = ""

    init(auth: AuthManager) {
        self.auth = auth
        _store = State(initialValue: RatingStore(auth: auth))
    }

    private var isValidPlate: Bool { PlateNumber.isValid(plateInput) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter a Swedish license plate to see or leave a driver rating.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                TextField("ABC123", text: $plateInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(.title2, design: .monospaced, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 40)

                if !plateInput.isEmpty && !isValidPlate {
                    Text("That doesn't look like a valid Swedish plate.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                NavigationLink(value: PlateNumber.normalize(plateInput)) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)
                .disabled(!isValidPlate)

                Spacer()
            }
            .padding(.top, 60)
            .navigationTitle("Plate Rater")
            .navigationDestination(for: String.self) { plate in
                PlateDetailView(plate: plate, store: store)
            }
            .toolbar {
                Menu {
                    if let email = auth.email {
                        Text(email)
                    }
                    Button("Sign out", role: .destructive) { auth.signOut() }
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
