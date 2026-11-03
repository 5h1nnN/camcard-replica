import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import UIKit
import Vision

struct CardQuadrilateral: Equatable, Sendable {
    let topLeft: CGPoint
    let topRight: CGPoint
    let bottomRight: CGPoint
    let bottomLeft: CGPoint
}

struct CardImageCorrectionResult: Equatable, Sendable {
    let imageData: Data
    let didCorrectPerspective: Bool
    let quadrilateral: CardQuadrilateral?
}

enum CardPerspectiveCorrectionError: LocalizedError {
    case unreadableImage
    case renderingFailed

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            "无法读取图片，不能执行边缘检测。"
        case .renderingFailed:
            "已检测到名片边缘，但透视校正失败。"
        }
    }
}

enum CardPerspectiveCorrector {
    nonisolated static func correct(_ imageData: Data) async throws -> CardImageCorrectionResult {
        try await Task.detached(priority: .userInitiated) {
            try correctSynchronously(imageData)
        }.value
    }

    nonisolated static func correctSynchronously(_ imageData: Data) throws -> CardImageCorrectionResult {
        guard let inputImage = CIImage(
            data: imageData,
            options: [.applyOrientationProperty: true]
        ) else {
            throw CardPerspectiveCorrectionError.unreadableImage
        }

        guard let quadrilateral = try detectQuadrilateral(in: inputImage) else {
            return CardImageCorrectionResult(
                imageData: imageData,
                didCorrectPerspective: false,
                quadrilateral: nil
            )
        }
        do {
            return try correctedImage(in: imageData, quadrilateral: quadrilateral)
        } catch CardPerspectiveCorrectionError.renderingFailed {
            return CardImageCorrectionResult(
                imageData: imageData,
                didCorrectPerspective: false,
                quadrilateral: quadrilateral
            )
        }
    }

    nonisolated static func correctedImage(
        in imageData: Data,
        quadrilateral: CardQuadrilateral
    ) throws -> CardImageCorrectionResult {
        guard let inputImage = CIImage(
            data: imageData,
            options: [.applyOrientationProperty: true]
        ) else {
            throw CardPerspectiveCorrectionError.unreadableImage
        }

        let extent = inputImage.extent
        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = inputImage
        filter.topLeft = imagePoint(quadrilateral.topLeft, in: extent)
        filter.topRight = imagePoint(quadrilateral.topRight, in: extent)
        filter.bottomRight = imagePoint(quadrilateral.bottomRight, in: extent)
        filter.bottomLeft = imagePoint(quadrilateral.bottomLeft, in: extent)

        guard let outputImage = filter.outputImage else {
            throw CardPerspectiveCorrectionError.renderingFailed
        }
        let outputExtent = outputImage.extent.integral
        let context = CIContext(options: [.cacheIntermediates: false])
        guard !outputExtent.isEmpty,
              outputExtent.isFinite,
              let cgImage = context.createCGImage(outputImage, from: outputExtent),
              let data = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.92) else {
            throw CardPerspectiveCorrectionError.renderingFailed
        }

        return CardImageCorrectionResult(
            imageData: data,
            didCorrectPerspective: true,
            quadrilateral: quadrilateral
        )
    }

    nonisolated private static func detectQuadrilateral(in image: CIImage) throws -> CardQuadrilateral? {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 8
        request.minimumConfidence = 0.6
        request.minimumAspectRatio = 0.35
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.18
        request.quadratureTolerance = 35

        let handler = VNImageRequestHandler(ciImage: image, orientation: .up)
        try handler.perform([request])
        let candidates = request.results ?? []
        let rectangle = candidates
            .filter(isPlausibleBusinessCard)
            .max(by: { candidateScore($0) < candidateScore($1) })
            ?? candidates
                .filter { (0.35...0.88).contains(quadrilateralArea($0)) }
                .max(by: { quadrilateralArea($0) < quadrilateralArea($1) })
        guard let rectangle else {
            return nil
        }
        return CardQuadrilateral(
            topLeft: rectangle.topLeft,
            topRight: rectangle.topRight,
            bottomRight: rectangle.bottomRight,
            bottomLeft: rectangle.bottomLeft
        )
    }

    nonisolated private static func isPlausibleBusinessCard(_ rectangle: VNRectangleObservation) -> Bool {
        let area = quadrilateralArea(rectangle)
        let ratio = longToShortAspectRatio(rectangle)
        // Strong perspective can make a landscape card approach a square in
        // the source image, so area is the stronger guard for low ratios.
        return (0.24...0.88).contains(area) && (1.1...2.35).contains(ratio)
    }

    nonisolated private static func candidateScore(_ rectangle: VNRectangleObservation) -> CGFloat {
        let area = quadrilateralArea(rectangle)
        let ratio = longToShortAspectRatio(rectangle)
        let ratioPenalty = abs(ratio - 1.75)
        return area * 5 + CGFloat(rectangle.confidence) * 2 - ratioPenalty
    }

    nonisolated private static func quadrilateralArea(_ rectangle: VNRectangleObservation) -> CGFloat {
        let points = [
            rectangle.topLeft,
            rectangle.topRight,
            rectangle.bottomRight,
            rectangle.bottomLeft
        ]
        let doubledArea = zip(points, points.dropFirst() + [points[0]]).reduce(CGFloat.zero) { result, pair in
            result + pair.0.x * pair.1.y - pair.1.x * pair.0.y
        }
        return abs(doubledArea) / 2
    }

    nonisolated private static func longToShortAspectRatio(_ rectangle: VNRectangleObservation) -> CGFloat {
        let horizontal = (
            distance(rectangle.topLeft, rectangle.topRight) +
            distance(rectangle.bottomLeft, rectangle.bottomRight)
        ) / 2
        let vertical = (
            distance(rectangle.topLeft, rectangle.bottomLeft) +
            distance(rectangle.topRight, rectangle.bottomRight)
        ) / 2
        let short = min(horizontal, vertical)
        guard short > 0 else { return .infinity }
        return max(horizontal, vertical) / short
    }

    nonisolated private static func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    nonisolated private static func imagePoint(_ normalizedPoint: CGPoint, in extent: CGRect) -> CGPoint {
        CGPoint(
            x: extent.minX + normalizedPoint.x * extent.width,
            y: extent.minY + normalizedPoint.y * extent.height
        )
    }
}

private extension CGRect {
    nonisolated var isFinite: Bool {
        minX.isFinite && minY.isFinite && width.isFinite && height.isFinite
    }
}
