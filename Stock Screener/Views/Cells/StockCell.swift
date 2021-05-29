import UIKit
import SkeletonView

final class StockCell: UITableViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet var cellView: UIView!
    @IBOutlet var cellStackView: UIStackView!
    @IBOutlet var cellInfoView: UIStackView!
    @IBOutlet var cellTopInfoView: UIStackView!
    @IBOutlet var cellBottomInfoView: UIStackView!
    @IBOutlet var tickerSectionView: UIStackView!
    @IBOutlet var ticker: UILabel!
    @IBOutlet var companyName: UILabel!
    @IBOutlet var companyLogo: UIImageView!
    @IBOutlet var currentPrice: UILabel!
    @IBOutlet var dayDelta: UILabel!
    @IBOutlet var favouriteButton: UIButton!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Public Properties
    
    var callbackOnFavouriteButton : (() -> Void)?
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupUI()
        setupSkeleton()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        // Self
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor.Custom.Background.secondary
        
        // Cell View
        cellView.layer.cornerRadius = 12
        cellView.layer.masksToBounds = true
        cellView.backgroundColor = UIColor.Custom.Background.main
        
        // Labels
        ticker.textColor = UIColor.Custom.Text.ternary
        companyName.textColor = UIColor.Custom.Text.ternary
        currentPrice.textColor = UIColor.Custom.Text.ternary
        dayDelta.textColor = UIColor.Custom.Text.ternary
        
        // Image View
        companyLogo.layer.cornerRadius = 12
        companyLogo.layer.masksToBounds = true
        
        // Activity indicator
        activityIndicator.hidesWhenStopped = true
        
        // Selection style of the cell
        selectedBackgroundView = {
            let view = UIView.init()
            view.backgroundColor = UIColor.Custom.Text.secondary
            return view
        }()
    }
    
    private func setupSkeleton() {
        self.isSkeletonable = true
        self.contentView.isSkeletonable = true
        ticker.isSkeletonable = true
        companyName.isSkeletonable = true
        companyLogo.isSkeletonable = true
        cellInfoView.isSkeletonable = true
        cellTopInfoView.isSkeletonable = true
        cellBottomInfoView.isSkeletonable = true
        tickerSectionView.isSkeletonable = true
        currentPrice.isSkeletonable = true
        dayDelta.isSkeletonable = true
        favouriteButton.isSkeletonable = true
        cellView.isSkeletonable = true
        cellStackView.isSkeletonable = true
        
        currentPrice.isHiddenWhenSkeletonIsActive = true
        dayDelta.isHiddenWhenSkeletonIsActive = true
        favouriteButton.isHiddenWhenSkeletonIsActive = true
        
        ticker.linesCornerRadius = 5
        companyName.linesCornerRadius = 5
        
        ticker.skeletonPaddingInsets = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: 0,
            right: cellInfoView.frame.width
        )
        companyName.skeletonPaddingInsets = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: 0,
            right: cellInfoView.frame.width / 2
        )
    }
    
    // MARK: - IBActions
    
    @IBAction func setFavourite(_ sender: UIButton) {
        callbackOnFavouriteButton?()
    }
}
