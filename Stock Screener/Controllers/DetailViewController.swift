import UIKit
import SafariServices

class DetailViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var favouriteButton: UIButton!
    
    // MARK: - Public Properties
    
    var detailedStock: StockModel!
    
    // MARK: - Private Properties
    
    private let stockManager = StockManager()
    
    private var stockNews = [StockNewsModel]()
    
    private var isFavourite = false
    
    private var dataIsSetted: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        assert(detailedStock != nil, "Stock has no value")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupTableView()
        setupUI()
        
        checkIfStockIsFavourite()
        setupFavouriteButton()
        
        stockManager.getNews(for: detailedStock.ticker) { [weak self] (result) in
            guard let strongSelf = self else { return }
            strongSelf.stockNews = result
            DispatchQueue.main.async {
                strongSelf.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Public Methods
    
    static func loadFromStoryboard() -> DetailViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        return storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController
    }
    
    class func detailViewControllerForStock(_ stock: StockModel) -> UIViewController {
        let detailViewController = loadFromStoryboard()
        detailViewController!.detailedStock = stock
        return detailViewController!
    }
    
    // MARK: - Private Methods
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: K.Cells.chart, bundle: nil), forCellReuseIdentifier: K.Cells.chart)
        tableView.register(UINib(nibName: K.Cells.news, bundle: nil), forCellReuseIdentifier: K.Cells.news)
    }
    
    private func setupUI() {
        title = detailedStock.ticker
        
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        
        let backBarButtton = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButtton
    }
    
    private func setupFavouriteButton() {
        if isFavourite {
            let image = UIImage(systemName: "star.fill")!.withTintColor(K.Colors.Common.isFavourite, renderingMode: .alwaysOriginal)
            favouriteButton.setImage(image, for: .normal)
        } else {
            let image = UIImage(systemName: "star.fill")!.withTintColor(K.Colors.Common.notFavourite, renderingMode: .alwaysOriginal)
            favouriteButton.setImage(image, for: .normal)
        }
    }
    
    private func showNewsWebsite(url: String) {
        if let url = URL(string: url) {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true
            
            let vc = SFSafariViewController(url: url, configuration: config)
            present(vc, animated: true)
        }
    }
    
    private func checkIfStockIsFavourite() {
        StockFavourite.shared.checkIfTickerIsFavourite(stock: detailedStock) { [weak self] (result) in
            guard let strongSelf = self else { return }
            strongSelf.isFavourite = result
        }
    }
    
    //MARK: - IBActions
    
    @IBAction func setFavourite(_ sender: UIButton) {
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

//MARK: - UITableViewDataSource

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
            let cell = tableView.dequeueReusableCell(withIdentifier: K.Cells.chart, for: indexPath)
                as! StockChartCell
            
            if cell.stockChartView.data == nil {
                cell.setData(for: detailedStock.ticker) { (result) in
                    self.dataIsSetted = true
                }
                cell.stockChartView.isHidden = true
                cell.activityIndicator.startAnimating()
            } else {
                cell.activityIndicator.stopAnimating()
                cell.stockChartView.isHidden = false
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: K.Cells.news, for: indexPath)
                as! StockNewsCell
            
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
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Monthly price change"
        }
        if section == 1 {
            return "Latest News"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            showNewsWebsite(url: stockNews[indexPath.row].url)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
}

//MARK: - UITableViewDelegate

extension DetailViewController: UITableViewDelegate {}
