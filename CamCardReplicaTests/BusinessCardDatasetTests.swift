import Foundation
import XCTest
@testable import CamCardReplica

@MainActor
final class BusinessCardDatasetTests: XCTestCase {
    private static let testedFields: [FieldKey] = [
        .name, .company, .jobTitle, .mobilePhone, .officePhone,
        .faxPhone, .email, .website, .address
    ]

    func testThirtyCardDatasetOCRBenchmark() async throws {
        let datasetRoot = try datasetRootURL()
        let manifestData = try Data(contentsOf: datasetRoot.appendingPathComponent("ground_truth.json"))
        let manifest = try JSONDecoder().decode(DatasetManifest.self, from: manifestData)
        XCTAssertEqual(manifest.records.count, 30, "The benchmark must use the complete 30-card dataset.")

        var caseResults: [CaseResult] = []
        let benchmarkStart = CFAbsoluteTimeGetCurrent()

        for record in manifest.records {
            let start = CFAbsoluteTimeGetCurrent()
            let imageURL = datasetRoot.appendingPathComponent(record.image)
            let imageData = try Data(contentsOf: imageURL)
            var rawText = ""
            var draft = BusinessCardDraft.empty
            var didCorrectPerspective = false
            var selectedSource = CardRecognitionImageSource.original.rawValue
            var originalRawText = ""
            var correctedRawText = ""
            let failure: String? = nil

            let recognition = await BusinessCardRecognitionPipeline.process(imageData)
            didCorrectPerspective = recognition.didApplyPerspectiveCorrection
            selectedSource = recognition.selectedSource.rawValue
            originalRawText = recognition.originalRawText
            correctedRawText = recognition.correctedRawText
            rawText = recognition.rawText
            draft = recognition.draft

            let comparisons = Dictionary(uniqueKeysWithValues: Self.testedFields.map { key in
                let expected = record.fields.value(for: key)
                let actual = draft.value(for: key)
                return (
                    key.rawValue,
                    FieldComparison(
                        expected: expected,
                        actual: actual,
                        matched: normalized(expected, for: key) == normalized(actual, for: key),
                        ocrContainsExpected: expected.isEmpty
                            ? nil
                            : normalized(rawText, for: key).contains(normalized(expected, for: key))
                    )
                )
            })
            let result = CaseResult(
                id: record.id,
                language: record.language,
                difficulty: record.difficulty,
                scenario: record.scenario,
                recognizedText: rawText,
                originalRecognizedText: originalRawText,
                correctedRecognizedText: correctedRawText,
                recognitionSucceeded: !BusinessCardFieldParser.normalizedLines(in: rawText).isEmpty,
                didCorrectPerspective: didCorrectPerspective,
                selectedSource: selectedSource,
                durationMilliseconds: Int((CFAbsoluteTimeGetCurrent() - start) * 1_000),
                error: failure,
                fields: comparisons
            )
            caseResults.append(result)
            print(
                "[DATASET_CASE] \(record.id) \(record.scenario) " +
                "OCR=\(result.recognitionSucceeded ? "yes" : "no") " +
                "populated=\(metrics(for: [result]).populatedFieldAccuracy.formatted(.percent.precision(.fractionLength(1))))"
            )
        }

        let report = BenchmarkReport(
            datasetName: manifest.dataset.name,
            datasetVersion: manifest.dataset.version,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            totalDurationMilliseconds: Int((CFAbsoluteTimeGetCurrent() - benchmarkStart) * 1_000),
            summary: summary(for: caseResults),
            byLanguage: groupedMetrics(caseResults, key: \CaseResult.language),
            byDifficulty: groupedMetrics(caseResults, key: \CaseResult.difficulty),
            byField: fieldMetrics(caseResults),
            cases: caseResults
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let reportData = try encoder.encode(report)
        let reportText = try XCTUnwrap(String(data: reportData, encoding: .utf8))
        let attachment = XCTAttachment(data: reportData, uniformTypeIdentifier: "public.json")
        attachment.name = "business-card-dataset-benchmark.json"
        attachment.lifetime = .keepAlways
        add(attachment)

        print("CAMCARD_DATASET_REPORT_BEGIN")
        print(reportText)
        print("CAMCARD_DATASET_REPORT_END")

        XCTAssertEqual(caseResults.count, manifest.records.count)
        XCTAssertTrue(caseResults.allSatisfy { $0.error == nil }, "Every dataset image must complete the app pipeline without throwing.")
    }

    private func datasetRootURL() throws -> URL {
        let bundle = Bundle(for: Self.self)
        let candidates = [
            bundle.resourceURL?.appendingPathComponent("BusinessCardDataset", isDirectory: true),
            bundle.url(forResource: "BusinessCardDataset", withExtension: nil)
        ].compactMap { $0 }
        for candidate in candidates where FileManager.default.fileExists(
            atPath: candidate.appendingPathComponent("ground_truth.json").path
        ) {
            return candidate
        }
        throw DatasetBenchmarkError.missingResource
    }

    private func summary(for results: [CaseResult]) -> BenchmarkSummary {
        let aggregate = metrics(for: results)
        return BenchmarkSummary(
            cases: results.count,
            recognitionSucceeded: results.filter(\.recognitionSucceeded).count,
            perspectiveCorrected: results.filter(\.didCorrectPerspective).count,
            pipelineFailures: results.filter { $0.error != nil }.count,
            metrics: aggregate
        )
    }

    private func groupedMetrics(
        _ results: [CaseResult],
        key: KeyPath<CaseResult, String>
    ) -> [String: BenchmarkMetrics] {
        Dictionary(grouping: results, by: { $0[keyPath: key] })
            .mapValues(metrics)
    }

    private func fieldMetrics(_ results: [CaseResult]) -> [String: BenchmarkMetrics] {
        Dictionary(uniqueKeysWithValues: Self.testedFields.map { key in
            let projected = results.map { result -> CaseResult in
                var copy = result
                copy.fields = [key.rawValue: result.fields[key.rawValue]!]
                return copy
            }
            return (key.rawValue, metrics(for: projected))
        })
    }

    private func metrics(for results: [CaseResult]) -> BenchmarkMetrics {
        let comparisons = results.flatMap { $0.fields.values }
        let populated = comparisons.filter { !$0.expected.isEmpty }
        let empty = comparisons.filter(\.expected.isEmpty)
        let ocrMeasured = comparisons.compactMap(\.ocrContainsExpected)
        return BenchmarkMetrics(
            cases: results.count,
            allFieldCorrect: comparisons.filter(\.matched).count,
            allFieldTotal: comparisons.count,
            allFieldAccuracy: ratio(comparisons.filter(\.matched).count, comparisons.count),
            populatedFieldCorrect: populated.filter(\.matched).count,
            populatedFieldTotal: populated.count,
            populatedFieldAccuracy: ratio(populated.filter(\.matched).count, populated.count),
            emptyFieldCorrect: empty.filter(\.matched).count,
            emptyFieldTotal: empty.count,
            emptyFieldAccuracy: ratio(empty.filter(\.matched).count, empty.count),
            ocrValueRecovered: ocrMeasured.filter { $0 }.count,
            ocrValueTotal: ocrMeasured.count,
            ocrValueRecall: ratio(ocrMeasured.filter { $0 }.count, ocrMeasured.count)
        )
    }

    private func ratio(_ numerator: Int, _ denominator: Int) -> Double {
        denominator == 0 ? 1 : Double(numerator) / Double(denominator)
    }

    private func normalized(_ value: String, for key: FieldKey) -> String {
        let folded = value.folding(
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
        switch key {
        case .mobilePhone, .officePhone, .faxPhone:
            return String(folded.unicodeScalars.filter(CharacterSet.decimalDigits.contains))
        case .email:
            return folded.filter { !$0.isWhitespace }
        case .website:
            return folded
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: " /.,;，；"))
                .filter { !$0.isWhitespace }
        default:
            return String(folded.unicodeScalars.filter(CharacterSet.alphanumerics.contains))
        }
    }
}

