import XCTest

final class CollapseLaunchTests: XCTestCase {
    func testRepeatedColdLaunchStaysForeground() {
        let app = XCUIApplication()
        for _ in 0..<3 {
            app.launch()
            XCTAssertEqual(app.state, .runningForeground)
            app.terminate()
        }
    }
}
