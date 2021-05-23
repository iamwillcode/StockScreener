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
        case 0..<Constants.TimeInSeconds.minute:
            return "\(timeDifference)s"
        case 0..<Constants.TimeInSeconds.hour:
            let minutes = timeDifference / Constants.TimeInSeconds.minute
            return "\(minutes)min"
        case 0..<Constants.TimeInSeconds.day:
            let hours = timeDifference / Constants.TimeInSeconds.hour
            return "\(hours)h"
        case 0..<Constants.TimeInSeconds.month:
            let days = timeDifference / Constants.TimeInSeconds.day
            return "\(days)d"
        case 0..<Constants.TimeInSeconds.year:
            let months = timeDifference / Constants.TimeInSeconds.month
            return "\(months)m"
        case Constants.TimeInSeconds.year...:
            let years = timeDifference / Constants.TimeInSeconds.year
            return "\(years)y"
        default:
            return "some time"
        }
    }
}
