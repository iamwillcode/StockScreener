import UIKit

class DetailViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Public Properties
    
    var stock: StockModel!
    
    // MARK: - Private Properties
    
    private let stockBuilder = StockBuilder()
    private var stockNews = [StockNewsModel]()
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
        
        assert(stock != nil, "Stock has no value")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupTableView()
        setupUI()
        
        stockBuilder.getNews(for: stock.ticker) { (result) in
            self.stockNews = result
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? WebViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.url = URL(string: stockNews[indexPath.row].url)
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
        detailViewController!.stock = stock
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
        title = stock.ticker
        
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension
        
        let backBarButtton = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backBarButtton
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
                cell.setData(for: stock.ticker) { (result) in
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
            cell.summary.text = stockNewsItem.summary
            cell.age.text = "\(stockNewsItem.age) ago"
            
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
            self.performSegue(withIdentifier: "openWebView", sender: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
}

//MARK: - UITableViewDelegate

extension DetailViewController: UITableViewDelegate {}
