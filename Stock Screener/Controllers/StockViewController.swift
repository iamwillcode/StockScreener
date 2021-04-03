import UIKit

class StockViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var segments: UISegmentedControl!
    
    var stock = [String: StockModel]()
    var favourites = [String: StockModel]()
    
    var searchController: UISearchController!
    var resultsTableController: ResultsTableController!
    
    private var formatter = StockFormatter()
    private var stockBuilder = StockBuilder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stockBuilder.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: "StockCell", bundle: nil), forCellReuseIdentifier: "StockCell")
        
        setupUI()
        
        stockBuilder.getTrends()
        
        resultsTableController = ResultsTableController()
        resultsTableController.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchTextField.placeholder = NSLocalizedString("Ticker or company name", comment: "")
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.returnKeyType = .done
        
        navigationItem.searchController = searchController
        
        navigationItem.hidesSearchBarWhenScrolling = false
        
        searchController.delegate = self
        
        searchController.searchBar.delegate = self
        
        definesPresentationContext = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? DetailViewController {
            if tableView.indexPathForSelectedRow != nil {
                let stockList = [StockModel](source.values).sorted{$0.ticker < $1.ticker}
                destinationVC.stock = stockList[tableView.indexPathForSelectedRow!.row]
            }
        }
    }
    
    private func setupUI() {
        tableView.separatorStyle = .none
        navigationItem.title = "Stock Screener"
    }
    
    
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        //        stockBuilder.updatePrice(for: source)
    }
    
}

// MARK: - UITableViewDataSource

extension StockViewController: UITableViewDataSource {
    
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
            cell.backgroundColor = UIColor(named: K.Colors.Background.main)
        }
        
        if stockItem.isFavourite {
            let image = UIImage(systemName: "star.fill")!.withTintColor(UIColor(named: K.Colors.Common.isFavourite)!, renderingMode: .alwaysOriginal)
            cell.favouriteButton.setImage(image, for: .normal)
        } else {
            let image = UIImage(systemName: "star.fill")!.withTintColor(UIColor(named: K.Colors.Common.notFavourite)!, renderingMode: .alwaysOriginal)
            cell.favouriteButton.setImage(image, for: .normal)
        }
        
        //TODO: - CrossView Favourites Manager
        cell.callbackOnFavouriteButton = {
            let ticker = stockItem.ticker
            if self.stock[ticker] != nil {
                self.stock[ticker]!.isFavourite = !self.stock[ticker]!.isFavourite
            }
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showDetail", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

//MARK: - UITableViewDelegate

extension StockViewController: UITableViewDelegate {
}

//MARK: - StockBuilderDelegate

extension StockViewController: StockBuilderDelegate {
    
    func didUpdateStockItem(_ stockBuilder: StockBuilder, _ stockItem: StockModel) {
        let queue = DispatchQueue(label: "update stock dictionary", qos: .userInitiated)
        
        queue.sync {
            let key = stockItem.ticker
            if self.stock[key] != nil {
                if let currentPrice = stockItem.currentPrice, self.stock[key]!.currentPrice != currentPrice {
                    self.stock[key]!.currentPrice = currentPrice
                }
                if let previousPrice = stockItem.previousPrice, self.stock[key]!.previousPrice != previousPrice {
                    self.stock[key]!.previousPrice = previousPrice
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            else {
                print(stockItem)
                self.stock[key] = stockItem
            }
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

// MARK: - UISearchBarDelegate

extension StockViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text!.isEmpty {
            //TODO: - Visible lable "No tickers for display"
        } else {
            //TODO: - lable "No tickers for display" hides
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // User tapped the Done button in the keyboard.
        searchController.dismiss(animated: true, completion: nil)
        searchBar.text = ""
    }
    
}

// MARK: - UISearchControllerDelegate

extension StockViewController: UISearchControllerDelegate {
    
    func presentSearchController(_ searchController: UISearchController) {
        searchController.showsSearchResultsController = true
    }
    
}

// MARK: - UISearchResultsUpdating

extension StockViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        
        if let searchQuery = searchController.searchBar.text, searchQuery.isEmpty == false {
        
            var searchResult = stockBuilder.searchStock(for: searchQuery)
        
//        if let resultsController = searchController.searchResultsController as? ResultsTableController {
//            resultsController.result = result
//            resultsController.tableView.reloadData()
//        }
    }
    }
}

// MARK: - ResultsTableControllerDelegate

extension StockViewController: ResultsTableControllerDelegate {
    
    func didSelectStock(stock: StockModel) {
        let detailVC = DetailViewController.detailViewControllerForStock(stock)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func didSetAsFavourite(stock: StockModel) {
        favourites[stock.ticker] = stock
    }
    
    func didUnsetAsFavourite(stock: StockModel) {
        favourites[stock.ticker] = nil
    }
    
}
