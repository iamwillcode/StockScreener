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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
