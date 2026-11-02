import XCTest
import SwiftData
import UIKit
@testable import CamCardReplica

@MainActor
final class CamCardReplicaTests: XCTestCase {
    func testNavigationStartsAtLaunchWithHomeSelectedAndIdleCaptureFlow() {
        let navigation = AppNavigationModel()

        XCTAssertEqual(navigation.stage, .launch)
        XCTAssertEqual(navigation.selectedTab, .home)
        XCTAssertTrue(navigation.path.isEmpty)
        XCTAssertEqual(navigation.captureState, .idle)
    }

    func testNavigationCanReturnToRootAndResetCapture() {
        let navigation = AppNavigationModel()
        navigation.push(.capture)
        navigation.captureState = .recognizing

        navigation.popToRoot()
        navigation.resetCapture()

        XCTAssertTrue(navigation.path.isEmpty)
        XCTAssertEqual(navigation.captureState, .idle)
    }

    func testEnteringMainAppResetsRouteAndSelectsHome() {
        let navigation = AppNavigationModel(initialStage: .login)
        navigation.selectedTab = .profile
        navigation.push(.capture)

        navigation.enterMainApp()

        XCTAssertEqual(navigation.stage, .main)
        XCTAssertEqual(navigation.selectedTab, .home)
        XCTAssertTrue(navigation.path.isEmpty)
    }

    func testPlaceholderActionHasStableIdentityAndSource() {
        let navigation = AppNavigationModel(initialStage: .main)

        navigation.showPlaceholder(
            id: "home.vip",
            title: "VIP 服务",
            source: "首页",
            symbol: "diamond.fill"
        )

        XCTAssertEqual(navigation.placeholderAction?.id, "home.vip")
        XCTAssertEqual(navigation.placeholderAction?.source, "首页")
        XCTAssertEqual(navigation.placeholderAction?.symbol, "diamond.fill")
    }

    func testSyntheticFixtureUsesReservedExampleDomain() {
        let fixture = FixtureCatalog.syntheticBusinessCard

        XCTAssertTrue(fixture.email.hasSuffix("@example.com"))
        XCTAssertEqual(fixture.assetName, "SyntheticBusinessCard")
        XCTAssertTrue(fixture.rawText.contains(fixture.company))
    }

    func testChineseCardParsingKeepsMissingWebsiteEmpty() {
        let draft = BusinessCardFieldParser.parse(
            """
            林晓
            星河科技有限公司
            产品经理
            手机：138 1234 5678
            邮箱：lin.xiao@example.com
            上海市浦东新区创新路 88 号
            """
        )

        XCTAssertEqual(draft.name, "林晓")
        XCTAssertEqual(draft.company, "星河科技有限公司")
        XCTAssertEqual(draft.jobTitle, "产品经理")
        XCTAssertEqual(draft.mobilePhone, "138 1234 5678")
        XCTAssertEqual(draft.email, "lin.xiao@example.com")
        XCTAssertEqual(draft.address, "上海市浦东新区创新路 88 号")
        XCTAssertTrue(draft.website.isEmpty)
    }

    func testEnglishCardParsingExtractsOnlyVisibleValues() {
        let draft = BusinessCardFieldParser.parse(
            """
            Avery Stone
            Product Designer
            Northwind Studio
            +1 415 555 0198
            avery@example.com
            https://www.example.com/avery
            88 Innovation Road, Seattle
            """
        )

        XCTAssertEqual(draft.name, "Avery Stone")
        XCTAssertEqual(draft.company, "Northwind Studio")
        XCTAssertEqual(draft.jobTitle, "Product Designer")
        XCTAssertEqual(draft.mobilePhone, "+1 415 555 0198")
        XCTAssertEqual(draft.email, "avery@example.com")
        XCTAssertEqual(draft.website, "https://www.example.com/avery")
        XCTAssertEqual(draft.address, "88 Innovation Road, Seattle")
    }

    func testRecognizedTextIsSortedByRowsThenColumns() {
        let lines = [
            RecognizedTextLine(text: "right", boundingBox: CGRect(x: 0.6, y: 0.8, width: 0.2, height: 0.1)),
            RecognizedTextLine(text: "bottom", boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.1)),
            RecognizedTextLine(text: "left", boundingBox: CGRect(x: 0.1, y: 0.81, width: 0.2, height: 0.1))
        ]

