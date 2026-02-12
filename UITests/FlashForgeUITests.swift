import XCTest

final class FlashForgeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("UITEST_SKIP_ONBOARDING")
        app.launch()
    }

    @MainActor
    func testTabsAreVisibleAndNavigable() {
        let studyTab = app.tabBars.buttons["tab.study"]
        let decksTab = app.tabBars.buttons["tab.decks"]
        let moreTab = app.tabBars.buttons["tab.more"]

        XCTAssertTrue(studyTab.waitForExistence(timeout: 5))
        XCTAssertTrue(decksTab.exists)
        XCTAssertTrue(moreTab.exists)

        studyTab.tap()
        XCTAssertTrue(app.buttons["home.deckButton"].waitForExistence(timeout: 3))

        decksTab.tap()
        XCTAssertTrue(app.navigationBars.buttons["decks.addButton"].waitForExistence(timeout: 3))

        moreTab.tap()
        XCTAssertTrue(app.buttons["more.backupButton"].waitForExistence(timeout: 3))
    }
}
