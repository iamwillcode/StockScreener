import UIKit

class StockViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var segments: UISegmentedControl!
    
    // MARK: - Private Properties
    
    private let tableViewRefreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshPrice(sender:)), for: .valueChanged)
        return refreshControl
    }()
    
    private var trending = [String: StockModel]()
    private var searchController: UISearchController!
    private var resultsTableController: ResultsTableController!
    private var formatter = StockFormatter()
    private var stockBuilder = StockBuilder()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stockBuilder.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: K.stockCell, bundle: nil), forCellReuseIdentifier: K.stockCell)
        tableView.refreshControl = tableViewRefreshControl
        
        resultsTableController = ResultsTableController()
        resultsTableController.delegate = self
        
        setupUI()
        setupSearchController()
        
        stockBuilder.getTrends()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? DetailViewController {
            if tableView.indexPathForSelectedRow != nil {
                let stockList = [StockModel](source.values).sorted{$0.ticker < $1.ticker}
                destinationVC.stock = stockList[tableView.indexPathForSelectedRow!.row]
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(named: K.Colors.Background.main)
        
        view.backgroundColor = UIColor(named: K.Colors.Brand.ternary)
        
        segments.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segments.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .normal)
        segments.selectedSegmentTintColor = UIColor(named: K.Colors.Brand.main)
        segments.layer.borderWidth = 0
        segments.backgroundColor = UIColor(named: K.Colors.Brand.ternary)

        navigationItem.title = "Stock Screener 📈"

    
        self.navigationController!.navigationBar.tintColor = UIColor(named: K.Colors.Brand.main)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: K.Colors.Brand.ternary)
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
   
        let backBarButtton = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButtton
    }
    
    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchTextField.placeholder = NSLocalizedString("Ticker or company name", comment: "")
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.returnKeyType = .search
        definesPresentationContext = true
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        searchController.delegate = self
        searchController.searchBar.delegate = self
    }
    
    private func selectStockAsFavourite(for stock: StockModel) {
        let ticker = stock.ticker
        
        var selectedStock = stock
        selectedStock.isFavourite = !selectedStock.isFavourite
        
        if self.trending[ticker] != nil {
            self.trending[ticker]!.isFavourite = !self.trending[ticker]!.isFavourite
        }
        
        if selectedStock.isFavourite {
            StockFavourite.shared.addToFavourite(stock: selectedStock)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } else {
            StockFavourite.shared.removeFromFavourite(stock: selectedStock)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    @objc private func refreshPrice(sender: UIRefreshControl) {
        stockBuilder.updatePrice(for: source)
        sender.endRefreshing()
    }
    
    @objc private func performStockSearch() {
        resultsTableController.searchStock()
    }
    
    // MARK: - IBActions
    
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
}

// MARK: - UITableViewDataSource

extension StockViewController: UITableViewDataSource {
    
    var source: [String: StockModel] {
        get {
            if segments.selectedSegmentIndex == 0 {
                return self.trending
            } else {
                return StockFavourite.shared.favourite
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let stockList = [StockModel](source.values).sorted{$0.ticker < $1.ticker}
        let stockItem = stockList[indexPath.row]
        
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
            cell.backgroundColor = UIColor(named: K.Colors.Background.secondary)
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
            self.selectStockAsFavourite(for: stockItem)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showDetail", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let stockList = [StockModel](source.values).sorted{$0.ticker < $1.ticker}
        let stockItem = stockList[indexPath.row]
        
        StockFavourite.shared.checkIfTickerIsFavourite(stock: stockItem) { (result) in
            if result {
                let ticker = stockItem.ticker
                self.trending[ticker]?.isFavourite = true
            }
        }
    }
    
}

//MARK: - UITableViewDelegate

extension StockViewController: UITableViewDelegate {}

//MARK: - StockBuilderDelegate

extension StockViewController: StockBuilderDelegate {
    
    func didUpdateStockItem(_ stockBuilder: StockBuilder, _ stockItem: StockModel) {
        let queue = Config.Queues.stockDictionaryAccess
        
        queue.sync {
            let key = stockItem.ticker
            if self.trending[key] != nil {
                if let currentPrice = stockItem.currentPrice, self.trending[key]!.currentPrice != currentPrice {
                    self.trending[key]!.currentPrice = currentPrice
                }
                if let previousPrice = stockItem.previousPrice, self.trending[key]!.previousPrice != previousPrice {
                    self.trending[key]!.previousPrice = previousPrice
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            else {
                self.trending[key] = stockItem
            }
        }
    }
    
    func didEndBuilding(_ stockBuilder: StockBuilder, _ amount: Int) {
        let queue = Config.Queues.stockDictionaryAccess
        
        queue.sync {
            if amount == trending.count {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                stockBuilder.updatePrice(for: trending)
            }
        }
    }
    
    func didFailWithError(_ stockBuilder: StockBuilder, error: StockError) {
        switch error {
        case .tickerPriceError(let ticker):
            print(error.localizedDescription)
            if trending[ticker] != nil {
                if trending[ticker]!.currentPrice == nil {
                    trending[ticker]!.currentPrice = 0
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

// MARK: - UISearchBarDelegate

extension StockViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let searchQuery = searchController.searchBar.text, searchQuery.isEmpty == false {
            if let resultsController = searchController.searchResultsController as? ResultsTableController {
                let formattedQuery = searchQuery.replacingOccurrences(of: "[^A-Za-z0-9.,/-()*@!+]+", with: "", options: .regularExpression)
                resultsController.searchQuery = formattedQuery
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.performStockSearch), object: searchBar)
                perform(#selector(self.performStockSearch), with: searchBar, afterDelay: 0.75)
            }
        } else {
            if let resultsController = searchController.searchResultsController as? ResultsTableController {
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.performStockSearch), object: searchBar)
                resultsController.clearResults()
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchQuery = searchController.searchBar.text, searchQuery.isEmpty == false {
            if let resultsController = searchController.searchResultsController as? ResultsTableController {
                let formattedQuery = searchQuery.replacingOccurrences(of: "[^A-Za-z0-9.,/-()*@!+]+", with: "", options: .regularExpression)
                resultsController.searchQuery = formattedQuery
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.performStockSearch), object: searchBar)
                performStockSearch()
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController.dismiss(animated: true, completion: nil)
        searchBar.text = ""
    }
    
}

// MARK: - UISearchControllerDelegate

extension StockViewController: UISearchControllerDelegate {
    
    func presentSearchController(_ searchController: UISearchController) {
        searchController.showsSearchResultsController = true
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        if let resultsController = searchController.searchResultsController as? ResultsTableController {
            resultsController.clearResults()
        }
    }
    
}

// MARK: - UISearchResultsUpdating

extension StockViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
    }
    
}

// MARK: - ResultsTableControllerDelegate

extension StockViewController: ResultsTableControllerDelegate {
    
    func didSelectStock(stock: StockModel) {
        let detailVC = DetailViewController.detailViewControllerForStock(stock)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
}
