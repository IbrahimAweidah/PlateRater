import SwiftUI

/// The hunt: find a car of every color, every kind and every brand. Rare ones are worth more points.
/// Tap something you have found to see the cars.
struct ColorHuntView: View {
    var store: RatingStore

    enum Hunt: String, CaseIterable, Identifiable {
        case colors = "Färger"
        case kinds = "Biltyper"
        case brands = "Märken"
        var id: String { rawValue }
    }

    @State private var hunt = Hunt.colors

    /// Finds waiting for a friend's check, or rejected by one, don't count yet.
    private var counted: [MyRating] { store.mine.filter(\.counts) }

    private var colorCounts: [CarColor: Int] {
        counted.reduce(into: [:]) { counts, rating in
            if let color = CarColor(key: rating.color) { counts[color, default: 0] += 1 }
        }
    }

    private var kindCounts: [CarKind: Int] {
        counted.reduce(into: [:]) { counts, rating in
            if let kind = CarKind(key: rating.kind) { counts[kind, default: 0] += 1 }
        }
    }

    private var brandCounts: [CarBrand: Int] {
        counted.reduce(into: [:]) { counts, rating in
            if let brand = CarBrand(key: rating.brand) { counts[brand, default: 0] += 1 }
        }
    }

    var body: some View {
        let colorCounts = self.colorCounts
        let kindCounts = self.kindCounts
        let brandCounts = self.brandCounts
        let points = HuntScore.points(colors: colorCounts.keys, kinds: kindCounts.keys, brands: brandCounts.keys)
        let waiting = store.mine.filter { $0.checkStatus == .pending }.count

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("⭐️ \(points) av \(HuntScore.maxPoints) poäng")
                        .font(AppStyle.title(26))
                    if waiting > 0 {
                        Text("❗ \(waiting) \(waiting == 1 ? "bil väntar" : "bilar väntar") på att en kompis kontrollerar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Picker("Jakt", selection: $hunt) {
                        ForEach(Hunt.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    switch hunt {
                    case .colors:
                        HuntProgress(
                            found: colorCounts.count, total: CarColor.allCases.count, unit: "färger",
                            allDone: "🏆 Du har hittat alla färger!",
                            next: CarColor.allCases.filter { colorCounts[$0] == nil }.max { $0.points < $1.points }
                                .map { "Kan du hitta en \($0.name.lowercased()) bil? Den ger \($0.points) poäng!" })
                        grid {
                            ForEach(CarColor.allCases) { color in
                                card(.color(color), name: color.name, points: color.points, count: colorCounts[color] ?? 0) {
                                    ZStack {
                                        ColorDot(color: color, size: 56)
                                        Text("🚗").font(.title2)
                                    }
                                }
                            }
                        }
                    case .kinds:
                        HuntProgress(
                            found: kindCounts.count, total: CarKind.allCases.count, unit: "biltyper",
                            allDone: "🏆 Du har hittat alla sorters bilar!",
                            next: CarKind.allCases.filter { kindCounts[$0] == nil }.max { $0.points < $1.points }
                                .map { "Kan du hitta en \($0.name.lowercased())? Den ger \($0.points) poäng!" })
                        grid {
                            ForEach(CarKind.allCases) { kind in
                                card(.kind(kind), name: kind.name, points: kind.points, count: kindCounts[kind] ?? 0) {
                                    Text(kind.emoji)
                                        .font(.system(size: 36))
                                        .frame(width: 56, height: 56)
                                        .background(AppStyle.yellow.opacity(0.4), in: Circle())
                                }
                            }
                        }
                    case .brands:
                        HuntProgress(
                            found: brandCounts.count, total: CarBrand.allCases.count, unit: "märken",
                            allDone: "🏆 Du har hittat alla märken!",
                            next: CarBrand.allCases.filter { brandCounts[$0] == nil }.max { $0.points < $1.points }
                                .map { "Kan du hitta en \($0.name)? Den ger \($0.points) poäng!" })
                        grid {
                            ForEach(CarBrand.byName) { brand in
                                card(.brand(brand), name: brand.name, points: brand.points, count: brandCounts[brand] ?? 0) {
                                    BrandBadge(brand: brand, size: 56)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Jakt")
            .navigationDestination(for: HuntFilter.self) { filter in
                FoundCarsView(filter: filter, store: store)
            }
            .navigationDestination(for: String.self) { plate in
                PlateDetailView(plate: plate, store: store)
            }
            .refreshable { try? await store.loadMine() }
        }
    }

    /// A card that opens the list of cars when you have found at least one.
    @ViewBuilder
    private func card<Icon: View>(_ filter: HuntFilter, name: String, points: Int, count: Int,
                                  @ViewBuilder icon: @escaping () -> Icon) -> some View {
        let all = store.mine.filter { filter.matches($0) }.count
        let content = HuntCard(name: name, points: points, count: count, icon: icon)
        if all > 0 {
            NavigationLink(value: filter) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }

    private func grid<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12, content: content)
    }
}

/// One color, kind or brand in the hunt.
enum HuntFilter: Hashable {
    case color(CarColor)
    case kind(CarKind)
    case brand(CarBrand)

    var title: String {
        switch self {
        case .color(let color): "\(color.name) bilar"
        case .kind(let kind): kind.name
        case .brand(let brand): brand.name
        }
    }

    func matches(_ rating: MyRating) -> Bool {
        switch self {
        case .color(let color): CarColor(key: rating.color) == color
        case .kind(let kind): CarKind(key: rating.kind) == kind
        case .brand(let brand): CarBrand(key: rating.brand) == brand
        }
    }
}

/// The cars you have found of one color, kind or brand.
struct FoundCarsView: View {
    let filter: HuntFilter
    var store: RatingStore

    var body: some View {
        let cars = store.mine.filter { filter.matches($0) }
        List(cars) { rating in
            NavigationLink(value: rating.plate) {
                MyRatingRow(rating: rating, store: store)
            }
        }
        .navigationTitle(filter.title)
        .overlay {
            if cars.isEmpty {
                ContentUnavailableView("Inga bilar här än", systemImage: "car")
            }
        }
    }
}

private struct HuntProgress: View {
    let found: Int
    let total: Int
    let unit: String
    let allDone: String
    let next: String?

    var body: some View {
        VStack(spacing: 8) {
            Text("\(found) av \(total) \(unit)")
                .font(.headline)
            ProgressView(value: Double(found), total: Double(total))
                .tint(AppStyle.pink)
                .padding(.horizontal, 40)
            if found == total {
                Text(allDone)
                    .font(AppStyle.title(20))
                    .multilineTextAlignment(.center)
            } else if let next {
                Text(next)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private struct HuntCard<Icon: View>: View {
    let name: String
    let points: Int
    let count: Int
    let icon: () -> Icon

    var body: some View {
        VStack(spacing: 6) {
            icon()
                .grayscale(count > 0 ? 0 : 1)
                .opacity(count > 0 ? 1 : 0.3)
                .overlay(alignment: .topTrailing) {
                    if count > 0 {
                        Text("✓")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(.green, in: Circle())
                            .offset(x: 4, y: -4)
                    }
                }
            Text(name)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(count > 0 ? "×\(count)" : "\(points) p")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}
