import Foundation
import UIKit
import Vision

struct RecognizedTextLine: Equatable, Sendable {
    let text: String
    let boundingBox: CGRect
}

enum RecognizedTextReadingOrder {
    static func sorted(_ lines: [RecognizedTextLine]) -> [RecognizedTextLine] {
        lines.sorted { lhs, rhs in
            let verticalDistance = abs(lhs.boundingBox.midY - rhs.boundingBox.midY)
            if verticalDistance > 0.025 {
                return lhs.boundingBox.midY > rhs.boundingBox.midY
            }
            return lhs.boundingBox.minX < rhs.boundingBox.minX
        }
    }
}

enum VisionTextRecognitionError: LocalizedError {
    case unreadableImage

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            "无法读取所选图片，请重新选择 JPEG、PNG 或 HEIC 图片。"
        }
    }
}

enum VisionTextRecognizer {
    nonisolated static func recognizeText(in data: Data) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            guard let image = UIImage(data: data), let cgImage = image.cgImage else {
                throw VisionTextRecognitionError.unreadableImage
            }

            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: image.imageOrientation.cgImageOrientation,
                options: [:]
            )
            try handler.perform([request])

            let lines = (request.results ?? []).compactMap { observation -> RecognizedTextLine? in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return nil }
                return RecognizedTextLine(text: text, boundingBox: observation.boundingBox)
            }
            return RecognizedTextReadingOrder.sorted(lines)
                .map(\.text)
                .joined(separator: "\n")
        }.value
    }
}

private extension UIImage.Orientation {
    nonisolated var cgImageOrientation: CGImagePropertyOrientation {
        switch self {
        case .up: .up
        case .down: .down
        case .left: .left
        case .right: .right
        case .upMirrored: .upMirrored
        case .downMirrored: .downMirrored
        case .leftMirrored: .leftMirrored
        case .rightMirrored: .rightMirrored
        @unknown default: .up
        }
    }
}
