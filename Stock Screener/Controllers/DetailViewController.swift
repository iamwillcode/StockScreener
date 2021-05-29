import UIKit
import SafariServices

class DetailViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var favouriteButton: UIButton!
    @IBOutlet var titleView: UIView!
    @IBOutlet var ticker: UILabel!
    @IBOutlet var companyName: UILabel!
    @IBOutlet var currentPrice: UILabel!
    @IBOutlet var dayDelta: UILabel!
    
    // MARK: - Public Properties
    
    var detailedStock: StockModel!
    
    // MARK: - Private Properties
    
    private let stockManager = StockManager()
    
    private var stockNews = [StockNewsModel]()
    
    private var isFavourite = false
    
    // MARK: - Lifecycle
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupTitle()
        setupTableView()
        setupUI()
        
        checkIfStockIsFavourite()
        setupFavouriteButton()
        
        stockManager.getNews(for: detailedStock.ticker) { [weak self] (result) in
            guard let strongSelf = self else { return }
            strongSelf.stockNews = result
            strongSelf.reloadTableView()
        }
    }
    
    // MARK: - Public Methods
    
    static func loadFromStoryboard() -> DetailViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        return storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController
    }
    
    class func detailViewControllerForStock(_ stock: StockModel) -> UIViewController? {
        let detailViewController = loadFromStoryboard()
        guard let detailVC = detailViewController else { return nil }
        detailVC.detailedStock = stock
        return detailVC
    }
    
    // MARK: - Private Methods
    
    private func setupTitle() {
        ticker.text = detailedStock.ticker
        companyName.text = detailedStock.companyName
        currentPrice.text = detailedStock.formattedPrice
        dayDelta.text = detailedStock.formattedDayDelta
        
        if let delta = detailedStock.delta {
            if delta >= 0 {
                dayDelta.textColor = UIColor.Custom.Common.green
            } else if delta < 0 {
                dayDelta.textColor = UIColor.Custom.Common.red
            } else {
                dayDelta.textColor = UIColor.Custom.Text.ternary
            }
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StockChartCell.self, forCellReuseIdentifier: Constants.Cells.chart)
        tableView.register(
            UINib(nibName: Constants.Cells.news, bundle: nil),
            forCellReuseIdentifier: Constants.Cells.news
        )
    }
    
    private func setupUI() {
        // Title View
        titleView.backgroundColor = UIColor.Custom.Brand.secondary
        
        // Labels
        ticker.textColor = UIColor.Custom.Text.main
        companyName.textColor = UIColor.Custom.Text.main
        currentPrice.textColor = UIColor.Custom.Text.main
        
        ticker.font = UIFont.systemFont(ofSize: 30, weight: .black)
        companyName.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        currentPrice.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        dayDelta.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        
        // Table View
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.Custom.Background.secondary
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Navigation Controller
        if let navigationBar = navigationController?.navigationBar {
            navigationBar.tintColor = UIColor.Custom.Text.main
            navigationBar.barStyle = .black
        }
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.Custom.Brand.main
        appearance.shadowColor = .none
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.largeTitleDisplayMode = .never
        
        let backBarButtton = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButtton
    }
    
    private func setupFavouriteButton() {
        if isFavourite {
            let image = UIImage(systemName: "star.fill")!
                .withTintColor(UIColor.Custom.Common.isFavourite, renderingMode: .alwaysOriginal)
            favouriteButton.setImage(image, for: .normal)
        } else {
            let image = UIImage(systemName: "star.fill")!
                .withTintColor(UIColor.Custom.Background.main, renderingMode: .alwaysOriginal)
            favouriteButton.setImage(image, for: .normal)
        }
        
        favouriteButton.contentVerticalAlignment = .fill
        favouriteButton.contentHorizontalAlignment = .fill
        favouriteButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
    private func showNewsWebsite(url: String) {
        if let url = URL(string: url) {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true
            
            let vc = SFSafariViewController(url: url, configuration: config) // swiftlint:disable:this identifier_name
            present(vc, animated: true)
        }
    }
    
    private func checkIfStockIsFavourite() {
        StockFavourite.shared.checkIfTickerIsFavourite(stock: detailedStock) { [weak self] (result) in
            guard let strongSelf = self else { return }
            strongSelf.isFavourite = result
        }
    }
    
    // Reloads only Newsfeed section
    private func reloadTableView() {
        DispatchQueue.main.async {
            self.tableView.reloadSections([1], with: .fade)
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func toggleFavourite(_ sender: UIButton) {
        if isFavourite {
            isFavourite = false
            detailedStock.isFavourite = false
            StockFavourite.shared.removeFromFavourite(stock: detailedStock)
            setupFavouriteButton()
        } else {
            isFavourite = true
            detailedStock.isFavourite = true
            StockFavourite.shared.addToFavourite(stock: detailedStock)
            setupFavouriteButton()
        }
    }
}

// MARK: - UITableViewDataSource

extension DetailViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return stockNews.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.chart, for: indexPath)
                as! StockChartCell // swiftlint:disable:this force_cast
            
            cell.ticker = detailedStock.ticker
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Cells.news, for: indexPath)
                as! StockNewsCell // swiftlint:disable:this force_cast
            
            let stockNewsItem = stockNews[indexPath.row]
            
            cell.source.text = stockNewsItem.source
            cell.headline.text = stockNewsItem.headline
            cell.age.text = "\(stockNewsItem.age) ago"
            
            if stockNewsItem.summary == "No summary available." {
                cell.summary.isHidden = true
            } else {
                cell.summary.text = stockNewsItem.summary
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            showNewsWebsite(url: stockNews[indexPath.row].url)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate

extension DetailViewController: UITableViewDelegate {}