        XCTAssertEqual(RecognizedTextReadingOrder.sorted(lines).map(\.text), ["left", "right", "bottom"])
    }

    func testVisionRecognizesEnglishSyntheticCard() async throws {
        let imageData = makeTextImage(
            lines: ["AVERY STONE", "NORTHWIND STUDIO", "avery@example.com", "+1 415 555 0198"]
        )

        let rawText = try await VisionTextRecognizer.recognizeText(in: imageData)

        XCTAssertFalse(rawText.isEmpty)
        XCTAssertTrue(rawText.localizedCaseInsensitiveContains("AVERY"))
        XCTAssertTrue(rawText.localizedCaseInsensitiveContains("example.com"))
    }

    func testVisionRecognizesChineseSyntheticCard() async throws {
        let imageData = makeTextImage(
            lines: ["林晓", "星河科技有限公司", "产品经理", "138 1234 5678"],
            fontName: "PingFangSC-Semibold"
        )

        let rawText = try await VisionTextRecognizer.recognizeText(in: imageData)

        XCTAssertFalse(rawText.isEmpty)
        XCTAssertTrue(rawText.contains("138") || rawText.contains("林晓") || rawText.contains("星河"))
    }

    func testVisionReturnsEmptyTextForBlankImage() async throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1000, height: 600))
        let data = renderer.pngData { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1000, height: 600))
        }

        let rawText = try await VisionTextRecognizer.recognizeText(in: data)

        XCTAssertTrue(rawText.isEmpty)
    }

    func testManualEntryPreservesImageAndStartsWithEmptyDraft() {
        let imageData = Data([0x01, 0x02, 0x03])
        let session = CardImportSession(imageData: imageData)
        session.continueWithManualEntry()

        XCTAssertTrue(session.isManualEntry)
        XCTAssertEqual(session.state, .ready)
        XCTAssertEqual(session.draft, .empty)
        XCTAssertEqual(session.imageData, imageData)
    }

    func testStartingAndCancellingSelectionDoesNotDestroyExistingDraft() {
        let session = CardImportSession(draft: .fixture)

        session.beginNewImport()

        XCTAssertEqual(session.draft, .fixture)
        XCTAssertEqual(session.state, .idle)
    }

    func testImageStoreSavesLoadsAndDeletesOnlyRelativeCardPaths() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = CardImageStore(baseDirectory: directory)
        let imageData = makeTextImage(lines: ["IMAGE"])

        let relativePath = try store.save(imageData, for: UUID())

        XCTAssertTrue(relativePath.hasPrefix("CardImages/"))
        XCTAssertEqual(try store.load(relativePath: relativePath), imageData)
        XCTAssertThrowsError(try store.load(relativePath: "../outside.png"))

        try store.delete(relativePath: relativePath)
        XCTAssertNil(try store.load(relativePath: relativePath))
    }

    func testPersistenceCreatesUpdatesSearchesAndDeletesCardWithImage() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let imageStore = CardImageStore(baseDirectory: directory)
        let container = try ModelContainer(
            for: BusinessCard.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let imageData = makeTextImage(lines: ["PERSISTED CARD"])
        let created = try BusinessCardPersistence.save(
            draft: .fixture,
            imageData: imageData,
            editingCardID: nil,
            in: context,
            imageStore: imageStore,
            now: Date(timeIntervalSince1970: 100)
        )

        XCTAssertEqual(try context.fetch(FetchDescriptor<BusinessCard>()).count, 1)
        XCTAssertEqual(try imageStore.load(relativePath: created.originalImagePath), imageData)
        XCTAssertTrue(created.matches("远山"))
        XCTAssertTrue(created.matches("demo@example"))
        XCTAssertFalse(created.matches("不存在的字段"))

        var editedDraft = created.draft
        editedDraft.name = "已编辑姓名"
        editedDraft.notes = "课程作业备注"
        let updated = try BusinessCardPersistence.save(
            draft: editedDraft,
            imageData: imageData,
            editingCardID: created.id,
            in: context,
            imageStore: imageStore,
            now: Date(timeIntervalSince1970: 200)
        )

        XCTAssertEqual(try context.fetch(FetchDescriptor<BusinessCard>()).count, 1)
        XCTAssertEqual(updated.name, "已编辑姓名")
        XCTAssertEqual(updated.notes, "课程作业备注")
        XCTAssertEqual(updated.updatedAt, Date(timeIntervalSince1970: 200))

        let savedPath = updated.originalImagePath
        try BusinessCardPersistence.delete(updated, in: context, imageStore: imageStore)

        XCTAssertTrue(try context.fetch(FetchDescriptor<BusinessCard>()).isEmpty)
        XCTAssertNil(try imageStore.load(relativePath: savedPath))
    }

    func testSwiftDataRecordSurvivesContainerRecreation() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let databaseURL = directory.appendingPathComponent("restart.store")
        let schema = Schema([BusinessCard.self])
        let configuration = ModelConfiguration(
            "RestartTest",
            schema: schema,
            url: databaseURL,
            cloudKitDatabase: .none
        )
        let expectedID: UUID

        do {
            let firstContainer = try ModelContainer(for: schema, configurations: configuration)
            let firstContext = ModelContext(firstContainer)
            let card = BusinessCard(draft: .fixture)
            expectedID = card.id
            firstContext.insert(card)
            try firstContext.save()
        }

        do {
            let secondConfiguration = ModelConfiguration(
                "RestartTest",
                schema: schema,
                url: databaseURL,
                cloudKitDatabase: .none
            )
            let secondContainer = try ModelContainer(for: schema, configurations: secondConfiguration)
            let secondContext = ModelContext(secondContainer)
            let restoredCards = try secondContext.fetch(FetchDescriptor<BusinessCard>())

            XCTAssertEqual(restoredCards.count, 1)
            XCTAssertEqual(restoredCards.first?.id, expectedID)
            XCTAssertEqual(restoredCards.first?.email, FixtureCatalog.syntheticBusinessCard.email)
        }
    }

    private func makeTextImage(lines: [String], fontName: String = "HelveticaNeue-Bold") -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1400, height: 800))
        return renderer.pngData { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1400, height: 800))

            let font = UIFont(name: fontName, size: 64) ?? UIFont.systemFont(ofSize: 64, weight: .bold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black
            ]
            for (index, line) in lines.enumerated() {
                NSString(string: line).draw(
                    at: CGPoint(x: 90, y: 80 + CGFloat(index) * 145),
                    withAttributes: attributes
                )
            }
        }
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("CamCardReplicaTests-\(UUID().uuidString)", isDirectory: true)
    }
}
