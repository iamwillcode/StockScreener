import UIKit

protocol ResultsTableControllerDelegate {
    
    func didSelectStock(stock: StockModel)
    
    func didSetAsFavourite(stock: StockModel)
    
    func didUnsetAsFavourite(stock: StockModel)
    
}

class ResultsTableController: UITableViewController {
    
    var result: [String: StockModel] = ["AAPL": StockModel(ticker: "AAPL", companyName: "Apple"), "AAP": StockModel(ticker: "AAP", companyName: "Apple")]
    
    var delegate: ResultsTableControllerDelegate?
    
    private var formatter = StockFormatter()
    private var stockBuilder = StockBuilder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stockBuilder.delegate = self
        self.tableView.register(UINib(nibName: "StockCell", bundle: nil), forCellReuseIdentifier: "StockCell")
        
        setupUI()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Tickers", comment: "")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return result.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let stockList = [StockModel](result.values).sorted{$0.ticker < $1.ticker}
        var stockItem = stockList[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "StockCell", for: indexPath)
            as! StockCell
        
        cell.ticker.text = stockItem.ticker
        cell.companyName.text = stockItem.companyName
        cell.currentPrice.text = stockItem.formattedPrice
        cell.dayDelta.text = stockItem.formattedDayDelta
        
        if let delta = stockItem.delta {
            if delta >= 0 {
                cell.dayDelta.textColor = UIColor(named: K.Colors.Common.green)
            } else {
                cell.dayDelta.textColor = UIColor(named: K.Colors.Common.red)
            }
            
        }
        
        switch cell.currentPrice.text {
        case "":
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
            cell.backgroundColor = UIColor(named: K.Colors.Background.secondary)
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
                self.delegate?.didSetAsFavourite(stock: stockItem)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                self.delegate?.didUnsetAsFavourite(stock: stockItem)
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
    
    private func setupUI() {
        tableView.separatorStyle = .none
    }
    
}

extension ResultsTableController: StockBuilderDelegate {
    
    func didUpdateStockItem(_ stockBuilder: StockBuilder, _ stockItem: StockModel) {
        let queue = DispatchQueue(label: "update stock", qos: .userInitiated)
        
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
            }
            else {
                print(stockItem)
                self.result[key] = stockItem
            }
        }
    }
    
    func didEndBuilding(_ stockBuilder: StockBuilder, _ amount: Int) {
        if amount == result.count {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            stockBuilder.updatePrice(for: result)
        }
    }
    
}
