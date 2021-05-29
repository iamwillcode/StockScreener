import UIKit

class StockNewsCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet var source: UILabel!
    @IBOutlet var headline: UILabel!
    @IBOutlet var summary: UILabel!
    @IBOutlet var age: UILabel!
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupUI()
    }
    
    // MARK: - Private methods
    
    private func setupUI() {
        self.backgroundColor = UIColor.Custom.Background.secondary
        
        selectedBackgroundView = {
            let view = UIView.init()
            view.backgroundColor = UIColor.Custom.Text.secondary
            return view
        }()
    }
}
