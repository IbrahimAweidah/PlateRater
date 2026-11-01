import PhotosUI
import SwiftUI

struct PlateDetailView: View {
    let plate: String
    var store: RatingStore

    @State private var carColor: CarColor?
    @State private var carKind: CarKind?
    @State private var carBrand: CarBrand?
    @State private var guessText: String?
    @State private var comment = ""
    @State private var newPhoto: UIImage?
    @State private var savedPhoto: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var celebration: String?

    private var summary: PlateSummary? { store.summary(for: plate) }
    private var photo: UIImage? { newPhoto ?? savedPhoto }

    var body: some View {
        List {
            header
            ratingForm
            photoSection
        }
        .navigationTitle(plate)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
        .onChange(of: pickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    newPhoto = image
                }
                pickerItem = nil
            }
        }
        .onChange(of: newPhoto) { _, image in
            if let image { Task { await guessCar(from: image) } }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { newPhoto = $0 }
                .ignoresSafeArea()
        }
        .overlay {
            if let celebration {
                Text(celebration)
                    .font(AppStyle.title(34))
                    .multilineTextAlignment(.center)
                    .padding(30)
                    .background(AppStyle.yellow, in: RoundedRectangle(cornerRadius: 24))
                    .rotationEffect(.degrees(-4))
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
                    .onTapGesture { self.celebration = nil }
            }
        }
        .animation(.spring(duration: 0.4, bounce: 0.5), value: celebration)
    }

    private var header: some View {
        Section {
            VStack(spacing: 12) {
                PlateBadge(plate: plate, size: 30)
                if let mine = summary?.myRating {
                    Text("✅ Hittad!")
                        .font(AppStyle.title(26))
                    Text("Du hittade den här bilen \(mine.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if summary == nil && errorMessage == nil {
                    ProgressView()
                } else if summary != nil {
                    Text("Ny bil! Fyll i vad du ser. 🕵️")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var ratingForm: some View {
        Section(summary?.myRating == nil ? "Vad hittade du?" : "Ditt fynd") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Vilken färg hade bilen?")
                    .font(.subheadline.weight(.semibold))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(CarColor.allCases) { option in
                        Button {
                            carColor = carColor == option ? nil : option
                        } label: {
                            ColorDot(color: option, size: option == carColor ? 38 : 30)
                                .overlay {
                                    if option == carColor {
                                        Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundStyle(option == .white || option == .yellow || option == .silver ? Color.black : Color.white)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.name)
                    }
                }
                .animation(.spring(duration: 0.3), value: carColor)
                Text(carColor.map { "\($0.name) bil" } ?? "Tryck på en färg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Vilken sorts bil var det?")
                    .font(.subheadline.weight(.semibold))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(CarKind.allCases) { option in
                        Button {
                            carKind = carKind == option ? nil : option
                        } label: {
                            Text(option.emoji)
                                .font(.system(size: option == carKind ? 34 : 26))
                                .frame(width: 42, height: 42)
                                .background(option == carKind ? AppStyle.yellow.opacity(0.5) : Color.clear, in: Circle())
                                .opacity(carKind == nil || option == carKind ? 1 : 0.5)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option.name)
                    }
                }
                .animation(.spring(duration: 0.3), value: carKind)
                Text(carKind?.name ?? "Tryck på en sorts bil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Vilket märke?")
                    .font(.subheadline.weight(.semibold))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(CarBrand.allCases) { option in
                        Button {
                            carBrand = carBrand == option ? nil : option
                        } label: {
                            Text(option.name)
                                .font(.caption.weight(option == carBrand ? .heavy : .regular))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(option == carBrand ? AppStyle.blue : Color.secondary.opacity(0.12), in: Capsule())
                                .foregroundStyle(option == carBrand ? Color.white : Color.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .animation(.spring(duration: 0.3), value: carBrand)
                if let guessText {
                    Text(guessText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            TextField("Anteckning (valfritt)", text: $comment, axis: .vertical)

            Button {
                Task { await save() }
            } label: {
                Text(summary?.myRating == nil ? "Spara fynd!" : "Uppdatera")
                    .font(AppStyle.title(18))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppStyle.pink)
            .disabled(isSaving)
        }
    }

    private var photoSection: some View {
        Section {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                if newPhoto != nil {
                    Text("Bilden sparas när du sparar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                if CameraPicker.isAvailable {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Ta foto", systemImage: "camera.fill")
                    }
                    .buttonStyle(.bordered)
                }
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Välj bild", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.bordered)
                Spacer()
                if let photo {
                    ShareLink(item: Image(uiImage: photo), preview: SharePreview(plate, image: Image(uiImage: photo))) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
            }
            if savedPhoto != nil && newPhoto == nil {
                Button("Ta bort bilden", role: .destructive) {
                    Task { await deletePhoto() }
                }
            }
        } header: {
            Text("Din bild")
        } footer: {
            Text("Bara du kan se dina fynd, anteckningar och bilder.")
        }
    }

    private func load() async {
        if newPhoto == nil, let scanned = store.scannedPhotos.removeValue(forKey: plate) {
            newPhoto = scanned
        }
        do {
            try await store.load(plate)
            errorMessage = nil
            if let mine = summary?.myRating {
                carColor = CarColor(key: mine.color)
                carKind = CarKind(key: mine.kind) ?? carKind
                carBrand = CarBrand(key: mine.brand) ?? carBrand
                comment = mine.comment
                if mine.hasPhoto {
                    savedPhoto = await store.photo(for: plate)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let colorsBefore = Set(store.mine.compactMap { CarColor(key: $0.color) })
        let kindsBefore = Set(store.mine.compactMap { CarKind(key: $0.kind) })
        let brandsBefore = Set(store.mine.compactMap { CarBrand(key: $0.brand) })
        do {
            try await store.saveRating(comment: comment, color: carColor, kind: carKind, brand: carBrand, photo: newPhoto, for: plate)
            errorMessage = nil
            if newPhoto != nil {
                savedPhoto = newPhoto
                newPhoto = nil
            }
            if let carColor, !colorsBefore.contains(carColor) {
                celebrate("🎨 Ny färg!\n\(carColor.name) +\(carColor.points) poäng")
            } else if let carBrand, !brandsBefore.contains(carBrand) {
                celebrate("🏷️ Nytt märke!\n\(carBrand.name) +\(carBrand.points) poäng")
            } else if let carKind, !kindsBefore.contains(carKind) {
                celebrate("\(carKind.emoji) Ny sorts bil!\n\(carKind.name) +\(carKind.points) poäng")
            } else {
                celebrate("🚗 Sparat!")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Guesses the color, brand and kind from the photo, on the phone. Fills in what is still empty,
    /// and says so if the photo doesn't match what you picked.
    private func guessCar(from image: UIImage) async {
        let guess = await CarGuesser.guess(from: image)
        var guessed: [String] = []
        var notes: [String] = []
        if let color = guess.color {
            if carColor == nil {
                carColor = color
                guessed.append("\(color.name.lowercased())")
            } else if carColor != color {
                notes.append("Bilen på bilden ser \(color.name.lowercased()) ut. Stämmer färgen?")
            } else {
                notes.append("✅ Färgen stämmer med bilden!")
            }
        }
        if let brand = guess.brand {
            if carBrand == nil {
                carBrand = brand
                guessed.append(brand.name)
            } else if carBrand != brand {
                notes.append("Det står \(brand.name) på bilen. Stämmer märket?")
            }
        }
        if let kind = guess.kind {
            if carKind == nil {
                carKind = kind
                guessed.append("\(kind.emoji) \(kind.name.lowercased())")
            } else if carKind != kind && kind != .car {
                notes.append("Bilen ser ut som en \(kind.name.lowercased()). Stämmer sorten?")
            }
        }
        if !guessed.isEmpty {
            notes.insert("🤖 Biljakt gissar: \(guessed.joined(separator: ", ")). Ändra om det är fel!", at: 0)
        }
        guessText = notes.isEmpty ? "🤖 Biljakt kunde inte gissa bilen från bilden. Välj själv!" : notes.joined(separator: "\n")
    }

    private func deletePhoto() async {
        do {
            try await store.deletePhoto(for: plate)
            savedPhoto = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func celebrate(_ text: String) {
        celebration = text
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            if celebration == text { celebration = nil }
        }
    }
}

#Preview {
    NavigationStack {
        PlateDetailView(plate: "ABC123", store: RatingStore(auth: AuthManager()))
    }
}
