import SwiftUI

/// The color hunt: find a car of every color. Rare colors are worth more points.
struct ColorHuntView: View {
    var store: RatingStore

    private var counts: [CarColor: Int] {
        store.mine.reduce(into: [:]) { counts, rating in
            if let color = CarColor(key: rating.color) { counts[color, default: 0] += 1 }
        }
    }

    var body: some View {
        let counts = self.counts
        let found = CarColor.allCases.filter { counts[$0] != nil }
        let points = found.reduce(0) { $0 + $1.points }
        let maxPoints = CarColor.allCases.reduce(0) { $0 + $1.points }
        let missing = CarColor.allCases.filter { counts[$0] == nil }

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("\(found.count) av \(CarColor.allCases.count) färger")
                        .font(Galen.title(30))
                    ProgressView(value: Double(found.count), total: Double(CarColor.allCases.count))
                        .tint(Galen.pink)
                        .padding(.horizontal, 40)
                    Text("⭐️ \(points) av \(maxPoints) poäng")
                        .font(.headline)

                    if missing.isEmpty {
                        Text("🏆 Du har hittat alla färger! Helt galet!")
                            .font(Galen.title(20))
                            .multilineTextAlignment(.center)
                    } else if let next = missing.max(by: { $0.points < $1.points }) {
                        Text("Kan du hitta en \(next.name.lowercased()) bil? Den ger \(next.points) poäng!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(CarColor.allCases) { color in
                            ColorCard(color: color, count: counts[color] ?? 0)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Färgjakt")
            .refreshable { try? await store.loadMine() }
        }
    }
}

private struct ColorCard: View {
    let color: CarColor
    let count: Int

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if count > 0 {
                    ColorDot(color: color, size: 56)
                    Text("🚗").font(.title2)
                } else {
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(.secondary)
                        .frame(width: 56, height: 56)
                    Text("?").font(Galen.title(24)).foregroundStyle(.secondary)
                }
            }
            Text(color.name)
                .font(.subheadline.bold())
            Text(count > 0 ? "×\(count)" : "\(color.points) p")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
