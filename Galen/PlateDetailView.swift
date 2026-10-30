import PhotosUI
import SwiftUI

struct PlateDetailView: View {
    let plate: String
    var store: RatingStore

    @State private var level = GalenLevel.cheeky
    @State private var carColor: CarColor?
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
            othersSection
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
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { newPhoto = $0 }
                .ignoresSafeArea()
        }
        .overlay {
            if let celebration {
                Text(celebration)
                    .font(Galen.title(34))
                    .multilineTextAlignment(.center)
                    .padding(30)
                    .background(Galen.yellow, in: RoundedRectangle(cornerRadius: 24))
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
                if let average = summary?.average, let count = summary?.count {
                    let verdict = GalenLevel(average: average)
                    Text("\(verdict.emoji) \(verdict.name)")
                        .font(Galen.title(26))
                    Text("Galen-mätare: \(average, specifier: "%.1f") av 5 · \(count) betyg")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if summary == nil && errorMessage == nil {
                    ProgressView()
                } else if summary != nil {
                    Text("Ingen har spanat in den här bilen än. Bli först! 🕵️")
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
        Section(summary?.myRating == nil ? "Hur galen var föraren?" : "Ditt betyg") {
            VStack(spacing: 8) {
                HStack {
                    ForEach(GalenLevel.allCases) { option in
                        Button {
                            level = option
                        } label: {
                            VStack(spacing: 2) {
                                Text(option.emoji)
                                    .font(.system(size: option == level ? 40 : 28))
                                Text(String(repeating: "★", count: option.rawValue))
                                    .font(.system(size: 8))
                                    .foregroundStyle(Galen.yellow)
                            }
                            .frame(maxWidth: .infinity)
                            .opacity(option == level ? 1 : 0.5)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .animation(.spring(duration: 0.3), value: level)
                Text(level.name)
                    .font(Galen.title(22))
                    .foregroundStyle(level == .galen ? Galen.pink : .primary)
                Text(level.blurb)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

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

            TextField("Vad hände? (valfritt)", text: $comment, axis: .vertical)

            Button {
                Task { await save() }
            } label: {
                Text(summary?.myRating == nil ? "Spara betyg!" : "Uppdatera betyg")
                    .font(Galen.title(18))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Galen.pink)
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
                    Text("Bilden sparas när du sparar betyget.")
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
            Text("Bara du kan se dina bilder.")
        }
    }

    private var othersSection: some View {
        Section("Alla betyg") {
            let ratings = summary?.ratings ?? []
            if ratings.isEmpty {
                Text("Inga betyg än.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(ratings) { rating in
                    let ratingLevel = GalenLevel(rawValue: rating.score) ?? .cheeky
                    HStack(alignment: .top, spacing: 12) {
                        Text(ratingLevel.emoji)
                            .font(.title)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(ratingLevel.name)
                                    .font(.subheadline.bold())
                                if rating.isMine {
                                    Text("Du")
                                        .font(.caption.bold())
                                        .foregroundStyle(Galen.pink)
                                }
                                Spacer()
                                if let color = CarColor(key: rating.color) {
                                    ColorDot(color: color, size: 14)
                                }
                                Text(rating.updatedAt, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if !rating.comment.isEmpty {
                                Text(rating.comment)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
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
                level = GalenLevel(rawValue: mine.score) ?? .cheeky
                carColor = CarColor(key: mine.color)
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
        do {
            try await store.saveRating(score: level.rawValue, comment: comment, color: carColor, photo: newPhoto, for: plate)
            errorMessage = nil
            if newPhoto != nil {
                savedPhoto = newPhoto
                newPhoto = nil
            }
            if let carColor, !colorsBefore.contains(carColor) {
                celebrate("🎨 Ny färg!\n\(carColor.name) +\(carColor.points) poäng")
            } else if level == .galen {
                celebrate("🤪 GALEN FÖRARE!")
            } else {
                celebrate("\(level.emoji) Sparat!")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
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
