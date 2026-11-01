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
/// The icons are our own simple badges (initials in a color), not the brands' logos, which are trademarks.
enum CarBrand: String, CaseIterable, Identifiable {
    case volvo, volkswagen, toyota, audi, bmw, mercedes, kia, ford, skoda, opel, tesla, renault, peugeot, citroen, hyundai, nissan, mazda, honda, subaru, mitsubishi, suzuki, seat, dacia, fiat, mini, jeep, mg, scania, polestar, saab, cupra, byd, lexus, landrover, jaguar, smart, alfaromeo, man, daf, iveco, porsche, ferrari, lamborghini, maserati, bentley, rollsroyce, astonmartin, mclaren, koenigsegg, bugatti

    var id: String { rawValue }

    /// All brands sorted by name, for pickers.
    static var byName: [CarBrand] { allCases.sorted { $0.name.localizedCompare($1.name) == .orderedAscending } }

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
        case .opel: "Opel"
        case .tesla: "Tesla"
        case .renault: "Renault"
        case .peugeot: "Peugeot"
        case .citroen: "Citroën"
        case .hyundai: "Hyundai"
        case .nissan: "Nissan"
        case .mazda: "Mazda"
        case .honda: "Honda"
        case .subaru: "Subaru"
        case .mitsubishi: "Mitsubishi"
        case .suzuki: "Suzuki"
        case .seat: "Seat"
        case .dacia: "Dacia"
        case .fiat: "Fiat"
        case .mini: "Mini"
        case .jeep: "Jeep"
        case .mg: "MG"
        case .scania: "Scania"
        case .polestar: "Polestar"
        case .saab: "Saab"
        case .cupra: "Cupra"
        case .byd: "BYD"
        case .lexus: "Lexus"
        case .landrover: "Land Rover"
        case .jaguar: "Jaguar"
        case .smart: "Smart"
        case .alfaromeo: "Alfa Romeo"
        case .man: "MAN"
        case .daf: "DAF"
        case .iveco: "Iveco"
        case .porsche: "Porsche"
        case .ferrari: "Ferrari"
        case .lamborghini: "Lamborghini"
        case .maserati: "Maserati"
        case .bentley: "Bentley"
        case .rollsroyce: "Rolls-Royce"
        case .astonmartin: "Aston Martin"
        case .mclaren: "McLaren"
        case .koenigsegg: "Koenigsegg"
        case .bugatti: "Bugatti"
        }
    }

    /// One to four letters shown on the badge.
    var short: String {
        switch self {
        case .volvo: "VO"
        case .volkswagen: "VW"
        case .toyota: "TO"
        case .audi: "AU"
        case .bmw: "BMW"
        case .mercedes: "MB"
        case .kia: "KIA"
        case .ford: "FO"
        case .skoda: "ŠK"
        case .opel: "OP"
        case .tesla: "TE"
        case .renault: "RE"
        case .peugeot: "PE"
        case .citroen: "CI"
        case .hyundai: "HY"
        case .nissan: "NI"
        case .mazda: "MA"
        case .honda: "HO"
        case .subaru: "SU"
        case .mitsubishi: "MI"
        case .suzuki: "SZ"
        case .seat: "SE"
        case .dacia: "DA"
        case .fiat: "FI"
        case .mini: "MINI"
        case .jeep: "JE"
        case .mg: "MG"
        case .scania: "SC"
        case .polestar: "PS"
        case .saab: "SA"
        case .cupra: "CU"
        case .byd: "BYD"
        case .lexus: "LX"
        case .landrover: "LR"
        case .jaguar: "JA"
        case .smart: "SM"
        case .alfaromeo: "AR"
        case .man: "MAN"
        case .daf: "DAF"
        case .iveco: "IV"
        case .porsche: "PO"
        case .ferrari: "FE"
        case .lamborghini: "LA"
        case .maserati: "MS"
        case .bentley: "BE"
        case .rollsroyce: "RR"
        case .astonmartin: "AM"
        case .mclaren: "MC"
        case .koenigsegg: "KO"
        case .bugatti: "BU"
        }
    }

    /// Rare brands on Swedish roads are worth more in the hunt.
    var points: Int {
        switch self {
        case .volvo: 1
        case .volkswagen: 1
        case .toyota: 1
        case .audi: 2
        case .bmw: 2
        case .mercedes: 2
        case .kia: 2
        case .ford: 2
        case .skoda: 2
        case .opel: 2
        case .tesla: 3
        case .renault: 3
        case .peugeot: 3
        case .citroen: 3
        case .hyundai: 3
        case .nissan: 3
        case .mazda: 3
        case .honda: 3
        case .subaru: 3
        case .mitsubishi: 3
        case .suzuki: 3
        case .seat: 3
        case .dacia: 3
        case .fiat: 3
        case .mini: 3
        case .jeep: 3
        case .mg: 3
        case .scania: 3
        case .polestar: 4
        case .saab: 4
        case .cupra: 4
        case .byd: 4
        case .lexus: 4
        case .landrover: 4
        case .jaguar: 4
        case .smart: 4
        case .alfaromeo: 4
        case .man: 4
        case .daf: 4
        case .iveco: 4
        case .porsche: 5
        case .ferrari: 5
        case .lamborghini: 5
        case .maserati: 5
        case .bentley: 5
        case .rollsroyce: 5
        case .astonmartin: 5
        case .mclaren: 5
        case .koenigsegg: 5
        case .bugatti: 5
        }
    }

    /// The badge color, as hex.
    private var hex: UInt32 {
        switch self {
        case .volvo: 0x1F3B73
        case .volkswagen: 0x001E50
        case .toyota: 0xEB0A1E
        case .audi: 0x2B2B2B
        case .bmw: 0x1C69D4
        case .mercedes: 0x4A4A4A
        case .kia: 0x05141F
        case .ford: 0x003478
        case .skoda: 0x0E3A2F
        case .opel: 0xC9A400
        case .tesla: 0xCC0000
        case .renault: 0xD9A800
        case .peugeot: 0x1A1A1A
        case .citroen: 0x8C1D2C
        case .hyundai: 0x002C5F
        case .nissan: 0xC3002F
        case .mazda: 0x303030
        case .honda: 0xCC0000
        case .subaru: 0x013C74
        case .mitsubishi: 0xE60012
        case .suzuki: 0xE30613
        case .seat: 0xB5121B
        case .dacia: 0x646B52
        case .fiat: 0xA6192E
        case .mini: 0x111111
        case .jeep: 0x3B5323
        case .mg: 0x9B1B30
        case .scania: 0x041E42
        case .polestar: 0x3A3A3A
        case .saab: 0x0B3D91
        case .cupra: 0x95572B
        case .byd: 0xC00000
        case .lexus: 0x2E2E2E
        case .landrover: 0x005A2B
        case .jaguar: 0x1A1A1A
        case .smart: 0x3C3C3C
        case .alfaromeo: 0x8F0E1F
        case .man: 0x2D2D2D
        case .daf: 0x003DA5
        case .iveco: 0x1D4F91
        case .porsche: 0x8A6D2F
        case .ferrari: 0xD40000
        case .lamborghini: 0x8B6914
        case .maserati: 0x0C2340
        case .bentley: 0x333333
        case .rollsroyce: 0x222244
        case .astonmartin: 0x00665E
        case .mclaren: 0xE07000
        case .koenigsegg: 0x202020
        case .bugatti: 0x0033A0
        }
    }

    var tint: Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    /// Words written on the car (badge or lettering on the boot) that give the brand away.
    var badgeWords: [String] {
        switch self {
        case .volvo: ["VOLVO"]
        case .volkswagen: ["VOLKSWAGEN"]
        case .toyota: ["TOYOTA"]
        case .audi: ["AUDI"]
        case .bmw: ["BMW"]
        case .mercedes: ["MERCEDES", "BENZ"]
        case .kia: ["KIA"]
        case .ford: ["FORD"]
        case .skoda: ["SKODA", "ŠKODA"]
        case .opel: ["OPEL"]
        case .tesla: ["TESLA"]
        case .renault: ["RENAULT"]
        case .peugeot: ["PEUGEOT"]
        case .citroen: ["CITROEN", "CITROËN"]
        case .hyundai: ["HYUNDAI"]
        case .nissan: ["NISSAN"]
        case .mazda: ["MAZDA"]
        case .honda: ["HONDA"]
        case .subaru: ["SUBARU"]
        case .mitsubishi: ["MITSUBISHI"]
        case .suzuki: ["SUZUKI"]
        case .seat: ["SEAT"]
        case .dacia: ["DACIA"]
        case .fiat: ["FIAT"]
        case .mini: ["MINI"]
        case .jeep: ["JEEP"]
        case .mg: ["MG"]
        case .scania: ["SCANIA"]
        case .polestar: ["POLESTAR"]
        case .saab: ["SAAB"]
        case .cupra: ["CUPRA"]
        case .byd: ["BYD"]
        case .lexus: ["LEXUS"]
        case .landrover: ["ROVER", "DEFENDER"]
        case .jaguar: ["JAGUAR"]
        case .smart: ["SMART"]
        case .alfaromeo: ["ROMEO"]
        case .man: ["MAN"]
        case .daf: ["DAF"]
        case .iveco: ["IVECO"]
        case .porsche: ["PORSCHE"]
        case .ferrari: ["FERRARI"]
        case .lamborghini: ["LAMBORGHINI"]
        case .maserati: ["MASERATI"]
        case .bentley: ["BENTLEY"]
        case .rollsroyce: ["ROLLS"]
        case .astonmartin: ["ASTON"]
        case .mclaren: ["MCLAREN"]
        case .koenigsegg: ["KOENIGSEGG"]
        case .bugatti: ["BUGATTI"]
        }
    }

    init?(key: String?) {
        guard let key, let brand = CarBrand(rawValue: key) else { return nil }
        self = brand
    }
}

/// A round badge for a brand: the brand's real logo on white while `useRealLogos` is on,
/// otherwise its initials on its color.
///
/// The logos are the brands' trademarks (images from github.com/filippofilip95/car-logos-dataset,
/// in Assets.xcassets/BrandLogos). Apple's App Review guideline 5.2.1 asks for permission to use them,
/// so turn `useRealLogos` off before an App Store release unless that permission is in place.
struct BrandBadge: View {
    static let useRealLogos = true

    let brand: CarBrand
    var size: CGFloat = 44

    var body: some View {
        if Self.useRealLogos, let logo = UIImage(named: "logo-\(brand.rawValue)") {
            Circle()
                .fill(.white)
                .overlay(Circle().strokeBorder(brand.tint.opacity(0.5), lineWidth: max(1, size * 0.04)))
                .overlay {
                    Image(uiImage: logo)
                        .resizable()
                        .scaledToFit()
                        .padding(size * 0.14)
                }
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
        } else {
            Circle()
                .fill(brand.tint.gradient)
                .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: size * 0.05))
                .overlay {
                    Text(brand.short)
                        .font(.system(size: size * 0.36, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(size * 0.12)
                }
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
        }
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
