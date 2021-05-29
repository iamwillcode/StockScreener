import UIKit

struct Constants {
    
    static let defaultLogo = "StockDefaultLogo"
    
    struct Cells {
        static let stock = "StockCell"
        static let chart = "StockChartCell"
        static let news = "StockNewsCell"
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
