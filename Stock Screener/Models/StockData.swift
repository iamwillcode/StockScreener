import Foundation

/// Use to serialize JSON
struct StockData: Codable {
    
    struct Ticker: Codable {
        let symbol: String
        let companyName: String
    }
    
    struct Price: Codable {
        let c, pc: Double? // swiftlint:disable:this identifier_name
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
        let c: [Double]? // swiftlint:disable:this identifier_name
        let t: [Double]? // swiftlint:disable:this identifier_name
    }
    
    struct News: Codable {
        let datetime: Int
        let headline: String
        let source: String
        let url: String
        let summary: String
    }
}
