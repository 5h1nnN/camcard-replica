import XCTest

final class CamCardReplicaUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testStageZeroBaselineLaunchesInLightMode() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleInterfaceStyle", "Light"]
        app.launch()

        XCTAssertTrue(app.otherElements["stage0.root"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["CamCard Replica"].exists)
        XCTAssertTrue(app.staticTexts["工程基线已就绪"].exists)
    }
}
