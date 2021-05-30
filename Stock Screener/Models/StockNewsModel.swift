import Foundation
import TimestampFormatter

struct StockNewsModel {
    
    let headline: String
    let source: String
    let url: String
    let timestamp: Int
    let summary: String
    
    // Convert news timestamp to readable format
    var age: String {
        let currentTimestamp = Int(Date().timeIntervalSince1970)
        let timestampInSeconds = timestamp / 1000
        let timeDifference = currentTimestamp - timestampInSeconds
        let formattedTime = TimestampFormatter.formatToCompactString(timestamp: timeDifference)
        return formattedTime
    }
}
