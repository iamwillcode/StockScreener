import UIKit

struct StockModel {
    
    let ticker: String
    let companyName: String
    var logo: UIImage?
    var isFavourite: Bool = false
    var currentPrice: Double?
    var previousPrice: Double?
    
    var delta: Double? {
        guard let c = currentPrice, let pc = previousPrice else {
            return nil
        }
        return c - pc
    }
    
    var percentDelta: Double? {
        guard let c = currentPrice, let pc = previousPrice else {
            return nil
        }
        return (c - pc) / pc
    }
    
    private let formatter = StockFormatter()
    
    var formattedPrice: String? {
        guard currentPrice != 0 else {return "-"}
        return formatter.formattedPrice(currentPrice)
    }
    
    var formattedDayDelta: String? {
        let formattedDelta = formatter.formattedDelta(delta)
        let formattedPercentDelta = formatter.formattedPercentDelta(percentDelta)
        return formattedDelta + formattedPercentDelta
    }
    
}
