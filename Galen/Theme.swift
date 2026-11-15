import SwiftUI

/// The Galen look: bright colors, rounded fonts, and silly names for every score.
enum Galen {
    static let pink = Color(red: 1.0, green: 0.27, blue: 0.55)
    static let yellow = Color(red: 1.0, green: 0.82, blue: 0.1)
    static let blue = Color(red: 0.0, green: 0.32, blue: 0.65)

    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
}

/// How crazy a driver is. 1 is calm as a snail, 5 is "Galen förare".
enum GalenLevel: Int, CaseIterable, Identifiable {
    case snail = 1, sundayDriver, cheeky, turbo, galen

    var id: Int { rawValue }

    var emoji: String {
        switch self {
        case .snail: "🐌"
        case .sundayDriver: "🐢"
        case .cheeky: "🐒"
        case .turbo: "🐰"
        case .galen: "🤪"
        }
    }

    var name: String {
        switch self {
        case .snail: "Snigelfart"
        case .sundayDriver: "Söndagsåkare"
        case .cheeky: "Lite busig"
        case .turbo: "Turbokanin"
        case .galen: "Galen förare!"
        }
    }

    var blurb: String {
        switch self {
        case .snail: "Lugn som en snigel på semester."
        case .sundayDriver: "Tar det lugnt och njuter av utsikten."
        case .cheeky: "Lite för glad på gasen ibland."
        case .turbo: "Hoppar fram i trafiken som en kanin."
        case .galen: "Helt galet! Håll i hatten!"
        }
    }

    /// The closest level for an average score such as 3.6.
    init(average: Double) {
        self = GalenLevel(rawValue: min(5, max(1, Int(average.rounded())))) ?? .cheeky
    }
}

/// Car colors for the color hunt. The raw values are what the API stores.
enum CarColor: String, CaseIterable, Identifiable {
    case white, black, grey, silver, red, blue, green, yellow, orange, brown, purple, pink

    var id: String { rawValue }

    var name: String {
        switch self {
        case .white: "Vit"
        case .black: "Svart"
        case .grey: "Grå"
        case .silver: "Silver"
        case .red: "Röd"
        case .blue: "Blå"
        case .green: "Grön"
        case .yellow: "Gul"
        case .orange: "Orange"
        case .brown: "Brun"
        case .purple: "Lila"
        case .pink: "Rosa"
        }
    }

    var color: Color {
        switch self {
        case .white: .white
        case .black: .black
        case .grey: Color(white: 0.5)
        case .silver: Color(white: 0.78)
        case .red: .red
        case .blue: .blue
        case .green: .green
        case .yellow: .yellow
        case .orange: .orange
        case .brown: .brown
        case .purple: .purple
        case .pink: .pink
        }
    }

    /// Rare colors are worth more in the hunt.
    var points: Int {
        switch self {
        case .white, .black, .grey, .silver: 1
        case .red, .blue: 2
        case .green, .brown: 3
        case .yellow, .orange: 4
        case .purple, .pink: 5
        }
    }

    init?(key: String?) {
        guard let key, let color = CarColor(rawValue: key) else { return nil }
        self = color
    }
}

/// A round color dot with an outline, so white and black show on any background.
struct ColorDot: View {
    let color: CarColor
    var size: CGFloat = 28

    var body: some View {
        Circle()
            .fill(color.color)
            .overlay(Circle().strokeBorder(.primary.opacity(0.25), lineWidth: 1))
            .frame(width: size, height: size)
    }
}

/// A plate drawn like a Swedish one: white with the blue EU strip.
struct PlateBadge: View {
    let plate: String
    var size: CGFloat = 28

    var body: some View {
        HStack(spacing: 0) {
            Text("S")
                .font(.system(size: size * 0.5, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size * 0.9, height: size * 1.6)
                .background(Galen.blue)
            Text(plate)
                .font(.system(size: size, weight: .bold, design: .monospaced))
                .foregroundStyle(.black)
                .padding(.horizontal, size * 0.4)
                .frame(height: size * 1.6)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
        .overlay(RoundedRectangle(cornerRadius: size * 0.2).strokeBorder(.black, lineWidth: 2))
    }
}

/// A title earned by rating more cars.
enum SpotterRank {
    static func title(for count: Int) -> String {
        switch count {
        case 0..<5: "🐣 Nybörjarspanare"
        case 5..<20: "🔎 Bilspanare"
        case 20..<50: "🕵️ Mästerspanare"
        default: "🤪 Galen spanare"
        }
    }

    /// How many more ratings until the next title, or nil at the top.
    static func toNext(from count: Int) -> Int? {
        [5, 20, 50].first { $0 > count }.map { $0 - count }
    }
}
