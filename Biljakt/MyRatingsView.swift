import SwiftUI

/// Every car you have found, how many, and your spotter title.
struct MyRatingsView: View {
    var store: RatingStore

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 6) {
                        Text("\(store.mine.count)")
                            .font(AppStyle.title(56))
                            .foregroundStyle(AppStyle.pink)
                        Text(store.mine.count == 1 ? "bil hittad" : "bilar hittade")
                            .font(.headline)
                        Text(SpotterRank.title(for: store.mine.count))
                            .font(AppStyle.title(20))
                        if let left = SpotterRank.toNext(from: store.mine.count) {
                            Text("\(left) till nästa nivå!")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Section("Mina bilar") {
                    if store.mine.isEmpty {
                        Text("Du har inte hittat någon bil än. Gå till Spana och börja jaga! 🏁")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(store.mine) { rating in
                        NavigationLink(value: rating.plate) {
                            MyRatingRow(rating: rating, store: store)
                        }
                    }
                }
            }
            .navigationTitle("Mina bilar")
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
        let kind = CarKind(key: rating.kind)
        HStack(spacing: 12) {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text(kind?.emoji ?? "🚗")
                    .font(.system(size: 32))
                    .frame(width: 48, height: 48)
            }
            VStack(alignment: .leading, spacing: 4) {
                PlateBadge(plate: rating.plate, size: 14)
                Text([CarBrand(key: rating.brand)?.name, kind?.name].compactMap { $0 }.joined(separator: " · "))
                    .font(.subheadline.bold())
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    if let status = rating.checkStatus {
                        Text(status.mark).font(.caption)
                    }
                    if let color = CarColor(key: rating.color) {
                        ColorDot(color: color, size: 18)
                    }
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
