import CoreImage
import ImageIO
import UIKit
import Vision

/// Finds a Swedish license plate in a photo of the whole car, and can pixelate it. Runs on the phone with Apple's text recognition,
/// so the photo is never sent anywhere and it costs nothing.
enum PlateScanner {
    static func plate(in image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            // In a photo of the whole car the plate is small, so look for small text too.
            request.minimumTextHeight = 0.01
            try? VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([request])

            // The biggest text that looks like a plate is most likely the plate we want.
            return (request.results ?? [])
                .sorted { $0.boundingBox.height > $1.boundingBox.height }
                .lazy
                .flatMap { $0.topCandidates(3) }
                .compactMap { plateCandidate(in: $0.string) }
                .first
        }.value
    }

    /// A copy of the photo with the plate pixelated, so a friend can check the car without seeing the plate.
    /// If no plate is found, all text in the photo is pixelated to be safe.
    static func hidingPlates(in image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            request.minimumTextHeight = 0.01
            try? VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([request])

            let texts = request.results ?? []
            let plates = texts.filter { text in text.topCandidates(3).contains { plateCandidate(in: $0.string) != nil } }
            let boxes = (plates.isEmpty ? texts : plates).map(\.boundingBox)

            var output = CIImage(cgImage: cgImage).oriented(orientation)
            let extent = output.extent
            let pixelated = output.clampedToExtent()
                .applyingFilter("CIPixellate", parameters: [kCIInputScaleKey: max(extent.width, extent.height) / 30])
                .cropped(to: extent)
            for box in boxes {
                // Vision boxes are 0...1 with the origin bottom-left, like Core Image. Grow them a bit.
                let rect = CGRect(x: extent.minX + box.minX * extent.width, y: extent.minY + box.minY * extent.height,
                                  width: box.width * extent.width, height: box.height * extent.height)
                    .insetBy(dx: -box.width * extent.width * 0.25, dy: -box.height * extent.height * 0.8)
                output = pixelated.cropped(to: rect).composited(over: output)
            }
            guard let result = CIContext().createCGImage(output, from: extent) else { return nil }
            return UIImage(cgImage: result)
        }.value
    }

    /// Looks for ABC123 or ABC12D anywhere in the text, e.g. "S ABC 123" or "ABC-123".
    static func plateCandidate(in text: String) -> String? {
        let chars = Array(text.uppercased().filter { $0.isLetter || $0.isNumber })
        guard chars.count >= 6 else { return nil }
        for start in 0...(chars.count - 6) {
            let plate = fixLookalikes(Array(chars[start..<start + 6]))
            if PlateNumber.isValid(plate) { return plate }
        }
        return nil
    }

    /// Text recognition mixes up O/0, I/1, S/5, B/8 and Z/2. A plate always starts with
    /// three letters and has digits in places four and five, so fix those places.
    private static func fixLookalikes(_ chars: [Character]) -> String {
        let toLetter: [Character: Character] = ["0": "O", "1": "I", "5": "S", "8": "B", "2": "Z"]
        let toDigit: [Character: Character] = ["O": "0", "I": "1", "S": "5", "B": "8", "Z": "2", "D": "0"]
        var fixed = chars
        for i in 0..<3 { fixed[i] = toLetter[fixed[i]] ?? fixed[i] }
        for i in 3..<5 { fixed[i] = toDigit[fixed[i]] ?? fixed[i] }
        return String(fixed)
    }
}

extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
