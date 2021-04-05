import Foundation

struct StockData: Codable {
    
    let c, pc: Double?
    
    let count: Int?
    let result: [Result]?
    
    struct Ticker: Codable {
        let symbol: String
        let companyName: String
    }
    
    struct Result: Codable {
        let symbol: String
        let description: String
        let type: String
    }
    
    struct ChartData: Codable {
        let h: [Double]?
    }
    
}







