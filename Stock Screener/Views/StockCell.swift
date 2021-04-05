import UIKit

class StockCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet var ticker: UILabel!
    @IBOutlet var companyName: UILabel!
    @IBOutlet var companyLogo: UIImageView!
    @IBOutlet var currentPrice: UILabel!
    @IBOutlet var dayDelta: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var favouriteButton: UIButton!
    
    // MARK: - Public Properties
    
    var callbackOnFavouriteButton : (()->())?
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupUI()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true
        
        companyLogo.layer.cornerRadius = 12
        companyLogo.layer.masksToBounds = true
        
        activityIndicator.hidesWhenStopped = true
    }
    
    // MARK: - IBActions
    
    @IBAction func setFavourite(_ sender: UIButton) {
        self.callbackOnFavouriteButton?()
    }
    
}
