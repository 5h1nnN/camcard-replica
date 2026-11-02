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

    func testEmptySearchKeyboardAndCardsTabStateAreStable() {
        login()
        app.buttons["core.tab.cards"].tap()

        XCTAssertTrue(element("screen.cards").waitForExistence(timeout: 3))
        XCTAssertTrue(element("core.cards.empty").waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["core.cards.demoDetail"].exists)

        let search = app.textFields["core.cards.search"]
        search.tap()
        search.typeText("不存在的名片")
        XCTAssertTrue(element("core.cards.noSearchResults").waitForExistence(timeout: 2))
        search.typeText("\n")
        XCTAssertFalse(app.keyboards.firstMatch.waitForExistence(timeout: 1))

        app.buttons["core.cards.clearSearch"].tap()
        app.buttons["core.cards.add"].tap()
        XCTAssertTrue(element("screen.capture").waitForExistence(timeout: 3))
        app.buttons["core.capture.close"].tap()

        XCTAssertTrue(element("screen.cards").waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons["core.tab.cards"].value as? String, "已选中")

        app.buttons["core.cards.groups"].tap()
        XCTAssertTrue(element("screen.groups").waitForExistence(timeout: 2))
        app.buttons["core.groups.back"].tap()
        XCTAssertTrue(element("screen.cards").exists)
        XCTAssertEqual(app.buttons["core.tab.cards"].value as? String, "已选中")
    }

    func testSavedCardCanBeAssignedToACreatedGroupAndOpenedFromIt() {
        login()
        app.buttons["core.tab.capture"].tap()
        XCTAssertTrue(element("screen.capture").waitForExistence(timeout: 3))
        app.buttons["core.capture.shutter"].tap()
        XCTAssertTrue(element("screen.review").waitForExistence(timeout: 3))
        app.buttons["core.review.save"].tap()
        XCTAssertTrue(element("screen.result").waitForExistence(timeout: 5))

        app.buttons["core.result.group"].tap()
        XCTAssertTrue(element("screen.groupAssignment").waitForExistence(timeout: 3))
        app.buttons["core.groupAssignment.new"].tap()
        let nameField = app.alerts["新建分组"].textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.typeText("课程同学")
        app.alerts["新建分组"].buttons.matching(identifier: "core.groupAssignment.create").firstMatch.tap()
        app.buttons["core.groupAssignment.done"].tap()
        XCTAssertTrue(element("screen.result").waitForExistence(timeout: 3))

        app.buttons["core.result.returnCards"].tap()
        XCTAssertTrue(element("screen.cards").waitForExistence(timeout: 3))
        app.buttons["core.cards.groups"].tap()
        XCTAssertTrue(element("screen.groups").waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["课程同学(1)"].waitForExistence(timeout: 2))
        app.staticTexts["课程同学(1)"].tap()
        XCTAssertTrue(element("screen.groupCards").waitForExistence(timeout: 3))
        XCTAssertTrue(groupedCardButton.waitForExistence(timeout: 2))
        groupedCardButton.tap()
        XCTAssertTrue(element("screen.detail").waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["课程同学"].waitForExistence(timeout: 2))

        let groupRow = element("core.detail.group")
        XCTAssertTrue(groupRow.waitForExistence(timeout: 2))
        groupRow.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        XCTAssertTrue(element("screen.groupAssignment").waitForExistence(timeout: 3))
    }

    func testSavedCardCanCreateAndThenUpdateASystemContact() {
        login()
        app.buttons["core.tab.capture"].tap()
        XCTAssertTrue(element("screen.capture").waitForExistence(timeout: 3))
        app.buttons["core.capture.shutter"].tap()
        XCTAssertTrue(element("screen.review").waitForExistence(timeout: 3))
        app.buttons["core.review.save"].tap()
        XCTAssertTrue(element("screen.result").waitForExistence(timeout: 5))

        app.buttons["core.result.contacts"].tap()
        let createdAlert = app.alerts["已存入系统通讯录"]
        XCTAssertTrue(createdAlert.waitForExistence(timeout: 3))
        createdAlert.buttons.matching(identifier: "完成").firstMatch.tap()

        app.buttons["core.result.detail"].tap()
        XCTAssertTrue(element("screen.detail").waitForExistence(timeout: 3))
        app.buttons["core.detail.contacts"].tap()
        let updatedAlert = app.alerts["已更新系统通讯录"]
        XCTAssertTrue(updatedAlert.waitForExistence(timeout: 3))
        updatedAlert.buttons.matching(identifier: "完成").firstMatch.tap()
        XCTAssertTrue(element("screen.detail").exists)
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
        XCTAssertFalse(app.buttons["core.cards.demoDetail"].exists)
        XCTAssertTrue(app.staticTexts["产品设计师"].exists)
        XCTAssertFalse(app.staticTexts["+86 138 0000 0000"].exists)

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

    private var groupedCardButton: XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'core.groupCards.card.'")
        ).firstMatch
    }
}
