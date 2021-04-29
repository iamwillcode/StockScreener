import Foundation

final class StockFavourite {
    
    private(set) var favouriteStocks = [String: StockModel]()
    
    static let shared: StockFavourite = {
        let instance = StockFavourite()
        return instance
    }()
    
    private init() {}
    
    private let queue = Config.Queues.favouriteStocksAccess
    
    func addToFavourite(stock: StockModel) {
        let ticker = stock.ticker
        queue.sync {
            self.favouriteStocks[ticker] = stock
        }
    }
    
    func removeFromFavourite(stock: StockModel) {
        let ticker = stock.ticker
        queue.sync {
            self.favouriteStocks[ticker] = nil
        }
    }
    
    func checkIfTickerIsFavourite(stock: StockModel, completion: @escaping (Bool) -> Void) {
        let ticker = stock.ticker
        queue.sync {
            if self.favouriteStocks[ticker] != nil {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func updateFavouriteStocks(to updatedStocks: [String: StockModel]) {
        queue.sync {
            self.favouriteStocks = updatedStocks
        }
    }
    
}
