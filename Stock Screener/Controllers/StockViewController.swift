import UIKit
import SkeletonView

class StockViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var trendingSegmentButton: UIButton!
    @IBOutlet var favouriteSegmentButton: UIButton!
    @IBOutlet var segmentsView: UIView!
    
    // MARK: - Private Properties
    
    private let tableViewRefreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshPrice(sender:)), for: .valueChanged)
        return refreshControl
    }()
    
    private var searchController: UISearchController!
    private var resultsTableController: ResultsTableController!
    private var formatter = StockFormatter()
    private var stockManager = StockManager()
    
    private var selectedSegment: StockSegments = .trending
    
    private var trendingStocks = [String: StockModel]()
    private var sourceStocks: [String: StockModel] {
        if selectedSegment == .trending {
            return trendingStocks
        } else {
            return StockFavourite.shared.getFavouriteStocks()
        }
    }
    
    private var trendingIsBuilded = false
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        reloadTableView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stockManager.delegate = self
        
        resultsTableController = ResultsTableController()
        resultsTableController.delegate = self
        
        setupTableView()
        setupSearchController()
        setupUI()
        setupSegmentButtons()
        setupSkeleton() 
        
        stockManager.getTrends()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? DetailViewController {
            if tableView.indexPathForSelectedRow != nil {
                let stockList = [StockModel](sourceStocks.values).sorted{ $0.ticker < $1.ticker }
                destinationVC.detailedStock = stockList[tableView.indexPathForSelectedRow!.row]
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func reloadTableView() {
        DispatchQueue.main.async {
            if self.trendingIsBuilded, self.tableView.isSkeletonActive {
                self.hideSkeleton()
            }
            self.tableView.reloadData()
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: K.Cells.stock, bundle: nil), forCellReuseIdentifier: K.Cells.stock)
        tableView.refreshControl = tableViewRefreshControl
    }
    
    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: resultsTableController)
        
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
    
    private func setupUI() {
        view.backgroundColor = K.Colors.Brand.ternary
        
        tableView.separatorStyle = .none
        tableView.backgroundColor = K.Colors.Background.main
        
        segmentsView.backgroundColor = K.Colors.Brand.ternary
        
        navigationItem.title = "Stock"
        
        self.navigationController!.navigationBar.tintColor = K.Colors.Brand.main
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = K.Colors.Brand.ternary
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        
        let backBarButtton = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButtton
    }
    
    private func setupSegmentButtonUI(_ button: UIButton) {
        guard let title = button.titleLabel else { return }
        if title.text == selectedSegment.rawValue {
            title.font = UIFont.boldSystemFont(ofSize: 20)
            button.setTitleColor(.black, for: .normal)
        } else {
            title.font = UIFont.systemFont(ofSize: 16)
            button.setTitleColor(.gray, for: .normal)
        }
    }
    
    private func setupSegmentButtons() {
        setupSegmentButtonUI(trendingSegmentButton)
        setupSegmentButtonUI(favouriteSegmentButton)
    }
    
    private func setupSkeleton() {
        tableView.isSkeletonable = true
        let gradient = SkeletonGradient(baseColor: K.Colors.Brand.ternary)
        tableView.showAnimatedGradientSkeleton(usingGradient: gradient)
    }
    
    private func hideSkeleton() {
            tableView.hideSkeleton(transition: .crossDissolve(0.25))
    }
    
    private func checkIfStockIsFavourite(_ stockItem: StockModel) {
        StockFavourite.shared.checkIfTickerIsFavourite(stock: stockItem) { [weak self] (result) in
            let ticker = stockItem.ticker
            
            guard let strongSelf = self,
                  strongSelf.trendingStocks[ticker] != nil else { return }
            
            if result,
               !stockItem.isFavourite {
                strongSelf.trendingStocks[ticker]!.isFavourite = true
                strongSelf.reloadTableView()
            } else if !result,
                      stockItem.isFavourite {
                strongSelf.trendingStocks[ticker]!.isFavourite = false
                strongSelf.reloadTableView()
            }
        }
    }
    
    private func setupStockAsFavourite(for stock: StockModel) {
        let queue = K.Queues.trendingStocksAccess
        
        let ticker = stock.ticker
        
        var selectedStock = stock
        selectedStock.isFavourite = !selectedStock.isFavourite
        
        queue.sync {
            if self.trendingStocks[ticker] != nil {
                self.trendingStocks[ticker]!.isFavourite = !self.trendingStocks[ticker]!.isFavourite
            }
        }
        
        if selectedStock.isFavourite {
            StockFavourite.shared.addToFavourite(stock: selectedStock)
        } else {
            StockFavourite.shared.removeFromFavourite(stock: selectedStock)
        }
        
        reloadTableView()
    }
    
    @objc private func refreshPrice(sender: UIRefreshControl) {
        for stock in sourceStocks {
            stockManager.getPrice(for: stock.value, segment: selectedSegment)
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
             sender.endRefreshing()
        }
    }
    
    @objc private func performStockSearch() {
        resultsTableController.searchStock()
    }
    
    // MARK: - IBActions
    
    @IBAction func changeSourceToTrending(_ sender: UIButton) {
        if selectedSegment != .trending {
            selectedSegment = .trending
            DispatchQueue.main.async {
                self.setupSegmentButtons()
            }
            reloadTableView()
        }
    }
    
    @IBAction func changeSourceToFavourite(_ sender: UIButton) {
        if selectedSegment != .favourite {
            selectedSegment = .favourite
            DispatchQueue.main.async {
                self.setupSegmentButtons()
            }
            reloadTableView()
        }
    }
    
}

