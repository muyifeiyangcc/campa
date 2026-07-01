import XCTest

final class CampaUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunches() throws {
        let app = XCUIApplication()

        app.launch()

        XCTAssertTrue(app.staticTexts["Campa"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Login by email"].exists)
    }

    func testLoginByEmailRequiresAgreementSelection() throws {
        let app = XCUIApplication()

        app.launch()
        app.buttons["Login by email"].tap()

        XCTAssertTrue(app.staticTexts["Please agree first"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Sign in"].exists)
    }

    func testLoginByEmailOpensLoginScreenAfterAgreementSelection() throws {
        let app = XCUIApplication()

        app.launch()
        app.buttons["agreementButton"].tap()
        app.buttons["Login by email"].tap()

        XCTAssertTrue(app.staticTexts["Sign in"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Login"].exists)
    }
}
