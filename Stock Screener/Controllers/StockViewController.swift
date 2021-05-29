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
    private var trendingIsBuilded = false
    
    private var trendingStocks = [String: StockModel]()
    private let queue = Constants.Queues.trendingStocksAccess
    
    private var sourceStocks: [String: StockModel] {
        if selectedSegment == .trending {
            let stocks = getTrendingStocks()
            return stocks
        } else {
            return StockFavourite.shared.getFavourite()
        }
    }
    
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
        getFavouriteStocks()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? DetailViewController {
            if tableView.indexPathForSelectedRow != nil {
                let stockList = [StockModel](sourceStocks.values).sorted { $0.ticker < $1.ticker }
                destinationVC.detailedStock = stockList[tableView.indexPathForSelectedRow!.row]
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func reloadTableView() {
        DispatchQueue.main.async {
            if self.trendingIsBuilded,
               self.tableView.isSkeletonActive {
                self.hideSkeleton()
            }
            self.tableView.reloadData()
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(
            UINib(nibName: Constants.Cells.stock, bundle: nil),
            forCellReuseIdentifier: Constants.Cells.stock
        )
        tableView.refreshControl = tableViewRefreshControl
        tableView.contentInset.top = 4
    }
    
    private func setupSearchController() {
        searchController = UISearchController(searchResultsController: resultsTableController)
        
        searchController.searchBar.autocapitalizationType = .none
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.returnKeyType = .search
        definesPresentationContext = true
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        searchController.delegate = self
        searchController.searchBar.delegate = self
    }
    
    private func setupUI() {
        // View
        view.backgroundColor = UIColor.Custom.Brand.main
        
        // Table View
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.Custom.Background.secondary
        tableViewRefreshControl.tintColor = UIColor.Custom.Brand.secondary
        
        // Segments View
        segmentsView.backgroundColor = UIColor.Custom.Brand.main
        
        // Search Bar
        let searchBar = searchController.searchBar
        searchBar.isTranslucent = false
        
        // Search Text Field
        let searchTextField = searchBar.searchTextField
        searchTextField.backgroundColor = UIColor.Custom.Brand.main
        searchTextField.textColor = UIColor.Custom.Text.main
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Ticker or company name",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.Custom.Text.secondary]
        )
        
        if let glassIconView = searchTextField.leftView as? UIImageView {
            glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
            glassIconView.tintColor = UIColor.Custom.Text.main
        }
        
        if let clearButton = searchTextField.value(forKey: "_clearButton") as? UIButton {
            let templateImage =  clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
            clearButton.setImage(templateImage, for: .normal)
            clearButton.tintColor = UIColor.Custom.Text.main
        }
        
        // Navigation Controller
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.tintColor = UIColor.Custom.Text.main
            navigationBar.prefersLargeTitles = true
            navigationBar.barStyle = .black
        }
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.Custom.Brand.main
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.Custom.Text.main]
        appearance.shadowColor = .none
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.title = "Stock Screener"
        navigationItem.largeTitleDisplayMode = .always
        
        let backBarButtton = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButtton
    }
    
    private func setupSegmentButtonUI(_ button: UIButton) {
        guard let title = button.titleLabel else { return }
        
        button.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.left
        button.contentVerticalAlignment = UIControl.ContentVerticalAlignment.bottom
        
        if title.text == selectedSegment.rawValue {
            title.font = UIFont.boldSystemFont(ofSize: 20)
            button.setTitleColor(UIColor.Custom.Text.main, for: .normal)
        } else {
            title.font = UIFont.systemFont(ofSize: 16)
            button.setTitleColor(UIColor.Custom.Text.secondary, for: .normal)
        }
    }
    
    private func setupSegmentButtons() {
        setupSegmentButtonUI(trendingSegmentButton)
        setupSegmentButtonUI(favouriteSegmentButton)
    }
    
    private func setupSkeleton() {
        tableView.isSkeletonable = true
        let gradient = SkeletonGradient(baseColor: UIColor.Custom.Background.secondary)
        let animation = GradientDirection.leftRight.slidingAnimation()
        tableView.showAnimatedGradientSkeleton(usingGradient: gradient, animation: animation)
    }
    
    private func getTrendingStocks() -> [String: StockModel] {
        var stocks = [String: StockModel]()
        queue.sync {
            stocks = self.trendingStocks
        }
        return stocks
    }
    
    private func updateTrendingStocks(stock: StockModel) {
        let ticker = stock.ticker
        queue.sync {
            self.trendingStocks[ticker] = stock
        }
    }
    
    private func hideSkeleton() {
        tableView.hideSkeleton(transition: .none)
    }
    
    private func getFavouriteStocks() {
        StockFavourite.shared.loadFavouriteFromRealm()
    }
    
    private func checkIfStockIsFavourite(_ stock: StockModel) {
        StockFavourite.shared.checkIfTickerIsFavourite(stock: stock) { [weak self] (result) in
            guard let strongSelf = self else { return }
            
            if stock.isFavourite != result {
                var updatedStock = stock
                
                updatedStock.isFavourite.toggle()
                strongSelf.updateTrendingStocks(stock: updatedStock)
                
                strongSelf.reloadTableView()
            }
        }
    }
    
    private func toggleFavourite(for stock: StockModel) {
        var selectedStock = stock
        
        selectedStock.isFavourite.toggle()
        
        selectedStock.isFavourite
            ? StockFavourite.shared.addToFavourite(stock: selectedStock)
            : StockFavourite.shared.removeFromFavourite(stock: selectedStock)
        
        if selectedSegment == .trending {
            updateTrendingStocks(stock: selectedStock)
        }
        
        reloadTableView()
    }
    
    private func getPriceForStocks(stocks: [String: StockModel], segment: StockSegments) {
        for stock in stocks {
            stockManager.getPrice(for: stock.value, segment: segment)
        }
    }
    
    @objc private func refreshPrice(sender: UIRefreshControl) {
        getPriceForStocks(stocks: sourceStocks, segment: selectedSegment)
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
                if !self.trendingIsBuilded,
                   !self.tableView.isSkeletonActive {
                    self.setupSkeleton()
                }
            }
            reloadTableView()
        }
    }
    
    @IBAction func changeSourceToFavourite(_ sender: UIButton) {
        if selectedSegment != .favourite {
            selectedSegment = .favourite
            DispatchQueue.main.async {
                self.setupSegmentButtons()
                if self.tableView.isSkeletonActive {
                    self.hideSkeleton()
                }
            }
            getPriceForStocks(stocks: StockFavourite.shared.getFavourite(), segment: .favourite)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.stock, for: indexPath)
            as! StockCell // swiftlint:disable:this force_cast
        
        // Guard to prevent "Index out of range error" while changing stock segments
        guard sourceStocks.count > indexPath.row else {
            reloadTableView()
            return cell
        }
        
        let stockList = [StockModel](sourceStocks.values).sorted { $0.ticker < $1.ticker }
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
                cell.dayDelta.textColor = UIColor.Custom.Text.ternary
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
        if selectedSegment == .trending {
            checkIfStockIsFavourite(stockItem)
        }
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showDetail", sender: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Fix SkeletonView bug when skeleton isn't hiding on the invisible cell
        if cell.isSkeletonActive,
           trendingIsBuilded,
           !(tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false) {
            cell.hideSkeleton(transition: .none)
        }
    }
}

