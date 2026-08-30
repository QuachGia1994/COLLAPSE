import XCTest

@MainActor
final class CollapseLaunchTests: XCTestCase {
    func testRepeatedColdLaunchStaysForeground() {
        let app = XCUIApplication()
        for _ in 0..<3 {
            app.launch()
            XCTAssertEqual(app.state, .runningForeground)
            app.terminate()
        }
    }

    func testFirstRunTutorialRendersMechanicAndNavigation() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.otherElements["tutorial.board"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tutorial.next"].exists)
        XCTAssertTrue(app.buttons["tutorial.close"].exists)
    }
}