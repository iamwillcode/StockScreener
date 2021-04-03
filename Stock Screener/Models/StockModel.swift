import UIKit

struct StockModel {
    
    let ticker: String
    let companyName: String
    var logo: UIImage?
    var isFavourite: Bool = false
    var currentPrice: Double?
    var previousPrice: Double?
    
    var delta: Double? {
        get {
            guard let c = currentPrice, let pc = previousPrice else {
                return nil
            }
            return c - pc
        }
    }
    
    var percentDelta: Double? {
        get {
            guard let c = currentPrice, let pc = previousPrice else {
                return nil
            }
            return (c - pc) / pc
        }
    }
    
    private let formatter = StockFormatter()
    
    var formattedPrice: String? {
        return formatter.formatPrice(currentPrice)
    }
    
    var formattedDayDelta: String? {
        let formattedDelta = formatter.formatDelta(delta)
        let formattedPercentDelta = formatter.formatPercentDelta(percentDelta)
        return formattedDelta + formattedPercentDelta
    }
    
}
