import UIKit

class StockListViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var segments: UISegmentedControl!
    @IBOutlet var searchBar: UISearchBar!
    
    var stock = [String: StockModel]()
    var favourites = [String: StockModel]()
    
    private var formatter = StockFormatter()
    private var stockBuilder = StockBuilder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stockBuilder.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "StockCell", bundle: nil), forCellReuseIdentifier: "StockCell")
        
        stockBuilder.getTrends()
    }
    
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        stockBuilder.updatePrice(for: source)
    }
    
    
}


// MARK: - Table view data source

extension StockListViewController: UITableViewDataSource {
    
    var source: [String: StockModel] {
        get {
            if segments.selectedSegmentIndex == 0 {
                return self.stock
            } else {
                return self.favourites
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let stockList = [StockModel](source.values).sorted{$0.ticker < $1.ticker}
        var stockItem = stockList[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "StockCell", for: indexPath)
            as! StockCell
        
        cell.ticker.text = stockItem.ticker
        cell.companyName.text = stockItem.companyName
        cell.currentPrice.text = formatter.formatPrice(stockItem.currentPrice)
        cell.dayDelta.text = formatter.formatDelta(stockItem.dayDelta) + formatter.formatPercentDelta(stockItem.percentDelta)
        
        if let delta = stockItem.dayDelta {
            if delta >= 0 {
                cell.dayDelta.textColor = UIColor(named: K.Colors.Common.green)
            } else {
                cell.dayDelta.textColor = UIColor(named: K.Colors.Common.red)
            }
            
        }
        
        if let logo = stockItem.logo {
            cell.companyLogo.image = logo
        } else {
            cell.companyLogo.image = UIImage(named: K.defaultLogo)
        }
        print("\(stockItem.ticker) \(stockItem.isFavourite)")
        if stockItem.isFavourite {
            let image = UIImage(systemName: "star.fill")!.withTintColor(UIColor(named: K.Colors.Common.isFavourite)!, renderingMode: .alwaysOriginal)
            cell.favouriteButton.setImage(image, for: .normal)
        } else {
            let image = UIImage(systemName: "star.fill")!.withTintColor(UIColor(named: K.Colors.Common.notFavourite)!, renderingMode: .alwaysOriginal)
            cell.favouriteButton.setImage(image, for: .normal)
        }
        
        switch cell.currentPrice.text {
        case "":
            cell.activityIndicator.startAnimating()
        default:
            cell.activityIndicator.stopAnimating()
        }
        
        cell.callbackOnButton = {
            let ticker = stockItem.ticker
            self.stock[ticker]!.isFavourite = !self.stock[ticker]!.isFavourite
            stockItem.isFavourite = !stockItem.isFavourite
            if stockItem.isFavourite {
                self.favourites[stockItem.ticker] = stockItem
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            } else {
                self.favourites[stockItem.ticker] = nil
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
        
        return cell
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

//MARK: - Table view delegate

extension StockListViewController: UITableViewDelegate {
}

//MARK: - Stock Network delegate

extension StockListViewController: StockBuilderDelegate {
    
    func didUpdateStockItem(_ stockBuilder: StockBuilder, _ stockItem: StockModel) {
        let key = stockItem.ticker
        if stock[key] != nil {
            if let currentPrice = stockItem.currentPrice, stock[key]!.currentPrice != currentPrice {
                stock[key]!.currentPrice = currentPrice
                //                print("Price \(key) OK")
            }
            if let previousPrice = stockItem.previousPrice, stock[key]!.previousPrice != previousPrice {
                stock[key]!.previousPrice = previousPrice
                //                print("PrevPrice \(key) OK")
            }
            //            if let logo = stockItem.logo, stock[key]!.logo != logo {
            //                stock[key]!.logo = logo
            //                print("Logo \(key) OK")
            //            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        else {
            stock[key] = stockItem
        }
    }
    
    func didEndBuilding(_ stockBuilder: StockBuilder, _ amount: Int) {
        if amount == stock.count {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            stockBuilder.updatePrice(for: stock)
        }
    }
    
}

