import UIKit

final class ShadowView: UIView {
    
    override var bounds: CGRect {
        didSet {
            setupShadow()
        }
    }

    private func setupShadow() {
        self.layer.cornerRadius = 12
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 4
        self.layer.shadowOpacity = 0.3
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: 12, height: 12)).cgPath
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }
    
}
