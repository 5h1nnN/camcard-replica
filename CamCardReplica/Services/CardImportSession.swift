import Foundation
import Observation
import PhotosUI
import SwiftUI
import UIKit

enum CardImportState: Equatable {
    case idle
    case loadingImage
    case detectingEdges
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
    private(set) var editingCardID: UUID?
    private(set) var savedCardID: UUID?
    private(set) var didApplyPerspectiveCorrection = false

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
        editingCardID = nil
        savedCardID = nil
        didApplyPerspectiveCorrection = false
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

            return await processImageData(data)
        } catch {
            return fail(
                error.localizedDescription,
                restoring: previousDraft,
                imageData: previousImageData
            )
        }
    }

    func importImageData(_ data: Data) async -> CardImportOutcome {
        let previousDraft = draft
        let previousImageData = imageData
        guard UIImage(data: data) != nil else {
            return fail(
                "无法读取拍摄的图片，请重新拍摄。",
                restoring: previousDraft,
                imageData: previousImageData
            )
        }
        return await processImageData(data)
    }

    func continueWithManualEntry() {
        draft = .empty
        state = .ready
        isManualEntry = true
        didApplyPerspectiveCorrection = false
    }

    func loadFixture() {
        draft = .fixture
        imageData = UIImage(named: FixtureCatalog.syntheticBusinessCard.assetName)?.pngData()
        state = .ready
        isManualEntry = false
        editingCardID = nil
        savedCardID = nil
        didApplyPerspectiveCorrection = false
    }

    func prepareForEditing(_ card: BusinessCard, imageData: Data?) {
        draft = card.draft
        self.imageData = imageData
        state = .ready
        isManualEntry = false
        editingCardID = card.id
        savedCardID = nil
        didApplyPerspectiveCorrection = false
    }

    func markSaved(cardID: UUID) {
        editingCardID = cardID
        savedCardID = cardID
        state = .ready
    }

    private func processImageData(_ data: Data) async -> CardImportOutcome {
        state = .detectingEdges
        isManualEntry = false
        state = .recognizing
        let recognition = await BusinessCardRecognitionPipeline.process(data)
        imageData = recognition.imageData
        didApplyPerspectiveCorrection = recognition.didApplyPerspectiveCorrection
        guard !BusinessCardFieldParser.normalizedLines(in: recognition.rawText).isEmpty else {
            draft = .empty
            state = .noText
            return .noText
        }

        draft = recognition.draft
        state = .ready
        return .ready
    }

    private func fail(
        _ message: String,
        restoring previousDraft: BusinessCardDraft,
        imageData previousImageData: Data?
    ) -> CardImportOutcome {
        imageData = previousImageData
        didApplyPerspectiveCorrection = false
        draft = previousDraft
        let safeMessage = message.isEmpty ? "识别失败，请重新选择图片。" : message
        state = .failed(message: safeMessage)
        return .failed(message: safeMessage)
    }
}
