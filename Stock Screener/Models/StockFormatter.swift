import Foundation

struct StockFormatter {
    
    func formattedPrice(_ price: Double?) -> String {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        guard let p = price else { return "" }
        
        let formattedPrice = formatter.string(from: NSNumber(value: p)) ?? ""
        return formattedPrice
    }
    
    func formattedDelta(_ delta: Double?) -> String {
        let formatter = NumberFormatter()
        formatter.positivePrefix = "+"
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        guard let d = delta,
              d != 0 else { return "" }
        
        let formattedDelta = formatter.string(from: NSNumber(value: d)) ?? ""
        return formattedDelta
    }
    
    func formattedPercentDelta(_ percentDelta: Double?) -> String {
        var formattedPercentDelta = ""
        
        guard let d = percentDelta,
              d != 0 else { return "" }
        
        if d >= 0 {
            formattedPercentDelta = String(format:"%.2f%%", d * 100)
        } else {
            formattedPercentDelta = String(format:"%.2f%%", d * -100)
        }
        return " (\(formattedPercentDelta))"
    }
}
