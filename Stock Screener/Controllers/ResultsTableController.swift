import UIKit

protocol ResultsTableControllerDelegate {
    
    func didSelectStock(stock: StockModel)
    
}

class ResultsTableController: UITableViewController {
    
    // MARK: - Public Properties
    
    var searchQuery: String = ""
    var delegate: ResultsTableControllerDelegate?
    
    // MARK: - Private Properties
    
    private var result = [String: StockModel]()
    private var formatter = StockFormatter()
    private var stockBuilder = StockBuilder()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stockBuilder.delegate = self
        
        self.tableView.register(UINib(nibName: K.stockCell, bundle: nil), forCellReuseIdentifier: K.stockCell)
        
        setupUI()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return result.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let stockList = [StockModel](result.values).sorted{$0.ticker < $1.ticker}
        var stockItem = stockList[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.stockCell, for: indexPath)
            as! StockCell
        
        cell.ticker.text = stockItem.ticker
        cell.companyName.text = stockItem.companyName
        cell.currentPrice.text = stockItem.formattedPrice
        cell.dayDelta.text = stockItem.formattedDayDelta
        
        if let delta = stockItem.delta {
            if delta >= 0 {
                cell.dayDelta.textColor = UIColor(named: K.Colors.Common.green)
            } else if delta < 0 {
                cell.dayDelta.textColor = UIColor(named: K.Colors.Common.red)
            } else {
                cell.dayDelta.textColor = .black
            }
        }
        
        switch stockItem.currentPrice {
        case nil:
            cell.activityIndicator.startAnimating()
        default:
            cell.activityIndicator.stopAnimating()
        }
        
        if let logo = stockItem.logo {
            cell.companyLogo.image = logo
        } else {
            cell.companyLogo.image = UIImage(named: K.defaultLogo)
        }
        
        if indexPath.row % 2 != 0 {
            cell.backgroundColor = UIColor(named: K.Colors.Background.main)
        } else {
            cell.backgroundColor = .white
        }
        
        if stockItem.isFavourite {
            let image = UIImage(systemName: "star.fill")!.withTintColor(UIColor(named: K.Colors.Common.isFavourite)!, renderingMode: .alwaysOriginal)
            cell.favouriteButton.setImage(image, for: .normal)
        } else {
            let image = UIImage(systemName: "star.fill")!.withTintColor(UIColor(named: K.Colors.Common.notFavourite)!, renderingMode: .alwaysOriginal)
            cell.favouriteButton.setImage(image, for: .normal)
        }
        
        cell.callbackOnFavouriteButton = {
            let ticker = stockItem.ticker
            self.result[ticker]!.isFavourite = !self.result[ticker]!.isFavourite
            stockItem.isFavourite = !stockItem.isFavourite
            if stockItem.isFavourite {
                StockFavourite.shared.addToFavourite(stock: stockItem)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                StockFavourite.shared.removeFromFavourite(stock: stockItem)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.indexPathForSelectedRow != nil {
            let stockList = [StockModel](result.values).sorted{$0.ticker < $1.ticker}
            let stock = stockList[tableView.indexPathForSelectedRow!.row]
            delegate?.didSelectStock(stock: stock)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Public Methods
    
    func clearResults() {
        result.removeAll()
        tableView.reloadData()
    }
    
    func searchStock() {
        result.removeAll()
        stockBuilder.search(for: searchQuery)
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(named: K.Colors.Background.main)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
    }
    
}

//MARK: - StockBuilderDelegate

extension ResultsTableController: StockBuilderDelegate {
    
    func didUpdateStockItem(_ stockBuilder: StockBuilder, _ stockItem: StockModel) {
        let queue = Config.Queues.resultDictionaryAccess
        
        queue.sync {
            let key = stockItem.ticker
            if self.result[key] != nil {
                if let currentPrice = stockItem.currentPrice, self.result[key]!.currentPrice != currentPrice {
                    self.result[key]!.currentPrice = currentPrice
                }
                if let previousPrice = stockItem.previousPrice, self.result[key]!.previousPrice != previousPrice {
                    self.result[key]!.previousPrice = previousPrice
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                self.result[key] = stockItem
                StockFavourite.shared.checkIfTickerIsFavourite(stock: stockItem) { (result) in
                    if result {
                        self.result[key]?.isFavourite = true
                    }
                }
            }
        }
    }
    
    func didEndBuilding(_ stockBuilder: StockBuilder, _ amount: Int) {
        let queue = Config.Queues.resultDictionaryAccess
        
        queue.sync {
            if amount == result.count {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                print(result.keys.sorted())
                stockBuilder.updatePrice(for: result)
            }
        }
    }
    
    func didFailWithError(_ stockBuilder: StockBuilder, error: StockError) {
        switch error {
        case .tickerPriceError(let ticker):
            print(error.localizedDescription)
            if result[ticker] != nil {
                if result[ticker]!.currentPrice == nil {
                    result[ticker]!.currentPrice = 0
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        default:
            print(error.localizedDescription)
        }
    }
    
}
