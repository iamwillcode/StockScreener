import Foundation

struct StockData: Codable {
    
    let c, pc: Double?
    
    struct Ticker: Codable {
        let symbol: String
        let companyName: String
    }
}







