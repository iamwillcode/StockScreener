import Foundation
import RealmSwift

final class StockFavourite {
    
    static let shared: StockFavourite = {
        let instance = StockFavourite()
        return instance
    }()
    
    let realm = try! Realm()
    
    private init() {}
    
    private var stockManager = StockManager()
    
    private var favouriteStocks = [String: StockModel]()
    
    private let queue = K.Queues.favouriteStocksAccess
    
    func getFavourite() -> [String: StockModel] {
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
        
        addObjectToRealm(from: stock)
    }
    
    func removeFromFavourite(stock: StockModel) {
        let ticker = stock.ticker
        
        queue.sync {
            self.favouriteStocks[ticker] = nil
        }
        
        removeObjectFromRealm(for: stock)
    }
    
    func updateFavourite(stock: StockModel) {
        let ticker = stock.ticker
        queue.sync {
            self.favouriteStocks[ticker] = stock
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
}

//MARK: - Realm methods extension

extension StockFavourite {
    
    func loadFavouriteFromRealm() {
        var safeFavouriteStocks = [String: StockModel]()
        
        let allObjects = realm.objects(StockObject.self)
        
        for object in allObjects {
            let key = object.key
            if let value = object.value {
                let ticker = value.ticker
                let companyName = value.companyName
                let isFavourite = true
                var logo: UIImage?
                
                let group = DispatchGroup()
                
                group.enter()
                stockManager.getLogo(for: ticker) { (image) in
                    logo = image
                    group.leave()
                }
                
                group.notify(queue: DispatchQueue.main) {
                    let stock = StockModel(ticker: ticker, companyName: companyName, logo: logo, isFavourite: isFavourite)
                    safeFavouriteStocks[key] = stock
                    self.queue.sync {
                        self.favouriteStocks = safeFavouriteStocks
                    }
                }
            } else {
                try! realm.write {
                    realm.delete(object)
                }
            }
        }
    }
    
    private func addObjectToRealm(from stock: StockModel) {
        let ticker = stock.ticker
        
        let tickerObject = StockObject()
        tickerObject.key = ticker
        
        let valueObject = StockModelObject()
        valueObject.ticker = stock.ticker
        valueObject.companyName = stock.companyName
        
        tickerObject.value = valueObject
        
        try! realm.write {
            realm.add(tickerObject, update: .modified)
        }
    }
    
    private func removeObjectFromRealm(for stock: StockModel) {
        let ticker = stock.ticker
        
        let stockObject = realm.object(ofType: StockObject.self, forPrimaryKey: ticker)
        let valueObject = realm.object(ofType: StockModelObject.self, forPrimaryKey: ticker)
        
        try! realm.write {
            guard let key = stockObject, let value = valueObject else { return }
            realm.delete(key)
            realm.delete(value)
        }
    }
}
