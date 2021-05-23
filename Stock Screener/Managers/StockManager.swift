import UIKit

protocol StockManagerDelegate: AnyObject {
    func didUpdateStockItem(_ stock: StockModel, segment: StockSegments?)
    func didBuildStockItem(_ stock: StockModel, workload: Int)
    func didFailWithError(_ error: StockError)
}

struct StockManager {
    
    weak var delegate: StockManagerDelegate?
    
    private let stockNetwork = StockNetwork()
    private let logoProvider = StockLogoProvider()
    
    /// Gets the list of trending tickers from API
    func getTrends() {
        let URL = "\(Config.Api.trends)?listLimit=\(Config.Api.trendsAmount)&token=\(Config.Api.trendsKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<[StockData.Ticker], StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.delegate?.didFailWithError(error)
                case .success(let stockData):
                    guard stockData.count > 0 else {
                        let error = StockError.trendsError
                        self.delegate?.didFailWithError(error)
                        return
                    }
                    
                    for element in stockData {
                        buildStockItem(for: element.symbol, element.companyName, workload: stockData.count)
                    }
                }
            }
        }
    }
    
    /// Gets search results for specified ticker from API
    func search(for ticker: String) {
        let URL = "\(Config.Api.main)search?q=\(ticker)&token=\(Config.Api.mainKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<StockData.Search, StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.delegate?.didFailWithError(error)
                case .success(let stockData):
                    if let searchResult: [StockData.Search.Result] = stockData.result {
                        // Set filter to show result only for common stocks, not crypto and etc.
                        var filteredResult = searchResult.filter { $0.type == "Common Stock" }
                        // Set search limit to 10 items
                        let searchLimit = 10
                        
                        if filteredResult.count == 0 {
                            let error = StockError.searchError(ticker)
                            self.delegate?.didFailWithError(error)
                        } else if filteredResult.count >= searchLimit {
                            // Reduce the number of results based on the search limit
                            filteredResult = [StockData.Search.Result](filteredResult[0...(searchLimit - 1)])
                        }
                        
                        for element in filteredResult {
                            buildStockItem(for: element.symbol, element.description, workload: filteredResult.count)
                        }
                    } else {
                        let error = StockError.searchError(ticker)
                        self.delegate?.didFailWithError(error)
                    }
                }
            }
        }
    }
    
    /// Gets the price of the specified stock object from API
    func getPrice(for stock: StockModel, segment: StockSegments?) {
        let URL = "\(Config.Api.main)quote?symbol=\(stock.ticker)&token=\(Config.Api.mainKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<StockData.Price, StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.delegate?.didFailWithError(error)
                case .success(let stockData):
                    if let currentPrice = stockData.c,
                       let previousPrice = stockData.pc {
                        var updatedStock = stock
                        updatedStock.currentPrice = currentPrice
                        updatedStock.previousPrice = previousPrice
                        self.delegate?.didUpdateStockItem(updatedStock, segment: segment)
                    } else {
                        let error = StockError.tickerPriceError(stock.ticker)
                        self.delegate?.didFailWithError(error)
                    }
                }
            }
        }
    }
    
    /// Gets data from API to draw a chart for the specified ticker for a certain period of time
    func getChartData (for ticker: String, period: String, completion: @escaping ([Double]?, [Double]?) -> Void) {
        let currentTimestamp = Int(Date().timeIntervalSince1970)
        
        var resolution: String {
            switch period {
            case "D":
                return "60"
            case "W", "M", "3M":
                return "D"
            case "6M", "Y":
                return "W"
            default:
                return "D"
            }
        }
        
        var calculatedTimestamp: Int {
            switch period {
            case "D":
                return currentTimestamp - Constants.TimeInSeconds.day
            case "W":
                return currentTimestamp - Constants.TimeInSeconds.week
            case "M":
                return currentTimestamp - Constants.TimeInSeconds.month
            case "3M":
                return currentTimestamp - Constants.TimeInSeconds.month * 3
            case "6M":
                return currentTimestamp - Constants.TimeInSeconds.month * 6
            case "Y":
                return currentTimestamp - Constants.TimeInSeconds.year
            default:
                return currentTimestamp
            }
        }
        
        // swiftlint:disable:next line_length
        let URL = "\(Config.Api.main)stock/candle?symbol=\(ticker)&resolution=\(resolution)&from=\(calculatedTimestamp)&to=\(currentTimestamp)&token=\(Config.Api.mainKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<StockData.ChartData, StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.delegate?.didFailWithError(error)
                case .success(let stockData):
                    if let price = stockData.c, let timestamp = stockData.t {
                        completion(price, timestamp)
                    } else {
                        completion(nil, nil)
                    }
                }
            }
        }
    }
    
    /// Gets the newsfeed for the specified ticker from API
    func getNews (for ticker: String, completion: @escaping ([StockNewsModel]) -> Void) {
        let URL = "\(Config.Api.news)\(ticker)/news?token=\(Config.Api.newsKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<[StockData.News], StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.delegate?.didFailWithError(error)
                case .success(let stockData):
                    var stockNews = [StockNewsModel]()
                    for searchItem in stockData {
                        let stockNewsItem = StockNewsModel(
                            headline: searchItem.headline,
                            source: searchItem.source,
                            url: searchItem.url,
                            timestamp: searchItem.datetime,
                            summary: searchItem.summary
                        )
                        stockNews.append(stockNewsItem)
                    }
                    completion(stockNews)
                }
            }
        }
    }
    
    /// Gets the logo of the specified ticker from API using Logo Provider
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
    
    /// Builds an object from Stock Model with given properties
    /// - Parameters:
    ///   - ticker: short name of stock
    ///   - companyName: full name of stock
    ///   - workload: total amount of objects to build
    func buildStockItem(for ticker: String, _ companyName: String, workload: Int) {
        let queue = Constants.Queues.stockManagerTask
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
            self.delegate?.didBuildStockItem(stockItem, workload: workload)
        }
    }
}
