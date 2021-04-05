import UIKit

class DetailViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Public Properties
    
    var stock: StockModel!
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        assert(stock != nil, "Stock has no value")
        
        title = stock.ticker
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UINib(nibName: K.chartCell, bundle: nil), forCellReuseIdentifier: K.chartCell)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupUI()
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
    
    private func setupUI() {
        tableView.separatorStyle = .none
        navigationItem.backButtonTitle = "Back" // Don't work??
    }
    
}

//MARK: - UITableViewDataSource

extension DetailViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.chartCell, for: indexPath)
            as! StockChartCell
        cell.setData(for: stock.ticker)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Price change for the last 30 days"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 300
        } else {
            return 50
        }
    }
    
}

//MARK: - UITableViewDelegate

extension DetailViewController: UITableViewDelegate {}
