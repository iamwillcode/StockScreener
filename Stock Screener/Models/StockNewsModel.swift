import Foundation

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
        
        switch timeDifference {
        case 0..<K.TimeInSeconds.minute:
            return "\(timeDifference)s"
        case 0..<K.TimeInSeconds.hour:
            let minutes = timeDifference / K.TimeInSeconds.minute
            return "\(minutes)min"
        case 0..<K.TimeInSeconds.day:
            let hours = timeDifference / K.TimeInSeconds.hour
            return "\(hours)h"
        case 0..<K.TimeInSeconds.month:
            let days = timeDifference / K.TimeInSeconds.day
            return "\(days)d"
        case 0..<K.TimeInSeconds.year:
            let months = timeDifference / K.TimeInSeconds.month
            return "\(months)m"
        case K.TimeInSeconds.year...:
            let years = timeDifference / K.TimeInSeconds.year
            return "\(years)y"
        default:
            return "some time"
        }
    }
}
