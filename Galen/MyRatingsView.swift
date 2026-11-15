import SwiftUI

/// Everything you have rated, how many, and your spotter title.
struct MyRatingsView: View {
    var store: RatingStore

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 6) {
                        Text("\(store.mine.count)")
                            .font(Galen.title(56))
                            .foregroundStyle(Galen.pink)
                        Text(store.mine.count == 1 ? "bil spanad" : "bilar spanade")
                            .font(.headline)
                        Text(SpotterRank.title(for: store.mine.count))
                            .font(Galen.title(20))
                        if let left = SpotterRank.toNext(from: store.mine.count) {
                            Text("\(left) till nästa nivå!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    HStack {
                        ForEach(GalenLevel.allCases) { level in
                            VStack {
                                Text(level.emoji).font(.title2)
                                Text("\(store.mine.filter { $0.score == level.rawValue }.count)")
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Section("Mina betyg") {
                    if store.mine.isEmpty {
                        Text("Du har inte betygsatt någon än. Gå till Spana och börja jaga! 🏁")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.mine) { rating in
                        NavigationLink(value: rating.plate) {
                            MyRatingRow(rating: rating, store: store)
                        }
                    }
                }
            }
            .navigationTitle("Mina betyg")
            .navigationDestination(for: String.self) { plate in
                PlateDetailView(plate: plate, store: store)
            }
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        do {
            try await store.loadMine()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct MyRatingRow: View {
    let rating: MyRating
    var store: RatingStore

    @State private var photo: UIImage?

    var body: some View {
        let level = GalenLevel(rawValue: rating.score) ?? .cheeky
        HStack(spacing: 12) {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text(level.emoji)
                    .font(.system(size: 32))
                    .frame(width: 48, height: 48)
            }
            VStack(alignment: .leading, spacing: 4) {
                PlateBadge(plate: rating.plate, size: 14)
                Text(level.name)
                    .font(.subheadline.bold())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let color = CarColor(key: rating.color) {
                    ColorDot(color: color, size: 18)
                }
                Text(rating.updatedAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: rating.hasPhoto) {
            photo = nil
            if rating.hasPhoto {
                photo = await store.photo(for: rating.plate)
            }
        }
    }
}
