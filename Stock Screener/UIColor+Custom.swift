import UIKit

extension UIColor {
    
    struct Custom {
        
        struct Brand {
            static let main = UIColor(named: "MainBrandColor")!
            static let secondary = UIColor(named: "SecondaryBrandColor")!
        }
        
        struct Background {
            static let main = UIColor(named: "MainBackgroundColor")!
            static let secondary = UIColor(named: "SecondaryBackgroundColor")!
        }
        
        struct Text {
            static let main = UIColor(named: "MainFontColor")!
            static let secondary = UIColor(named: "SecondaryFontColor")!
            static let ternary = UIColor(named: "TernaryFontColor")!
            static let quaternary = UIColor(named: "QuaternaryFontColor")
        }
        
        struct Common {
            static let green = UIColor(named: "StockGreen")!
            static let red = UIColor(named: "StockRed")!
            static let isFavourite = UIColor(named: "IsFavourite")!
            static let notFavourite = UIColor(named: "notFavourite")!
        }
    }
}
