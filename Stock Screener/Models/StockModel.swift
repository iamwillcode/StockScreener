import UIKit

final class StockModel {
    
    let ticker: String
    let companyName: String
    var logo: UIImage?
    var isFavourite: Bool
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
    
    init (ticker: String, companyName: String, logo: UIImage?) {
        self.ticker = ticker
        self.companyName = companyName
        self.logo = logo
        self.isFavourite = false
        self.currentPrice = nil
        self.previousPrice = nil
    }
    
    // Formatted properties
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
