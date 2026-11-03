import Foundation

enum CardRecognitionImageSource: String, Equatable {
    case original
    case corrected
}

struct BusinessCardRecognitionResult {
    let imageData: Data
    let rawText: String
    let draft: BusinessCardDraft
    let didApplyPerspectiveCorrection: Bool
    let selectedSource: CardRecognitionImageSource
    let originalRawText: String
    let correctedRawText: String
}

enum BusinessCardRecognitionPipeline {
    nonisolated static func process(_ imageData: Data) async -> BusinessCardRecognitionResult {
        let correction = try? await CardPerspectiveCorrector.correct(imageData)
        guard let correction, correction.didCorrectPerspective else {
            let rawText = await recognizeOrEmpty(imageData)
            return result(
                imageData: imageData,
                rawText: rawText,
                didApplyPerspectiveCorrection: false,
                selectedSource: .original,
                originalRawText: rawText,
                correctedRawText: ""
            )
        }

        async let originalTextTask = recognizeOrEmpty(imageData)
        async let correctedTextTask = recognizeOrEmpty(correction.imageData)
        let (originalText, correctedText) = await (originalTextTask, correctedTextTask)

        let correctedScore = recognitionQualityScore(correctedText)
        let originalScore = recognitionQualityScore(originalText)
        let useCorrected = !correctedText.isEmpty && correctedScore >= originalScore
        let selectedText = useCorrected ? correctedText : originalText

        return result(
            imageData: useCorrected ? correction.imageData : imageData,
            rawText: selectedText,
            didApplyPerspectiveCorrection: useCorrected,
            selectedSource: useCorrected ? .corrected : .original,
            originalRawText: originalText,
            correctedRawText: correctedText
        )
    }

    nonisolated static func recognitionQualityScore(_ rawText: String) -> Int {
        let lines = BusinessCardFieldParser.normalizedLines(in: rawText)
        guard !lines.isEmpty else { return 0 }
        let draft = BusinessCardFieldParser.parse(rawText)
        let structuredValues = [
            draft.name, draft.company, draft.jobTitle,
            draft.mobilePhone, draft.officePhone, draft.faxPhone,
            draft.email, draft.website, draft.address
        ].filter { !$0.isEmpty }.count
        let contactValues = [
            draft.mobilePhone, draft.officePhone, draft.faxPhone,
            draft.email, draft.website
        ].filter { !$0.isEmpty }.count
        let characterCount = min(lines.joined().count, 500)
        return structuredValues * 100 + contactValues * 80 + lines.count * 20 + characterCount
    }

    nonisolated private static func recognizeOrEmpty(_ imageData: Data) async -> String {
        (try? await VisionTextRecognizer.recognizeText(in: imageData)) ?? ""
    }

    nonisolated private static func result(
        imageData: Data,
        rawText: String,
        didApplyPerspectiveCorrection: Bool,
        selectedSource: CardRecognitionImageSource,
        originalRawText: String,
        correctedRawText: String
    ) -> BusinessCardRecognitionResult {
        BusinessCardRecognitionResult(
            imageData: imageData,
            rawText: rawText,
            draft: BusinessCardFieldParser.parse(rawText),
            didApplyPerspectiveCorrection: didApplyPerspectiveCorrection,
            selectedSource: selectedSource,
            originalRawText: originalRawText,
            correctedRawText: correctedRawText
        )
    }
}
