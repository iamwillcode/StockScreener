import UIKit

class StockCell: UITableViewCell {
    
    var callbackOnButton : (()->())?
    
    @IBOutlet var ticker: UILabel!
    @IBOutlet var companyName: UILabel!
    @IBOutlet var companyLogo: UIImageView!
    @IBOutlet var currentPrice: UILabel!
    @IBOutlet var dayDelta: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var favouriteButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        roundLogo()
        activityIndicatorSetup()

    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func roundLogo() {
        companyLogo.layer.cornerRadius = 12
        companyLogo.layer.masksToBounds = true
    }
    
    func activityIndicatorSetup() {
        activityIndicator.hidesWhenStopped = true
    }
    
    @IBAction func setFavourite(_ sender: UIButton) {
        self.callbackOnButton?()
    }
    
}
