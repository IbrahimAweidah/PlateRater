import PhotosUI
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
                .tabItem { Label("Mina bilar", systemImage: "car.fill") }
            ColorHuntView(store: store)
                .tabItem { Label("Jakt", systemImage: "paintpalette.fill") }
            FriendsView(auth: auth, store: store)
                .tabItem { Label("Tävla", systemImage: "trophy.fill") }
        }
        .tint(AppStyle.pink)
        .task { try? await store.loadMine() }
    }
}

/// Photograph the whole car (the app reads the plate, color, kind and brand), or type the plate.
struct SpotView: View {
    var auth: AuthManager
    var store: RatingStore

    @State private var plateInput = ""
    @State private var path: [String] = []
    @State private var showCamera = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var isScanning = false
    @State private var scanMessage: String?
    /// A photo where no plate was found; it goes with the plate the user types next.
    @State private var pendingPhoto: UIImage?

    private var isValidPlate: Bool { PlateNumber.isValid(plateInput) }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 20) {
                Text("🚗💨")
                    .font(.system(size: 56))
                Text("Såg du en bil? Fota hela bilen, eller skriv in registreringsnumret!")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                HStack(spacing: 0) {
                    Text("S")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 64)
                        .background(AppStyle.blue)
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

                Button {
                    openFind(PlateNumber.normalize(plateInput))
                } label: {
                    Text(pendingPhoto == nil ? "Kör! 🏁" : "Kör med bilden! 🏁")
                        .font(AppStyle.title(20))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 40)
                .disabled(!isValidPlate)

                HStack {
                    if CameraPicker.isAvailable {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Fota bilen", systemImage: "camera.fill")
                        }
                    }
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("Från bild", systemImage: "photo")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isScanning)

                if isScanning {
                    ProgressView("Tittar på bilen…")
                } else if let scanMessage {
                    Text(scanMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Text("\(SpotterRank.title(for: store.mine.count)) · \(store.mine.count) bilar spanade")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("Biljakt")
            .navigationDestination(for: String.self) { plate in
                PlateDetailView(plate: plate, store: store)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in Task { await scan(image) } }
                    .ignoresSafeArea()
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                pickerItem = nil
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        await scan(image)
                    }
                }
            }
            .toolbar {
                Menu {
                    if let email = auth.email {
                        Text(email)
                    }
                    Button("Logga ut", role: .destructive) { auth.signOut() }
                    Text("Biljakt – en produkt av Ibrax AB")
                } label: {
                    Image(systemName: "person.crop.circle")
                }
            }
        }
    }

    /// Reads the plate from the photo of the car, then opens the find with the photo attached,
    /// where color, kind and brand are guessed. Without a plate, the photo waits for a typed plate.
    private func scan(_ image: UIImage) async {
        isScanning = true
        defer { isScanning = false }
        guard let plate = await PlateScanner.plate(in: image) else {
            pendingPhoto = image
            scanMessage = "Hittade ingen skylt i bilden. 🙈 Skriv in registreringsnumret så följer bilden med."
            return
        }
        plateInput = plate
        pendingPhoto = image
        openFind(plate)
    }

    private func openFind(_ plate: String) {
        if let pendingPhoto {
            store.scannedPhotos[plate] = pendingPhoto
            self.pendingPhoto = nil
        }
        scanMessage = nil
        path.append(plate)
    }
}

#Preview {
    ContentView(auth: AuthManager())
}
