import XCTest
@testable import Stock_Screener

class StockFormatterTests: XCTestCase {
    
    var formatter: StockFormatter!
    
    override func setUpWithError() throws {
        formatter = StockFormatter()
    }

    override func tearDownWithError() throws {
        formatter = nil
    }

    func testFormattedPrice() throws {
        let price = 99.00321
        let formattedPrice = formatter.formattedPrice(price)
        let result = "99,00"
        
        XCTAssertEqual(formattedPrice, result)
    }
    
    func testFormattedDelta() throws {
        let delta = -10.402134
        let formattedDelta = formatter.formattedDelta(delta)
        let result = "-10,40"
        
        XCTAssertEqual(formattedDelta, result)
    }
    
    func testFormattedPercentDelta() throws {
        let percentDelta = -0.38213
        let formattedDelta = formatter.formattedPercentDelta(percentDelta)
        let result = "38.21%"
        
        XCTAssertEqual(formattedDelta, result)
    }
    
    func testformattedDateFromUnixTimestamp() throws {
        let timestamp = 1621785595.00
        let time = formatter.formattedDateFromUnixTimestamp(timestamp)
        let result = "23 May 2021"
        
        XCTAssertEqual(time, result)
    }
}
