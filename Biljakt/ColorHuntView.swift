import SwiftUI

/// The hunt: find a car of every color, every kind and every brand. Rare ones are worth more points.
struct ColorHuntView: View {
    var store: RatingStore

    enum Hunt: String, CaseIterable, Identifiable {
        case colors = "Färger"
        case kinds = "Biltyper"
        case brands = "Märken"
        var id: String { rawValue }
    }

    @State private var hunt = Hunt.colors

    private var colorCounts: [CarColor: Int] {
        store.mine.reduce(into: [:]) { counts, rating in
            if let color = CarColor(key: rating.color) { counts[color, default: 0] += 1 }
        }
    }

    private var kindCounts: [CarKind: Int] {
        store.mine.reduce(into: [:]) { counts, rating in
            if let kind = CarKind(key: rating.kind) { counts[kind, default: 0] += 1 }
        }
    }

    private var brandCounts: [CarBrand: Int] {
        store.mine.reduce(into: [:]) { counts, rating in
            if let brand = CarBrand(key: rating.brand) { counts[brand, default: 0] += 1 }
        }
    }

    var body: some View {
        let colorCounts = self.colorCounts
        let kindCounts = self.kindCounts
        let brandCounts = self.brandCounts
        let points = HuntScore.points(colors: colorCounts.keys, kinds: kindCounts.keys, brands: brandCounts.keys)

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("⭐️ \(points) av \(HuntScore.maxPoints) poäng")
                        .font(AppStyle.title(26))

                    Picker("Jakt", selection: $hunt) {
                        ForEach(Hunt.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    switch hunt {
                    case .colors:
                        HuntProgress(
                            found: colorCounts.count, total: CarColor.allCases.count, unit: "färger",
                            allDone: "🏆 Du har hittat alla färger! Helt galet!",
                            next: CarColor.allCases.filter { colorCounts[$0] == nil }.max { $0.points < $1.points }
                                .map { "Kan du hitta en \($0.name.lowercased()) bil? Den ger \($0.points) poäng!" })
                        grid {
                            ForEach(CarColor.allCases) { color in
                                HuntCard(name: color.name, points: color.points, count: colorCounts[color] ?? 0) {
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
                            allDone: "🏆 Du har hittat alla sorters bilar! Helt galet!",
                            next: CarKind.allCases.filter { kindCounts[$0] == nil }.max { $0.points < $1.points }
                                .map { "Kan du hitta en \($0.name.lowercased())? Den ger \($0.points) poäng!" })
                        grid {
                            ForEach(CarKind.allCases) { kind in
                                HuntCard(name: kind.name, points: kind.points, count: kindCounts[kind] ?? 0) {
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
                            allDone: "🏆 Du har hittat alla märken! Helt galet!",
                            next: CarBrand.allCases.filter { brandCounts[$0] == nil }.max { $0.points < $1.points }
                                .map { "Kan du hitta en \($0.name)? Den ger \($0.points) poäng!" })
                        grid {
                            ForEach(CarBrand.allCases) { brand in
                                HuntCard(name: brand.name, points: brand.points, count: brandCounts[brand] ?? 0) {
                                    Text(String(brand.name.prefix(2)))
                                        .font(AppStyle.title(22))
                                        .foregroundStyle(.white)
                                        .frame(width: 56, height: 56)
                                        .background(AppStyle.blue, in: Circle())
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Jakt")
            .refreshable { try? await store.loadMine() }
        }
    }

    private func grid<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12, content: content)
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
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if count > 0 {
                    icon()
                } else {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.secondary)
                        .frame(width: 56, height: 56)
                    Text("?").font(AppStyle.title(24)).foregroundStyle(.secondary)
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
    }
}