// MARK: - UITableViewDelegate

extension StockViewController: UITableViewDelegate {}

// MARK: - StockManagerDelegate

extension StockViewController: StockManagerDelegate {
    
    func didUpdateStockItem(_ stock: StockModel, segment: StockSegments?) {
        // Check what source dictionary we should update
        if segment == .trending {
            updateTrendingStocks(stock: stock)
        } else if segment == .favourite {
            StockFavourite.shared.updateFavourite(stock: stock)
        }
        
        reloadTableView()
    }
    
    func didBuildStockItem(_ stock: StockModel, workload: Int) {
        updateTrendingStocks(stock: stock)
        stockManager.getPrice(for: stock, segment: .trending)
        
        // Reload Table View data when all stocks were builded
        let stocks = getTrendingStocks()
        
        if stocks.count == workload {
            trendingIsBuilded = true
            reloadTableView()
        }
    }
    
    func didFailWithError(_ error: StockError) {
        switch error {
        case .tickerPriceError(let ticker):
            print(error.localizedDescription)
            let stocks = getTrendingStocks()
            var stock = stocks[ticker]
            
            guard stock != nil else { return }
            
            if stock!.currentPrice == nil {
                stock!.currentPrice = 0
                
                if selectedSegment == .trending {
                    updateTrendingStocks(stock: stock!)
                } else if selectedSegment == .favourite {
                    StockFavourite.shared.updateFavourite(stock: stock!)
                }
            }
            reloadTableView()
        default:
            print(error.localizedDescription)
        }
    }
}

// MARK: - UISearchBarDelegate

extension StockViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let searchQuery = searchController.searchBar.text,
           !searchQuery.isEmpty {
            if let resultsController = searchController.searchResultsController as? ResultsTableController {
                // Validate a search query with regular expression
                let formattedQuery = searchQuery.replacingOccurrences(
                    of: "[^A-Za-z0-9.,/-()*@!+]+",
                    with: "",
                    options: .regularExpression
                )
                resultsController.searchQuery = formattedQuery
                
                // Clear result of the previous search
                resultsController.clearResults()
                
                // Setup a small delay to perform search only when user has ended typing
                NSObject.cancelPreviousPerformRequests(
                    withTarget: self,
                    selector: #selector(self.performStockSearch),
                    object: searchBar
                )
                perform(#selector(self.performStockSearch), with: searchBar, afterDelay: 0.75)
            }
        } else {
            // Cancel previous search if user clears the search query
            if let resultsController = searchController.searchResultsController as? ResultsTableController {
                NSObject.cancelPreviousPerformRequests(
                    withTarget: self,
                    selector: #selector(self.performStockSearch),
                    object: searchBar
                )
                resultsController.clearResults()
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchQuery = searchController.searchBar.text, searchQuery.isEmpty == false {
            if let resultsController = searchController.searchResultsController as? ResultsTableController {
                
                let formattedQuery = searchQuery.replacingOccurrences(
                    of: "[^A-Za-z0-9.,/-()*@!+]+",
                    with: "",
                    options: .regularExpression
                )
                resultsController.searchQuery = formattedQuery
                
                resultsController.clearResults()
                
                NSObject.cancelPreviousPerformRequests(
                    withTarget: self,
                    selector: #selector(self.performStockSearch),
                    object: searchBar
                )
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
        guard let detailVC = DetailViewController.detailViewControllerForStock(stock) else { return }
        navigationController?.pushViewController(detailVC, animated: false)
    }
}

// MARK: - SkeletonTableViewDataSource

extension StockViewController: SkeletonTableViewDataSource {
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if selectedSegment == .trending {
            let stocks = getTrendingStocks()
            return stocks.count > 0 ? stocks.count : 10
        } else {
            return sourceStocks.count > 0 ? sourceStocks.count : 0
        }
    }
    
    func collectionSkeletonView(
        _ skeletonView: UITableView,
        cellIdentifierForRowAt indexPath: IndexPath
    ) -> ReusableCellIdentifier {
        return Constants.Cells.stock
    }
}
