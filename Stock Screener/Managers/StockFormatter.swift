import Foundation

final class StockFormatter {
    
    func formattedPrice(_ price: Double?) -> String {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        guard let p = price else { return "" } // swiftlint:disable:this identifier_name
        
        let formattedPrice = formatter.string(from: NSNumber(value: p)) ?? ""
        return formattedPrice
    }
    
    func formattedDelta(_ delta: Double?) -> String {
        let formatter = NumberFormatter()
        formatter.positivePrefix = "+"
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        // swiftlint:disable:next identifier_name
        guard let d = delta,
              d != 0 else { return "" }
        
        let formattedDelta = formatter.string(from: NSNumber(value: d)) ?? ""
        return formattedDelta
    }
    
    func formattedPercentDelta(_ percentDelta: Double?) -> String {
        var formattedPercentDelta = ""
        
        // swiftlint:disable:next identifier_name
        guard let d = percentDelta,
              d != 0 else { return "" }
        
        if d >= 0 {
            formattedPercentDelta = String(format: "%.2f%%", d * 100)
        } else {
            formattedPercentDelta = String(format: "%.2f%%", d * -100)
        }
        return formattedPercentDelta
    }
    
    func formattedDateFromUnixTimestamp(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM YYYY"
        let formattedDate = formatter.string(from: date)
        return formattedDate
    }
    
    func formattedDateAndTimeFromUnixTimestamp(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM YYYY, HH:mm"
        let formattedDate = formatter.string(from: date)
        return formattedDate
    }
}
