import ImageIO
import UIKit
import Vision

/// Finds a Swedish license plate in a photo. Runs on the phone with Apple's text recognition,
/// so the photo is never sent anywhere and it costs nothing.
enum PlateScanner {
    static func plate(in image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)

        return await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
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

private extension CGImagePropertyOrientation {
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
