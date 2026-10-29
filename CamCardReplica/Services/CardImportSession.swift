import Foundation
import Observation
import PhotosUI
import SwiftUI
import UIKit

enum CardImportState: Equatable {
    case idle
    case loadingImage
    case recognizing
    case ready
    case noText
    case failed(message: String)
}

enum CardImportOutcome: Equatable {
    case cancelled
    case ready
    case noText
    case failed(message: String)
}

@MainActor
@Observable
final class CardImportSession {
    var draft: BusinessCardDraft
    private(set) var imageData: Data?
    private(set) var state: CardImportState = .idle
    private(set) var isManualEntry = false

    init(draft: BusinessCardDraft = .fixture, imageData: Data? = nil) {
        self.draft = draft
        self.imageData = imageData
    }

    var selectedImage: UIImage? {
        imageData.flatMap(UIImage.init(data:))
    }

    func beginNewImport() {
        state = .idle
        isManualEntry = false
    }

    func importPhoto(_ item: PhotosPickerItem?) async -> CardImportOutcome {
        guard let item else { return .cancelled }
        let previousDraft = draft
        let previousImageData = imageData
        state = .loadingImage
        isManualEntry = false

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  UIImage(data: data) != nil else {
                return fail(
                    "无法读取所选图片，请重新选择 JPEG、PNG 或 HEIC 图片。",
                    restoring: previousDraft,
                    imageData: previousImageData
                )
            }

            imageData = data
            state = .recognizing
            let rawText = try await VisionTextRecognizer.recognizeText(in: data)
            guard !BusinessCardFieldParser.normalizedLines(in: rawText).isEmpty else {
                draft = .empty
                state = .noText
                return .noText
            }

            draft = BusinessCardFieldParser.parse(rawText)
            state = .ready
            return .ready
        } catch {
            return fail(
                error.localizedDescription,
                restoring: previousDraft,
                imageData: previousImageData
            )
        }
    }

    func continueWithManualEntry() {
        draft = .empty
        state = .ready
        isManualEntry = true
    }

    func loadFixture() {
        draft = .fixture
        imageData = UIImage(named: FixtureCatalog.syntheticBusinessCard.assetName)?.pngData()
        state = .ready
        isManualEntry = false
    }

    private func fail(
        _ message: String,
        restoring previousDraft: BusinessCardDraft,
        imageData previousImageData: Data?
    ) -> CardImportOutcome {
        imageData = previousImageData
        draft = previousDraft
        let safeMessage = message.isEmpty ? "识别失败，请重新选择图片。" : message
        state = .failed(message: safeMessage)
        return .failed(message: safeMessage)
    }
}
