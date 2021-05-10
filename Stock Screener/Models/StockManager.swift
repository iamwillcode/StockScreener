import UIKit

protocol StockManagerDelegate {
    
    func didUpdateStockItem(_ stock: StockModel, segment: StockSegments?)
    
    func didBuildStockItem(_ stock: StockModel)
    
    func didEndBuilding()
    
    func didFailWithError(_ error: StockError)
    
}

struct StockManager {
    
    let stockNetwork = StockNetwork()
    let logoProvider = StockLogoProvider()
    
    var delegate: StockManagerDelegate?
    
    func getTrends() {
        let URL = "\(Config.Api.trends)?listLimit=\(Config.Api.trendsAmount)&token=\(Config.Api.trendsKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<[StockData.Ticker], StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.delegate?.didFailWithError(error)
                case .success (let stockData):
                    guard stockData.count > 0 else {
                        let error = StockError.trendsError
                        self.delegate?.didFailWithError(error)
                        return
                    }
                    var i = 0
                    for element in stockData {
                        i += 1
                        buildStockItem(for: element.symbol, element.companyName, workload: stockData.count, index: i)
                    }
                }
            }
        }
    }
    
    func search(for ticker: String) {
        let URL = "\(Config.Api.main)search?q=\(ticker)&token=\(Config.Api.mainKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<StockData.Search, StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.delegate?.didFailWithError(error)
                case .success (let stockData):
                    if let searchResult: [StockData.Search.Result] = stockData.result {
                        // set filter to show result only for common stocks, not crypto and etc.
                        var filteredResult = searchResult.filter{ $0.type == "Common Stock" }
                        // set search limit to 10 items
                        let searchLimit = 10
                        
                        if filteredResult.count == 0 {
                            let error = StockError.searchError(ticker)
                            self.delegate?.didFailWithError(error)
                        } else if filteredResult.count >= searchLimit {
                            filteredResult = [StockData.Search.Result](filteredResult[0...(searchLimit - 1)])
                        }
                        var i = 0
                        for element in filteredResult {
                            i += 1
                            buildStockItem(for: element.symbol, element.description, workload: filteredResult.count, index: i)
                        }
                    } else {
                        let error = StockError.searchError(ticker)
                        self.delegate?.didFailWithError(error)
                    }
                }
            }
        }
    }
    
    func getPrice(for stock: StockModel, segment: StockSegments?) {
        let URL = "\(Config.Api.main)quote?symbol=\(stock.ticker)&token=\(Config.Api.mainKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<StockData.Price, StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.delegate?.didFailWithError(error)
                case .success (let stockData):
                    if let currentPrice = stockData.c, let previousPrice = stockData.pc {
                        var updatedStock = stock
                        updatedStock.currentPrice = currentPrice
                        updatedStock.previousPrice = previousPrice
                        delegate?.didUpdateStockItem(updatedStock, segment: segment)
                    } else {
                        let error = StockError.tickerPriceError(stock.ticker)
                        self.delegate?.didFailWithError(error)
                    }
                }
            }
        }
    }
    
    func getChartData (for ticker: String, completion: @escaping ([Double], [Double]) -> Void) {
        let currentTimestamp = Int(Date().timeIntervalSince1970)
        let monthAgoTimestamp = currentTimestamp - 2592000
        
        let URL = "\(Config.Api.main)stock/candle?symbol=\(ticker)&resolution=D&from=\(monthAgoTimestamp)&to=\(currentTimestamp)&token=\(Config.Api.mainKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<StockData.ChartData, StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure (let error):
                    self.delegate?.didFailWithError(error)
                case .success (let stockData):
                    if let price = stockData.c, let timestamp = stockData.t {
                        completion(price, timestamp)
                    }
                }
            }
        }
    }
    
    func getNews (for ticker: String, completion: @escaping ([StockNewsModel]) -> Void) {
        let URL = "\(Config.Api.news)\(ticker)/news?token=\(Config.Api.newsKey)"

        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<[StockData.News], StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure (let error):
                    self.delegate?.didFailWithError(error)
                case .success (let stockData):
                    var stockNews = [StockNewsModel]()
                    for searchItem in stockData {
                        let stockNewsItem = StockNewsModel(headline: searchItem.headline, source: searchItem.source, url: searchItem.url, timestamp: searchItem.datetime, summary: searchItem.summary)
                        stockNews.append(stockNewsItem)
                    }
                    completion(stockNews)
                }
            }
        }
    }
    
    func getLogo(for ticker: String, completion: @escaping (UIImage?) -> Void) {
        let urlString = "\(Config.Api.logo)\(ticker).png"
        guard let logoURL = URL(string: urlString) else { return }
            
        logoProvider.downloadImage(url: logoURL) { (image) in
            if let logo = image {
                completion(logo)
            } else {
                completion(nil)
                let error = StockError.tickerLogoError(ticker)
                self.delegate?.didFailWithError(error)
            }
        }
    }
    
    func buildStockItem(for ticker: String, _ companyName: String, workload: Int, index: Int) {
        let queue = K.Queues.stockManagerTask
        let group = DispatchGroup()
        
        var logo: UIImage?
        
        group.enter()
        queue.async {
            getLogo(for: ticker) { (image) in
                logo = image
                group.leave()
            }
        }
        
        group.notify(queue: queue) {
            let stockItem = StockModel(ticker: ticker, companyName: companyName, logo: logo)
            self.delegate?.didBuildStockItem(stockItem)
            if index == workload {
                self.delegate?.didEndBuilding()
            }
        }
    }
    
}

