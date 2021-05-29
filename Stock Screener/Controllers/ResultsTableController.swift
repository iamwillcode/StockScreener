import UIKit

protocol ResultsTableControllerDelegate: AnyObject {
    func didSelectStock(stock: StockModel)
}

class ResultsTableController: UITableViewController {
    
    // MARK: - Public Properties
    
    lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.hidesWhenStopped = true
        indicator.color = .black
        indicator.style = .medium
        return indicator
    }()
    
    lazy var placeholder: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    var searchQuery: String = ""
    weak var delegate: ResultsTableControllerDelegate?
    
    // MARK: - Private Properties
    
    private var formatter = StockFormatter()
    private var stockManager = StockManager()
    
    private var searchResultStocks = [String: StockModel]()
    private let queue = Constants.Queues.searchResultStocksAccess
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        reloadTableView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stockManager.delegate = self
        
        setupTableView()
        setupActivityIndicator()
        setupUI()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let stocks = getSearchResultStocks()
        return stocks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.stock, for: indexPath)
            as! StockCell // swiftlint:disable:this force_cast
        
        let stocks = getSearchResultStocks()
        let stockList = [StockModel](stocks.values).sorted { $0.ticker < $1.ticker }
        let stockItem = stockList[indexPath.row]
        
        // Setup Cell's labels
        cell.ticker.text = stockItem.ticker
        cell.companyName.text = stockItem.companyName
        cell.currentPrice.text = stockItem.formattedPrice
        cell.dayDelta.text = stockItem.formattedDayDelta
        
        // Setup delta text color depending on it's value
        if let delta = stockItem.delta {
            if delta >= 0 {
                cell.dayDelta.textColor = UIColor.Custom.Common.green
            } else if delta < 0 {
                cell.dayDelta.textColor = UIColor.Custom.Common.red
            } else {
                cell.dayDelta.textColor = .black
            }
        }
        
        // Setup activity indicator while price is loading
        switch stockItem.currentPrice {
        case nil:
            cell.activityIndicator.startAnimating()
        default:
            cell.activityIndicator.stopAnimating()
        }
        
        // Setup placeholder if there is no proper logo
        if let logo = stockItem.logo {
            cell.companyLogo.image = logo
        } else {
            cell.companyLogo.image = UIImage(named: Constants.defaultLogo)
        }
        
        // Setup stock's Favourite property
        checkIfStockIsFavourite(stockItem)
        
        // Setup favourite button image
        if stockItem.isFavourite {
            let image = UIImage(systemName: "star.fill")!
                .withTintColor(UIColor.Custom.Common.isFavourite, renderingMode: .alwaysOriginal)
            cell.favouriteButton.setImage(image, for: .normal)
        } else {
            let image = UIImage(systemName: "star.fill")!
                .withTintColor(UIColor.Custom.Common.notFavourite, renderingMode: .alwaysOriginal)
            cell.favouriteButton.setImage(image, for: .normal)
        }
        
        // Setup favourite button action
        cell.callbackOnFavouriteButton = {
            self.toggleFavourite(for: stockItem)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Perform segue to the Detail View Controller by selecting a cell
        if tableView.indexPathForSelectedRow != nil {
            let stocks = getSearchResultStocks()
            let stockList = [StockModel](stocks.values).sorted { $0.ticker < $1.ticker }
            let stock = stockList[tableView.indexPathForSelectedRow!.row]
            delegate?.didSelectStock(stock: stock)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Public Methods
    
    /// Clears search results, placeholder and activity indicator from the View
    func clearResults() {
        placeholder.removeFromSuperview()
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
        clearSearchResultStocks()
        reloadTableView()
    }
    
    /// Performs a search with specified search query
    func searchStock() {
        clearSearchResultStocks()
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
        }
        stockManager.search(for: searchQuery)
    }
    
    // MARK: - Private Methods
    
    private func reloadTableView() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func setupTableView() {
        tableView.register(
            UINib(nibName: Constants.Cells.stock, bundle: nil),
            forCellReuseIdentifier: Constants.Cells.stock
        )
    }
    
    private func setupUI() {
        // Table View
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.Custom.Background.secondary
        
        // Navigation Controller
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.barStyle = .black
        }
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.Custom.Background.main
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
    }
    
    private func setupActivityIndicator() {
        tableView.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 20).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 50).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    private func setupPlaceholder(text: String) {
        tableView.addSubview(placeholder)
        placeholder.text = text
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        placeholder.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 20).isActive = true
        placeholder.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        placeholder.heightAnchor.constraint(equalToConstant: 50).isActive = true
        placeholder.widthAnchor.constraint(equalTo: tableView.widthAnchor).isActive = true
    }
    
    private func getSearchResultStocks() -> [String: StockModel] {
        var stocks = [String: StockModel]()
        queue.sync {
            stocks = self.searchResultStocks
        }
        return stocks
    }
    
    private func updateSearchResultStocks(stock: StockModel) {
        let ticker = stock.ticker
        queue.sync {
            self.searchResultStocks[ticker] = stock
        }
    }
    
    private func clearSearchResultStocks() {
        queue.sync {
            self.searchResultStocks.removeAll()
        }
    }
    
    private func checkIfStockIsFavourite(_ stock: StockModel) {
        StockFavourite.shared.checkIfTickerIsFavourite(stock: stock) { [weak self] (result) in
            guard let strongSelf = self else { return }
            
            if stock.isFavourite != result {
                var updatedStock = stock
                
                updatedStock.isFavourite.toggle()
                strongSelf.updateSearchResultStocks(stock: updatedStock)
                
                strongSelf.reloadTableView()
            }
        }
    }
    
    private func toggleFavourite(for stock: StockModel) {
        var selectedStock = stock
        
        selectedStock.isFavourite.toggle()
        
        updateSearchResultStocks(stock: selectedStock)
        
        selectedStock.isFavourite
            ? StockFavourite.shared.addToFavourite(stock: selectedStock)
            : StockFavourite.shared.removeFromFavourite(stock: selectedStock)
        
        reloadTableView()
    }
}

// MARK: - StockManagerDelegate

extension ResultsTableController: StockManagerDelegate {
    
    func didUpdateStockItem(_ stock: StockModel, segment: StockSegments?) {
        updateSearchResultStocks(stock: stock)
        
        reloadTableView()
    }
    
    func didBuildStockItem(_ stock: StockModel, workload: Int) {
        updateSearchResultStocks(stock: stock)
        stockManager.getPrice(for: stock, segment: nil)
        
        // Reload Table View data when all stocks were builded
        let stocks = getSearchResultStocks()
        
        if stocks.count == workload {
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            reloadTableView()
        }
    }
    
    func didFailWithError(_ error: StockError) {
        switch error {
        case .tickerPriceError(let ticker):
            print(error.localizedDescription)
            let stocks = getSearchResultStocks()
            var stock = stocks[ticker]
            
            guard stock != nil else { return }
            
            if stock!.currentPrice == nil {
                stock!.currentPrice = 0
                updateSearchResultStocks(stock: stock!)
            }
            reloadTableView()
        case .searchError(let ticker):
            activityIndicator.stopAnimating()
            print(error.localizedDescription)
            let text = "No results for \"\(ticker)\""
            setupPlaceholder(text: text)
        default:
            print(error.localizedDescription)
        }
    }
}
