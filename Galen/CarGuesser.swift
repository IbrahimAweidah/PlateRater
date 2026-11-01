import ImageIO
import UIKit
import Vision

/// Guesses the brand and kind of car in a photo. Runs on the phone with Apple Vision,
/// so the photo is never sent anywhere and it costs nothing.
///
/// - Brand: reads the text on the car (badge or lettering on the boot, e.g. "VOLVO", "TOYOTA", "TESLA").
///   Cars with only a logo and no text (many VW, Audi, Kia) can't be guessed this way.
/// - Kind: Apple's built-in image classifier (bus, truck, motorcycle, tractor …), plus "TAXI" on the car.
/// The guess only fills in empty fields; the user can always change it.
enum CarGuesser {
    struct Guess: Equatable {
        var brand: CarBrand?
        var kind: CarKind?

        var isEmpty: Bool { brand == nil && kind == nil }
    }

    static func guess(from image: UIImage) async -> Guess {
        guard let cgImage = image.cgImage else { return Guess() }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return await Task.detached(priority: .userInitiated) {
            let text = VNRecognizeTextRequest()
            text.recognitionLevel = .accurate
            text.usesLanguageCorrection = false
            let classify = VNClassifyImageRequest()
            try? VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([text, classify])

            let words = (text.results ?? [])
                .compactMap { $0.topCandidates(1).first?.string.uppercased() }
                .joined(separator: " ")
            let labels = (classify.results ?? [])
                .filter { $0.confidence > 0.3 }
                .sorted { $0.confidence > $1.confidence }
                .map(\.identifier)

            var guess = Guess(brand: brand(in: words), kind: kind(for: labels))
            if words.contains("TAXI") { guess.kind = .taxi }
            return guess
        }.value
    }

    /// The first brand whose name appears as a word in the text.
    static func brand(in text: String) -> CarBrand? {
        let words = Set(text.components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty })
        // Tesla often spells its name with spaces: "T E S L A".
        let squeezed = text.filter(\.isLetter)
        return CarBrand.allCases.first { brand in
            brand.badgeWords.contains { words.contains($0) || ($0.count >= 5 && squeezed.contains($0)) }
        }
    }

    /// Maps Apple's classifier labels to our kinds. A specific kind beats a plain "car".
    static func kind(for labels: [String]) -> CarKind? {
        let mapped = labels.compactMap { label in labelKinds.first { $0.labels.contains(label) }?.kind }
        return mapped.first { $0 != .car } ?? mapped.first
    }

    private static let labelKinds: [(kind: CarKind, labels: Set<String>)] = [
        (.motorcycle, ["motorcycle", "motorbike", "moped", "scooter"]),
        (.bus, ["bus", "schoolbus", "school_bus", "trolleybus"]),
        (.tractor, ["tractor", "farm_machinery"]),
        (.emergency, ["ambulance", "fire_truck", "fire_engine", "firetruck", "police_car"]),
        (.camper, ["rv", "camper", "motorhome", "recreational_vehicle", "camper_van"]),
        (.truck, ["truck", "semi_truck", "tow_truck", "lorry", "pickup_truck", "dump_truck"]),
        (.van, ["van", "minivan"]),
        (.suv, ["suv", "jeep"]),
        (.sports, ["sports_car", "race_car", "racecar", "convertible"]),
        (.vintage, ["vintage_car", "antique_car", "classic_car"]),
        (.taxi, ["taxi", "cab"]),
        (.car, ["car", "automobile", "sedan", "hatchback", "coupe", "station_wagon"]),
    ]
}
