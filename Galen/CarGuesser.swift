import CoreImage
import ImageIO
import UIKit
import Vision

/// Guesses the color, brand and kind of car in a photo. Runs on the phone with Apple Vision,
/// so the photo is never sent anywhere and it costs nothing.
///
/// - Brand: reads the text on the car (badge or lettering on the boot, e.g. "VOLVO", "TOYOTA", "TESLA").
///   Cars with only a logo and no text (many VW, Audi, Kia) can't be guessed this way.
/// - Color: cuts the car out of the photo (Vision foreground mask) and looks at which color most of it is.
/// - Kind: Apple's built-in image classifier (bus, truck, motorcycle, tractor …), plus "TAXI" on the car.
/// The guess only fills in empty fields; the user can always change it.
enum CarGuesser {
    struct Guess: Equatable {
        var color: CarColor?
        var brand: CarBrand?
        var kind: CarKind?
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

            var guess = Guess(color: color(in: cgImage, orientation: orientation), brand: brand(in: words), kind: kind(for: labels))
            if words.contains("TAXI") { guess.kind = .taxi }
            return guess
        }.value
    }

    /// The main color of the car. Uses the car cut out from the background, or the middle of the photo if that fails.
    static func color(in cgImage: CGImage, orientation: CGImagePropertyOrientation) -> CarColor? {
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation)
        let request = VNGenerateForegroundInstanceMaskRequest()
        if (try? handler.perform([request])) != nil, let result = request.results?.first,
           let masked = try? result.generateMaskedImage(ofInstances: result.allInstances, from: handler, croppedToInstancesExtent: true) {
            return dominantColor(of: CIImage(cvPixelBuffer: masked))
        }
        let full = CIImage(cgImage: cgImage)
        return dominantColor(of: full.cropped(to: full.extent.insetBy(dx: full.extent.width * 0.25, dy: full.extent.height * 0.25)))
    }

    /// Lets every visible pixel vote for a car color. Transparent pixels (the cut-away background) don't vote.
    static func dominantColor(of image: CIImage) -> CarColor? {
        let side = 48
        let extent = image.extent
        guard extent.width > 0, extent.height > 0 else { return nil }
        let scale = CGFloat(side) / max(extent.width, extent.height)
        let small = image
            .transformed(by: CGAffineTransform(translationX: -extent.minX, y: -extent.minY))
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        CIContext().render(small, toBitmap: &pixels, rowBytes: side * 4,
                           bounds: CGRect(x: 0, y: 0, width: side, height: side),
                           format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        var votes: [CarColor: Int] = [:]
        for i in stride(from: 0, to: pixels.count, by: 4) where pixels[i + 3] > 200 {
            var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0
            UIColor(red: CGFloat(pixels[i]) / 255, green: CGFloat(pixels[i + 1]) / 255, blue: CGFloat(pixels[i + 2]) / 255, alpha: 1)
                .getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
            votes[carColor(hue: hue * 360, saturation: saturation, brightness: brightness), default: 0] += 1
        }
        let total = votes.values.reduce(0, +)
        guard total > 30 else { return nil }

        // Windows, tyres and shadows add black and grey to every car, so a real color wins with a fair share.
        let neutral: Set<CarColor> = [.black, .grey, .silver, .white]
        if let colorful = votes.filter({ !neutral.contains($0.key) }).max(by: { $0.value < $1.value }),
           Double(colorful.value) / Double(total) > 0.2 {
            return colorful.key
        }
        return votes.max { $0.value < $1.value }?.key
    }

    static func carColor(hue: CGFloat, saturation: CGFloat, brightness: CGFloat) -> CarColor {
        if brightness < 0.18 { return .black }
        if saturation < 0.18 {
            if brightness > 0.85 { return .white }
            if brightness > 0.6 { return .silver }
            return brightness > 0.3 ? .grey : .black
        }
        switch hue {
        case ..<15, 345...: return saturation < 0.5 && brightness > 0.7 ? .pink : (brightness < 0.4 ? .brown : .red)
        case 15..<40: return brightness < 0.55 ? .brown : .orange
        case 40..<70: return brightness < 0.45 ? .brown : .yellow
        case 70..<170: return .green
        case 170..<260: return .blue
        case 260..<300: return .purple
        default: return .pink
        }
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