private enum DatasetBenchmarkError: LocalizedError {
    case missingResource

    var errorDescription: String? {
        "BusinessCardDataset was not copied into the CamCardReplicaTests bundle."
    }
}

private enum FieldKey: String, CaseIterable {
    case name
    case company
    case jobTitle
    case mobilePhone
    case officePhone
    case faxPhone
    case email
    case website
    case address
}

private struct DatasetManifest: Decodable {
    let dataset: DatasetMetadata
    let records: [DatasetRecord]
}

private struct DatasetMetadata: Decodable {
    let name: String
    let version: String
}

private struct DatasetRecord: Decodable {
    let id: String
    let image: String
    let language: String
    let difficulty: String
    let scenario: String
    let fields: ExpectedFields
}

private struct ExpectedFields: Decodable {
    let name: String
    let company: String
    let jobTitle: String
    let mobilePhone: String
    let officePhone: String
    let faxPhone: String
    let email: String
    let website: String
    let address: String

    func value(for key: FieldKey) -> String {
        switch key {
        case .name: name
        case .company: company
        case .jobTitle: jobTitle
        case .mobilePhone: mobilePhone
        case .officePhone: officePhone
        case .faxPhone: faxPhone
        case .email: email
        case .website: website
        case .address: address
        }
    }
}

private extension BusinessCardDraft {
    func value(for key: FieldKey) -> String {
        switch key {
        case .name: name
        case .company: company
        case .jobTitle: jobTitle
        case .mobilePhone: mobilePhone
        case .officePhone: officePhone
        case .faxPhone: faxPhone
        case .email: email
        case .website: website
        case .address: address
        }
    }
}

private struct FieldComparison: Encodable {
    let expected: String
    let actual: String
    let matched: Bool
    let ocrContainsExpected: Bool?
}

private struct CaseResult: Encodable {
    let id: String
    let language: String
    let difficulty: String
    let scenario: String
    let recognizedText: String
    let originalRecognizedText: String
    let correctedRecognizedText: String
    let recognitionSucceeded: Bool
    let didCorrectPerspective: Bool
    let selectedSource: String
    let durationMilliseconds: Int
    let error: String?
    var fields: [String: FieldComparison]
}

private struct BenchmarkMetrics: Encodable {
    let cases: Int
    let allFieldCorrect: Int
    let allFieldTotal: Int
    let allFieldAccuracy: Double
    let populatedFieldCorrect: Int
    let populatedFieldTotal: Int
    let populatedFieldAccuracy: Double
    let emptyFieldCorrect: Int
    let emptyFieldTotal: Int
    let emptyFieldAccuracy: Double
    let ocrValueRecovered: Int
    let ocrValueTotal: Int
    let ocrValueRecall: Double
}

private struct BenchmarkSummary: Encodable {
    let cases: Int
    let recognitionSucceeded: Int
    let perspectiveCorrected: Int
    let pipelineFailures: Int
    let metrics: BenchmarkMetrics
}

private struct BenchmarkReport: Encodable {
    let datasetName: String
    let datasetVersion: String
    let generatedAt: String
    let totalDurationMilliseconds: Int
    let summary: BenchmarkSummary
    let byLanguage: [String: BenchmarkMetrics]
    let byDifficulty: [String: BenchmarkMetrics]
    let byField: [String: BenchmarkMetrics]
    let cases: [CaseResult]
}
