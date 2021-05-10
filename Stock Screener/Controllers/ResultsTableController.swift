import UIKit

protocol ResultsTableControllerDelegate {
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
    var delegate: ResultsTableControllerDelegate?
    
    // MARK: - Private Properties
    
    private var formatter = StockFormatter()
    private var stockManager = StockManager()
    
    private var searchResultStocks = [String: StockModel]()
    
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
        return searchResultStocks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.Cells.stock, for: indexPath)
            as! StockCell
        
        let stockList = [StockModel](searchResultStocks.values).sorted{$0.ticker < $1.ticker}
        let stockItem = stockList[indexPath.row]
        
        cell.ticker.text = stockItem.ticker
        cell.companyName.text = stockItem.companyName
        cell.currentPrice.text = stockItem.formattedPrice
        cell.dayDelta.text = stockItem.formattedDayDelta
        
        if let delta = stockItem.delta {
            if delta >= 0 {
                cell.dayDelta.textColor = K.Colors.Common.green
            } else if delta < 0 {
                cell.dayDelta.textColor = K.Colors.Common.red
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
        
        checkIfStockIsFavourite(stockItem)
        
        if stockItem.isFavourite {
            let image = UIImage(systemName: "star.fill")!.withTintColor(K.Colors.Common.isFavourite, renderingMode: .alwaysOriginal)
            cell.favouriteButton.setImage(image, for: .normal)
        } else {
            let image = UIImage(systemName: "star.fill")!.withTintColor(K.Colors.Common.notFavourite, renderingMode: .alwaysOriginal)
            cell.favouriteButton.setImage(image, for: .normal)
        }
        
        cell.callbackOnFavouriteButton = {
            self.setupStockAsFavourite(for: stockItem)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.indexPathForSelectedRow != nil {
            let stockList = [StockModel](searchResultStocks.values).sorted{ $0.ticker < $1.ticker }
            let stock = stockList[tableView.indexPathForSelectedRow!.row]
            delegate?.didSelectStock(stock: stock)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Public Methods
    
    func clearResults() {
        placeholder.removeFromSuperview()
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
        searchResultStocks.removeAll()
        reloadTableView()
    }
    
    func searchStock() {
        searchResultStocks.removeAll()
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
        tableView.register(UINib(nibName: K.Cells.stock, bundle: nil), forCellReuseIdentifier: K.Cells.stock)
    }
    
    private func setupUI() {
        tableView.separatorStyle = .none
        tableView.backgroundColor = K.Colors.Background.secondary
        
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.barStyle = .black
        }
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = K.Colors.Background.main
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
    
    private func checkIfStockIsFavourite(_ stockItem: StockModel) {
        StockFavourite.shared.checkIfTickerIsFavourite(stock: stockItem) { [weak self] (result) in
            let ticker = stockItem.ticker
            
            guard let strongSelf = self,
                  strongSelf.searchResultStocks[ticker] != nil else { return }
            
            if result,
               !stockItem.isFavourite {
                strongSelf.searchResultStocks[ticker]!.isFavourite = true
                strongSelf.reloadTableView()
            } else if !result,
                      stockItem.isFavourite {
                strongSelf.searchResultStocks[ticker]!.isFavourite = false
                strongSelf.reloadTableView()
            }
        }
    }
    
    private func setupStockAsFavourite(for stock: StockModel) {
        let queue = K.Queues.searchResultStocksAccess
        
        let ticker = stock.ticker
        
        var selectedStock = stock
        selectedStock.isFavourite = !selectedStock.isFavourite
        
        queue.sync {
            if self.searchResultStocks[ticker] != nil {
                self.searchResultStocks[ticker]!.isFavourite = !self.searchResultStocks[ticker]!.isFavourite
            }
        }
        
        if selectedStock.isFavourite {
            StockFavourite.shared.addToFavourite(stock: selectedStock)
        } else {
            StockFavourite.shared.removeFromFavourite(stock: selectedStock)
        }
        
        reloadTableView()
    }
}

//MARK: - StockManagerDelegate

extension ResultsTableController: StockManagerDelegate {
    
    func didUpdateStockItem(_ stock: StockModel, segment: StockSegments?) {
        let queue = K.Queues.searchResultStocksAccess
        let ticker = stock.ticker
        var updatedStocks = [String: StockModel]()
        
        queue.sync {
            updatedStocks = self.searchResultStocks
        }
        
        guard updatedStocks[ticker] != nil else { return }
        
        if let currentPrice = stock.currentPrice, updatedStocks[ticker]!.currentPrice != currentPrice {
            updatedStocks[ticker]!.currentPrice = currentPrice
        }
        if let previousPrice = stock.previousPrice, updatedStocks[ticker]!.previousPrice != previousPrice {
            updatedStocks[ticker]!.previousPrice = previousPrice
        }
        
        queue.sync {
            self.searchResultStocks = updatedStocks
        }
        
        reloadTableView()
    }
    
    func didBuildStockItem(_ stock: StockModel) {
        let queue = K.Queues.searchResultStocksAccess
        let ticker = stock.ticker
        
        queue.sync {
            self.searchResultStocks[ticker] = stock
        }
        
        stockManager.getPrice(for: stock, segment: nil)
    }
    
    func didEndBuilding() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
        reloadTableView()
    }
    
    func didFailWithError(_ error: StockError) {
        switch error {
        case .tickerPriceError(let ticker):
            print(error.localizedDescription)
            if searchResultStocks[ticker] != nil {
                if searchResultStocks[ticker]!.currentPrice == nil {
                    searchResultStocks[ticker]!.currentPrice = 0
                }
                reloadTableView()
            }
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
