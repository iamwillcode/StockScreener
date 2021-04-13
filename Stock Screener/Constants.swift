//
//  Constants.swift
//  Stock Screener
//
//  Created by Admin on 31.03.2021.
//

import Foundation

struct K {
    
    static let defaultLogo = "StockDefaultLogo"
    
    struct Cells {
        static let stock = "StockCell"
        static let chart = "StockChartCell"
        static let news = "StockNewsCell"
    }
    
    struct Colors {
        struct Brand {
            static let main = "MainBrandColor"
            static let secondary = "SecondaryBrandColor"
            static let ternary = "TernaryBrandColor"
        }
        
        struct Background {
            static let main = "MainBackgroundColor"
            static let secondary = "SecondaryBackgroundColor"
        }
        
        struct Common {
            static let green = "StockGreen"
            static let red = "StockRed"
            static let isFavourite = "IsFavourite"
            static let notFavourite = "notFavourite"
        }
    }
    
}
