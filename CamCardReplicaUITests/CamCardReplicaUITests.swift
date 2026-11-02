import XCTest

final class CamCardReplicaUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITesting", "-ResetUITestStore", "-AppleInterfaceStyle", "Light"]
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

    func testSavedCardPersistsCanBeSearchedEditedAndDeleted() {
        login()
        app.buttons["core.tab.capture"].tap()
        XCTAssertTrue(element("screen.capture").waitForExistence(timeout: 3))
        app.buttons["core.capture.shutter"].tap()
        XCTAssertTrue(element("screen.review").waitForExistence(timeout: 3))
        app.buttons["core.review.save"].tap()
        XCTAssertTrue(element("screen.result").waitForExistence(timeout: 5))
        app.buttons["core.result.returnCards"].tap()
        XCTAssertTrue(element("screen.cards").waitForExistence(timeout: 3))
        XCTAssertTrue(savedCardButton.waitForExistence(timeout: 3))

        app.terminate()
        app.launchArguments = ["-UITesting", "-AppleInterfaceStyle", "Light"]
        app.launch()
        login()
        app.buttons["core.tab.cards"].tap()
        XCTAssertTrue(element("screen.cards").waitForExistence(timeout: 3))

        let search = app.textFields["core.cards.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 2))
        search.tap()
        search.typeText("demo@example.com")
        XCTAssertTrue(savedCardButton.waitForExistence(timeout: 3))
        savedCardButton.tap()
        XCTAssertTrue(element("screen.detail").waitForExistence(timeout: 3))

        app.buttons["core.detail.edit"].tap()
        XCTAssertTrue(element("screen.review").waitForExistence(timeout: 3))
        let nameField = app.textFields["core.review.field.姓名"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText(" 已编辑")
        app.buttons["core.review.save"].tap()
        XCTAssertTrue(element("screen.result").waitForExistence(timeout: 5))
        app.buttons["core.result.returnCards"].tap()
        XCTAssertTrue(element("screen.cards").waitForExistence(timeout: 3))

        app.buttons["core.cards.clearSearch"].tap()
        let editedSearch = app.textFields["core.cards.search"]
        editedSearch.tap()
        editedSearch.typeText("已编辑")
        XCTAssertTrue(savedCardButton.waitForExistence(timeout: 3))
        savedCardButton.tap()
        XCTAssertTrue(element("screen.detail").waitForExistence(timeout: 3))

        app.buttons["core.detail.moreMenu"].tap()
        XCTAssertTrue(app.buttons["删除名片"].waitForExistence(timeout: 2))
        app.buttons["删除名片"].tap()
        XCTAssertTrue(element("screen.cards").waitForExistence(timeout: 3))
        XCTAssertFalse(savedCardButton.exists)
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

    private var savedCardButton: XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'core.cards.savedCard.'")
        ).firstMatch
    }
}
