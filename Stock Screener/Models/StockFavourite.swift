import Foundation

final class StockFavourite {
    
    static let shared: StockFavourite = {
        let instance = StockFavourite()
        return instance
    }()
    
    private init() {}
    
    private var favouriteStocks = [String: StockModel]()
    
    private let queue = K.Queues.favouriteStocksAccess
    
    func getFavouriteStocks() -> [String: StockModel] {
        var safeFavouriteStocks = [String: StockModel]()
        queue.sync {
            safeFavouriteStocks = self.favouriteStocks
        }
        return safeFavouriteStocks
    }
    
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
