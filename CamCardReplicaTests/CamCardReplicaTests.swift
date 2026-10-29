import XCTest
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
}
