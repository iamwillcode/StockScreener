import Foundation

struct StockNewsModel {
    
    let headline: String
    let source: String
    let url: String
    let timestamp: Int
    let summary: String
    
    var age: String {
        let currentTimestamp = Int(Date().timeIntervalSince1970)
        let timestampInSeconds = timestamp / 1000
        let timeDifference = currentTimestamp - timestampInSeconds
        
        switch timeDifference {
        case 0..<60:
            return "\(timeDifference)s"
        case 0..<3600:
            let minutes = timeDifference / 60
            return "\(minutes)min"
        case 0..<86400:
            let hours = timeDifference / 3600
            return "\(hours)h"
        case 0..<2592000:
            let days = timeDifference / 86400
            return "\(days)d"
        case 0..<31536000:
            let months = timeDifference / 2592000
            return "\(months)m"
        case 31536000...:
            let years = timeDifference / 31536000
            return "\(years)y"
        default:
            return "some time"
        }
    }
    
}
