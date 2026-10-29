import XCTest

final class CamCardReplicaUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITesting", "-AppleInterfaceStyle", "Light"]
        app.launch()
    }

    func testLocalLoginAndMainTabs() {
        XCTAssertTrue(element("screen.login").waitForExistence(timeout: 5))

        app.buttons["core.login.submit"].tap()
        XCTAssertTrue(app.alerts["请先同意协议"].waitForExistence(timeout: 2))
        app.alerts.buttons["知道了"].tap()

        login()
        XCTAssertTrue(element("screen.home").waitForExistence(timeout: 5))

        app.buttons["core.tab.cards"].tap()
        XCTAssertTrue(element("screen.cards").waitForExistence(timeout: 2))

        app.buttons["core.tab.enterprise"].tap()
        XCTAssertTrue(element("screen.enterprise").waitForExistence(timeout: 2))

        app.buttons["core.tab.profile"].tap()
        XCTAssertTrue(element("screen.profile").waitForExistence(timeout: 2))

        app.buttons["core.tab.home"].tap()
        XCTAssertTrue(element("screen.home").waitForExistence(timeout: 2))
    }

    func testCaptureReviewResultAndDetailFlow() {
        login()

        app.buttons["core.tab.capture"].tap()
        XCTAssertTrue(element("screen.capture").waitForExistence(timeout: 3))

        app.buttons["core.capture.shutter"].tap()
        XCTAssertTrue(element("screen.review").waitForExistence(timeout: 3))

        app.buttons["core.review.save"].tap()
        XCTAssertTrue(element("screen.result").waitForExistence(timeout: 3))

        app.buttons["core.result.detail"].tap()
        XCTAssertTrue(element("screen.detail").waitForExistence(timeout: 3))
    }

    func testPlaceholderFeedbackCanBeClosed() {
        login()

        app.buttons["placeholder.home.messages"].tap()
        XCTAssertTrue(element("placeholder.sheet").waitForExistence(timeout: 3))

        app.buttons["placeholder.close"].tap()
        XCTAssertFalse(element("placeholder.sheet").waitForExistence(timeout: 1))
    }

    private func login() {
        XCTAssertTrue(element("screen.login").waitForExistence(timeout: 5))
        app.buttons["core.login.agreement"].tap()
        app.buttons["core.login.submit"].tap()
        XCTAssertTrue(element("main.shell").waitForExistence(timeout: 5))
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
