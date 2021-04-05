import Foundation

final class StockFavourite {
    
    var favourite = [String: StockModel]()
    
    static let shared: StockFavourite = {
        let instance = StockFavourite()
        return instance
    }()
    
    private init() {}
    
    private let queue = Config.Queues.favouriteDictionaryAccess
    
    func addToFavourite(stock: StockModel) {
        let ticker = stock.ticker
        queue.sync {
            self.favourite[ticker] = stock
        }
    }
    
    func removeFromFavourite(stock: StockModel) {
        let ticker = stock.ticker
        queue.sync {
            self.favourite[ticker] = nil
        }
    }
    
    func checkIfTickerIsFavourite(stock: StockModel, completion: @escaping (Bool) -> Void) {
        let ticker = stock.ticker
        queue.sync {
            if self.favourite[ticker] != nil {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
}
