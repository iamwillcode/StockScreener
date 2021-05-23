import UIKit

struct StockModel {
    
    let ticker: String
    let companyName: String
    var logo: UIImage?
    var isFavourite: Bool = false
    var currentPrice: Double?
    var previousPrice: Double?
    
    var delta: Double? {
        guard let cPrice = currentPrice,
              let pPrice = previousPrice else { return nil }
        return cPrice - pPrice
    }
    
    var percentDelta: Double? {
        guard let cPrice = currentPrice,
              let pPrice = previousPrice else { return nil }
        return (cPrice - pPrice) / pPrice
    }
    
    private let formatter = StockFormatter()
    
    var formattedPrice: String? {
        guard currentPrice != 0 else { return "-" }
        return formatter.formattedPrice(currentPrice)
    }
    
    var formattedDayDelta: String? {
        let formattedDelta = formatter.formattedDelta(delta)
        let formattedPercentDelta = formatter.formattedPercentDelta(percentDelta)
        
        guard formattedPercentDelta.count > 0 else { return formattedDelta }
        
        let dayDelta = "\(formattedDelta) (\(formattedPercentDelta))"
        
        return dayDelta
    }
}
