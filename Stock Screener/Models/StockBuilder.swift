//
//  StockBuilder.swift
//  Stock Screener
//
//  Created by Admin on 30.03.2021.
//

import UIKit

protocol StockBuilderDelegate {
    func didUpdateStockItem(_ stockBuilder: StockBuilder, _ stockItem: StockModel)
    func didEndBuilding(_ stockBuilder: StockBuilder, _ amount: Int)
}

struct StockBuilder {
    
    let stockNetwork = StockNetwork()
    
    var delegate: StockBuilderDelegate?
    
    let trendsAPI = "https://cloud.iexapis.com/stable/stock/market/list/mostactive"
    let trendsLimit = 10
    let trendsToken = "pk_8f50c7473cf041fdbe7f9bbafb968391"
    
    let infoAPI = "https://finnhub.io/api/v1/"
    let infoToken = "c1ccrp748v6scqmqri1g"
    
    let searchAPI = "https://api.polygon.io/v2/reference/tickers?sort=ticker&market=STOCKS&search=m&perpage=20&page=1&apiKey="
    let searchToken = "rrDRZXdAdH8R4mbEUkzUhKlg5CZ8xGQX"
    
    let logoURL = "https://storage.googleapis.com/iex/api/logos/"

    
    func getTrends() {
        let URL = "\(trendsAPI)?listLimit=\(trendsLimit)&token=\(trendsToken)"
        
        DispatchQueue.global(qos: .utility).async {
            
            let result: Result<[StockData.Ticker], StockError> = stockNetwork.performRequest(with: URL)
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    print(error)
                case .success (let stockData):
                    for element in stockData {
//                        let stockItem = StockModel(ticker: element.symbol, companyName: element.companyName)
//                        self.delegate?.didUpdateStockItem(self, stockItem)
                        self.delegate?.didEndBuilding(self, stockData.count)
                        buildStockItem(for: element, amount: stockData.count)
                    }
                }
            }
        }
    }
    
    func getPrice(for ticker: String, completion: @escaping (Double, Double) -> Void) {
        let URL = "\(infoAPI)quote?symbol=\(ticker)&token=\(infoToken)"
        
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
    
    func buildStockItem(for ticker: StockData.Ticker, amount: Int) {
        let queue = DispatchQueue(label: "stock builder")
        let group = DispatchGroup()
        
        var logo: UIImage?
        var currentPrice: Double?
        var previousPrice: Double?
//        
//        group.enter()
//        queue.async {
//            getPrice(for: ticker.symbol) { (c, pc) in
//                currentPrice = c
//                previousPrice = pc
//                print("Price \(ticker) OK")
//                group.leave()
//            }
//        }
        
        group.enter()
        queue.async {
            logo = getLogo(for: ticker.symbol)
            print("Logo \(ticker) OK")
            group.leave()
        }
        
        group.notify(queue: queue) {
            let stockItem = StockModel(ticker: ticker.symbol, companyName: ticker.companyName, logo: logo, currentPrice: currentPrice, previousPrice: previousPrice)
            self.delegate?.didUpdateStockItem(self, stockItem)
            self.delegate?.didEndBuilding(self, amount)
        }
    }
    
}

