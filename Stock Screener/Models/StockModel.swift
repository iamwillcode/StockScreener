import UIKit

struct StockModel {
    let ticker: String
    let companyName: String
    var logo: UIImage?
    var isFavourite: Bool = false
    var currentPrice: Double?
    var previousPrice: Double?
    var dayDelta: Double? {
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
    
}
