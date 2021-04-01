import Foundation

struct StockFormatter {
    
    func formatPrice(_ price: Double?) -> String {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 2
        
        guard let p = price else { return "" }
        
        let formattedPrice = formatter.string(from: NSNumber(value: p)) ?? ""
        return formattedPrice
    }
    
    func formatDelta(_ delta: Double?) -> String {
        let formatter = NumberFormatter()
        formatter.positivePrefix = "+"
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 2
        
        guard let d = delta else { return "" }
        
        let formattedDelta = formatter.string(from: NSNumber(value: d)) ?? ""
        return formattedDelta
    }
    
    func formatPercentDelta(_ percentDelta: Double?) -> String {
        var formattedPercentDelta = ""
        
        guard let d = percentDelta else { return "" }
        
        if d >= 0 {
            formattedPercentDelta = String(format:"%.2f%%", d * 100)
        } else {
            formattedPercentDelta = String(format:"%.2f%%", d * -100)
        }
        return " (\(formattedPercentDelta))"
    }
    
}
