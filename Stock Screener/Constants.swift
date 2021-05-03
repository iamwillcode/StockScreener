import UIKit

struct K {
    
    static let defaultLogo = "StockDefaultLogo"
    
    struct Cells {
        static let stock = "StockCell"
        static let chart = "StockChartCell"
        static let news = "StockNewsCell"
    }
    
    struct Colors {
        struct Brand {
            static let main = UIColor(named: "MainBrandColor")!
            static let secondary = UIColor(named: "SecondaryBrandColor")!
            static let ternary = UIColor(named: "TernaryBrandColor")!
        }
        
        struct Background {
            static let main = UIColor(named: "MainBackgroundColor")!
            static let secondary = UIColor(named: "SecondaryBackgroundColor")!
        }
        
        struct Common {
            static let green = UIColor(named: "StockGreen")!
            static let red = UIColor(named: "StockRed")!
            static let isFavourite = UIColor(named: "IsFavourite")!
            static let notFavourite = UIColor(named: "notFavourite")!
        }
    }
    
    struct Queues {
        static let stockManagerTask = DispatchQueue(label: "stock-manager-tasks")
        static let trendingStocksAccess = DispatchQueue(label: "access-trending-dictionary")
        static let favouriteStocksAccess = DispatchQueue(label: "access-favourite-dictionary")
        static let searchResultStocksAccess = DispatchQueue(label: "acces-result-dictionary")
        static let chartDataAccess = DispatchQueue(label: "chart-data")
    }
    
}
