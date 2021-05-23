import XCTest

// UI Test examples
class StockScreenerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testSegmentSwitch() throws {
        let app = XCUIApplication()
        app.launch()
        
        let trendingTable = app.tables
        
        app.buttons["Favourite"].tap()
        
        let favouriteTable = app.tables
        
        XCTAssert(trendingTable != favouriteTable)
    }
    
    func testSearchBar() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.searchFields["Ticker or company name"].tap()
        app.searchFields["Ticker or company name"].typeText("AAPL")
        
        XCTAssert(app.searchFields["Ticker or company name"].value as? String == "AAPL")
        
        app.searchFields["Ticker or company name"].buttons["Clear text"].tap()
        
        XCTAssert(app.searchFields["Ticker or company name"].value as? String == "Ticker or company name")
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
