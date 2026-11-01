import SwiftUI

/// The Biljakt look: bright colors and rounded fonts. (The enum keeps its old name AppStyle.)
enum AppStyle {
    static let pink = Color(red: 1.0, green: 0.27, blue: 0.55)
    static let yellow = Color(red: 1.0, green: 0.82, blue: 0.1)
    static let blue = Color(red: 0.0, green: 0.32, blue: 0.65)

    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy, design: .rounded) }
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

/// Kinds of car for the car-kind hunt. The raw values are what the API stores (CarKinds in the API).
enum CarKind: String, CaseIterable, Identifiable {
    case car, suv, van, truck, bus, motorcycle, taxi, camper, tractor, sports, vintage, emergency

    var id: String { rawValue }

    var name: String {
        switch self {
        case .car: "Vanlig bil"
        case .suv: "Jeep/SUV"
        case .van: "Skåpbil"
        case .truck: "Lastbil"
        case .bus: "Buss"
        case .motorcycle: "Motorcykel"
        case .taxi: "Taxi"
        case .camper: "Husbil"
        case .tractor: "Traktor"
        case .sports: "Sportbil"
        case .vintage: "Veteranbil"
        case .emergency: "Utryckning"
        }
    }

    var emoji: String {
        switch self {
        case .car: "🚗"
        case .suv: "🚙"
        case .van: "🚐"
        case .truck: "🚚"
        case .bus: "🚌"
        case .motorcycle: "🏍️"
        case .taxi: "🚕"
        case .camper: "🏕️"
        case .tractor: "🚜"
        case .sports: "🏎️"
        case .vintage: "🕰️"
        case .emergency: "🚑"
        }
    }

    /// Rare kinds are worth more in the hunt.
    var points: Int {
        switch self {
        case .car, .suv: 1
        case .van, .truck: 2
        case .bus, .taxi, .motorcycle: 3
        case .camper, .tractor: 4
        case .sports, .vintage, .emergency: 5
        }
    }

    init?(key: String?) {
        guard let key, let kind = CarKind(rawValue: key) else { return nil }
        self = kind
    }
}

/// Car brands for the brand hunt. The raw values are what the API stores (CarBrands in the API).
enum CarBrand: String, CaseIterable, Identifiable {
    case volvo, volkswagen, toyota, audi, bmw, mercedes, kia, ford, skoda, tesla, renault,
         peugeot, hyundai, nissan, polestar, saab, porsche, ferrari, lamborghini

    var id: String { rawValue }

    var name: String {
        switch self {
        case .volvo: "Volvo"
        case .volkswagen: "Volkswagen"
        case .toyota: "Toyota"
        case .audi: "Audi"
        case .bmw: "BMW"
        case .mercedes: "Mercedes"
        case .kia: "Kia"
        case .ford: "Ford"
        case .skoda: "Škoda"
        case .tesla: "Tesla"
        case .renault: "Renault"
        case .peugeot: "Peugeot"
        case .hyundai: "Hyundai"
        case .nissan: "Nissan"
        case .polestar: "Polestar"
        case .saab: "Saab"
        case .porsche: "Porsche"
        case .ferrari: "Ferrari"
        case .lamborghini: "Lamborghini"
        }
    }

    /// Rare brands on Swedish roads are worth more in the hunt.
    var points: Int {
        switch self {
        case .volvo, .volkswagen, .toyota: 1
        case .audi, .bmw, .mercedes, .kia, .ford, .skoda: 2
        case .tesla, .renault, .peugeot, .hyundai, .nissan: 3
        case .polestar, .saab: 4
        case .porsche, .ferrari, .lamborghini: 5
        }
    }

    /// Words written on the car (badge or lettering on the boot) that give the brand away.
    var badgeWords: [String] {
        switch self {
        case .mercedes: ["MERCEDES", "BENZ"]
        case .volkswagen: ["VOLKSWAGEN"]
        case .skoda: ["SKODA", "ŠKODA"]
        default: [rawValue.uppercased()]
        }
    }

    init?(key: String?) {
        guard let key, let brand = CarBrand(rawValue: key) else { return nil }
        self = brand
    }
}

/// Hunt points: every color, kind and brand of car you have found counts once.
enum HuntScore {
    static func points(colors: some Sequence<CarColor>, kinds: some Sequence<CarKind>, brands: some Sequence<CarBrand>) -> Int {
        Set(colors).reduce(0) { $0 + $1.points } + Set(kinds).reduce(0) { $0 + $1.points } + Set(brands).reduce(0) { $0 + $1.points }
    }

    static var maxPoints: Int { points(colors: CarColor.allCases, kinds: CarKind.allCases, brands: CarBrand.allCases) }
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
                .background(AppStyle.blue)
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

/// A title earned by finding more cars.
enum SpotterRank {
    static func title(for count: Int) -> String {
        switch count {
        case 0..<5: "🐣 Nybörjarspanare"
        case 5..<20: "🔎 Bilspanare"
        case 20..<50: "🕵️ Mästerspanare"
        default: "🏆 Biljaktsmästare"
        }
    }

    /// How many more ratings until the next title, or nil at the top.
    static func toNext(from count: Int) -> Int? {
        [5, 20, 50].first { $0 > count }.map { $0 - count }
    }
}
