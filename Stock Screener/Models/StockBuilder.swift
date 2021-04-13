import UIKit

protocol StockBuilderDelegate {
    
    func didUpdateStockItem(_ stockBuilder: StockBuilder, _ stockItem: StockModel)
    
    func didEndBuilding(_ stockBuilder: StockBuilder, _ amount: Int)
    
    func didFailWithError(_ stockBuilder: StockBuilder, error: StockError)
    
}

struct StockBuilder {
    
    let stockNetwork = StockNetwork()
    
    var delegate: StockBuilderDelegate?
    
    func getTrends() {
        let URL = "\(Config.Api.trends)?listLimit=\(Config.Api.trendsAmount)&token=\(Config.Api.trendsKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<[StockData.Ticker], StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.delegate?.didFailWithError(self, error: error)
                case .success (let stockData):
                    for element in stockData {
                        self.delegate?.didEndBuilding(self, stockData.count)
                        buildStockItem(for: element.symbol, element.companyName, amount: stockData.count)
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
                    self.delegate?.didFailWithError(self, error: error)
                case .success (let stockData):
                    if let searchResult: [StockData.Search.Result] = stockData.result {
                        // set filter to show result only for common stocks, not crypto and etc.
                        var filteredResult = searchResult.filter{ $0.type == "Common Stock" }
                        
                        if filteredResult.count == 0 {
                            let error = StockError.searchError(ticker)
                            self.delegate?.didFailWithError(self, error: error)
                        // set search limit to 10 items
                        } else if filteredResult.count >= 10 {
                            filteredResult = [StockData.Search.Result](filteredResult[0...9])
                        }
                        
                        for element in filteredResult {
                            buildStockItem(for: element.symbol, element.description, amount: filteredResult.count)
                        }
                    } else {
                        let error = StockError.searchError(ticker)
                        self.delegate?.didFailWithError(self, error: error)
                    }
                }
            }
        }
    }
    
    func getPrice(for ticker: String, completion: @escaping (Double, Double) -> Void) {
        let URL = "\(Config.Api.main)quote?symbol=\(ticker)&token=\(Config.Api.mainKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<StockData.Price, StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.delegate?.didFailWithError(self, error: error)
                case .success (let stockData):
                    if let currentPrice = stockData.c, let previousPrice = stockData.pc {
                        completion(currentPrice, previousPrice)
                    } else {
                        let error = StockError.tickerPriceError(ticker)
                        self.delegate?.didFailWithError(self, error: error)
                    }
                }
            }
        }
    }
    
    func updatePrice(for stock: [String: StockModel]) {
        for ticker in stock.keys {
            getPrice(for: ticker) { (currentPrice, previousPrice) in
                var stockItem = stock[ticker]!
                stockItem.currentPrice = currentPrice
                stockItem.previousPrice = previousPrice
                self.delegate?.didUpdateStockItem(self, stockItem)
            }
        }
    }
    
    func getChartData (for ticker: String, completion: @escaping ([Double]) -> Void) {
        let currentTimestamp = Int(Date().timeIntervalSince1970)
        let monthAgoTimestamp = currentTimestamp - 2592000
        
        let URL = "\(Config.Api.main)stock/candle?symbol=\(ticker)&resolution=D&from=\(monthAgoTimestamp)&to=\(currentTimestamp)&token=\(Config.Api.mainKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<StockData.ChartData, StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure (let error):
                    self.delegate?.didFailWithError(self, error: error)
                case .success (let stockData):
                    if let chartData = stockData.h {
                        completion(chartData)
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
                    self.delegate?.didFailWithError(self, error: error)
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
    
    func getLogo(for ticker: String) -> UIImage? {
        let urlString = "\(Config.Api.logo)\(ticker).png"
        if let logoURL = URL(string: urlString) {
            if let data = try? Data(contentsOf: logoURL) {
                if let image = UIImage(data: data) {
                    return image
                } else {
                    let error = StockError.tickerLogoError(ticker)
                    self.delegate?.didFailWithError(self, error: error)
                }
            }
        }
        return nil
    }
    
    func buildStockItem(for ticker: String, _ companyName: String, amount: Int) {
        let queue = Config.Queues.builderTask
        let group = DispatchGroup()
        
        var logo: UIImage?
        
        group.enter()
        queue.async {
            logo = getLogo(for: ticker)
            group.leave()
        }
        
        group.notify(queue: queue) {
            let stockItem = StockModel(ticker: ticker, companyName: companyName, logo: logo)
            self.delegate?.didUpdateStockItem(self, stockItem)
            self.delegate?.didEndBuilding(self, amount)
        }
    }
    
}

