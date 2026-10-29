import XCTest
@testable import CamCardReplica

@MainActor
final class CamCardReplicaTests: XCTestCase {
    func testNavigationStartsAtHomeWithIdleCaptureFlow() {
        let navigation = AppNavigationModel()

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

    func testSyntheticFixtureUsesReservedExampleDomain() {
        let fixture = FixtureCatalog.syntheticBusinessCard

        XCTAssertTrue(fixture.email.hasSuffix("@example.com"))
        XCTAssertEqual(fixture.assetName, "SyntheticBusinessCard")
        XCTAssertTrue(fixture.rawText.contains(fixture.company))
    }
}