// MARK: - UITableViewDataSource

extension StockViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sourceStocks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.Cells.stock, for: indexPath)
            as! StockCell
        
        guard sourceStocks.count > 0 else { return cell }
        
        let stockList = [StockModel](sourceStocks.values).sorted{ $0.ticker < $1.ticker }
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
        
        if selectedSegment == .trending {
            checkIfStockIsFavourite(stockItem)
        }
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showDetail", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if cell.isSkeletonActive, trendingIsBuilded == true {
            cell.hideSkeleton(transition: .crossDissolve(0.25))
        }
    }
    
}

//MARK: - UITableViewDelegate

extension StockViewController: UITableViewDelegate {}

//MARK: - StockManagerDelegate

extension StockViewController: StockManagerDelegate {
    
    func didUpdateStockItem(_ stock: StockModel, segment: StockSegments?) {
        let queue = K.Queues.trendingStocksAccess
        let ticker = stock.ticker
        var updatedStocks = [String: StockModel]()
        
        if segment == .trending {
            queue.sync {
                updatedStocks = self.trendingStocks
            }
        } else if segment == .favourite {
            updatedStocks = StockFavourite.shared.getFavouriteStocks()
        }
        
        guard updatedStocks[ticker] != nil else { return }
        
        if let currentPrice = stock.currentPrice, updatedStocks[ticker]!.currentPrice != currentPrice {
            updatedStocks[ticker]!.currentPrice = currentPrice
        }
        if let previousPrice = stock.previousPrice, updatedStocks[ticker]!.previousPrice != previousPrice {
            updatedStocks[ticker]!.previousPrice = previousPrice
        }
        
        if segment == .trending {
            queue.sync {
                self.trendingStocks = updatedStocks
            }
        } else if segment == .favourite {
            StockFavourite.shared.updateFavouriteStocks(to: updatedStocks)
        }
        
        reloadTableView()
    }
    
    func didBuildStockItem(_ stock: StockModel) {
        let queue = K.Queues.trendingStocksAccess
        let ticker = stock.ticker
        
        queue.sync {
            self.trendingStocks[ticker] = stock
        }
        
        stockManager.getPrice(for: stock, segment: .trending)
    }
    
    func didEndBuilding() {
        trendingIsBuilded = true
        reloadTableView()
    }
    
    func didFailWithError(_ error: StockError) {
        switch error {
        case .tickerPriceError(let ticker):
            print(error.localizedDescription)
            if trendingStocks[ticker] != nil {
                if trendingStocks[ticker]!.currentPrice == nil {
                    trendingStocks[ticker]!.currentPrice = 0
                }
                reloadTableView()
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

// MARK: - ResultsTableControllerDelegate

extension StockViewController: ResultsTableControllerDelegate {
    
    func didSelectStock(stock: StockModel) {
        let detailVC = DetailViewController.detailViewControllerForStock(stock)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
}

//MARK: - SkeletonTableViewDataSource

extension StockViewController: SkeletonTableViewDataSource {
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedSegment == .trending {
            let queue = K.Queues.trendingStocksAccess
            var count = 0
            queue.sync {
                count = trendingStocks.count
            }
            return count > 0 ? count : 10
        } else {
            return sourceStocks.count > 0 ? sourceStocks.count : 0
        }
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return K.Cells.stock
    }
    
}
