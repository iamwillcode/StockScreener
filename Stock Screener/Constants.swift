import UIKit

struct Constants {
    
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
    
    struct Queues {
        static let stockManagerTask = DispatchQueue(label: "stock-manager-tasks")
        static let trendingStocksAccess = DispatchQueue(label: "access-trending-dictionary")
        static let favouriteStocksAccess = DispatchQueue(label: "access-favourite-dictionary")
        static let searchResultStocksAccess = DispatchQueue(label: "acces-result-dictionary")
        static let chartDataAccess = DispatchQueue(label: "chart-data")
    }
    
    struct TimeInSeconds {
        static let minute = 60
        static let hour = 3_600
        static let day = 86_400
        static let week = 604_800
        static let month = 2_592_000
        static let year = 31_536_000
    }
}
