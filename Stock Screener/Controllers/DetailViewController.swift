import UIKit

class DetailViewController: UIViewController {
    
    // MARK: - Properties
    
    var stock: StockModel!
    
    static func loadFromStoryboard() -> DetailViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        return storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController
    }
    
    class func detailViewControllerForStock(_ stock: StockModel) -> UIViewController {
        let detailViewController = loadFromStoryboard()
        detailViewController!.stock = stock
        return detailViewController!
    }
    
    // MARK: - View Life Cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        assert(stock != nil, "Stock has no value")
        
        title = stock.ticker
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupUI()
    }
    
    private func setupUI() {
        navigationItem.backButtonTitle = "Back" // Don't work??
    }
    
}
