import UIKit

protocol StockBuilderDelegate {
    
    func didUpdateStockItem(_ stockBuilder: StockBuilder, _ stockItem: StockModel)
    
    func didEndBuilding(_ stockBuilder: StockBuilder, _ amount: Int)
    
}

struct StockBuilder {
    
    let stockNetwork = StockNetwork()
    
    var delegate: StockBuilderDelegate?
    
    let trendsAPI = "https://cloud.iexapis.com/stable/stock/market/list/mostactive"
    let trendsAmount = 10
    let trendsAPIKey = "pk_8f50c7473cf041fdbe7f9bbafb968391"
    
    let mainAPI = "https://finnhub.io/api/v1/" // 60 calls per minute limit
    let mainAPIKey = "c1ccrp748v6scqmqri1g"
    
    let logoURL = "https://storage.googleapis.com/iex/api/logos/"
    
    func getTrends() {
        let URL = "\(trendsAPI)?listLimit=\(trendsAmount)&token=\(trendsAPIKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<[StockData.Ticker], StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    print(error)
                case .success (let stockData):
                    for element in stockData {
                        self.delegate?.didEndBuilding(self, stockData.count)
                        buildStockItem(for: element.symbol, element.companyName, amount: stockData.count)
                    }
                }
            }
        }
    }
    
    func searchStock(for ticker: String) {
        let URL = "\(mainAPI)search?q=\(ticker)&token=\(mainAPIKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<StockData, StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    print(error)
                case .success (let stockData):
                    if let searchResult = stockData.result {
                    for element in searchResult {
                        self.delegate?.didEndBuilding(self, searchResult.count)
                        buildStockItem(for: element.symbol, element.description, amount: searchResult.count)
                    }
                }
                }
            }
        }
    }
    
    func getPrice(for ticker: String, completion: @escaping (Double, Double) -> Void) {
        let URL = "\(mainAPI)quote?symbol=\(ticker)&token=\(mainAPIKey)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<StockData, StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    print(error)
                case .success (let stockData):
                    if let currentPrice = stockData.c, let previousPrice = stockData.pc {
                        completion(currentPrice, previousPrice)
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
    
    func getLogo(for ticker: String) -> UIImage? {
        let urlString = "\(logoURL)\(ticker).png"
        if let logoURL = URL(string: urlString) {
            if let data = try? Data(contentsOf: logoURL) {
                if let image = UIImage(data: data) {
                    return image
                }
            }
        }
        return nil
    }
    
    func buildStockItem(for ticker: String, _ companyName: String, amount: Int) {
        let queue = DispatchQueue(label: "stock builder")
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

