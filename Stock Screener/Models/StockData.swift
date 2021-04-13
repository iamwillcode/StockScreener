import Foundation

struct StockData: Codable {
    
    struct Ticker: Codable {
        let symbol: String
        let companyName: String
    }
    
    struct Price: Codable {
        let c, pc: Double?
    }
    
    struct Search: Codable {
        let count: Int?
        let result: [Result]?
        
        struct Result: Codable {
            let symbol: String
            let description: String
            let type: String
        }
    }
    
    struct ChartData: Codable {
        let h: [Double]?
    }
    
    struct News: Codable {
        let datetime: Int
        let headline: String
        let source: String
        let url: String
        let summary: String
    }
    
}







