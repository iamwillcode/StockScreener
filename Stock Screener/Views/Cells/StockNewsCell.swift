import UIKit

class StockNewsCell: UITableViewCell {

    //MARK: - IBOutlets
    
    @IBOutlet var source: UILabel!
    @IBOutlet var headline: UILabel!
    @IBOutlet var summary: UILabel!
    @IBOutlet var age: UILabel!
    
    //MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
