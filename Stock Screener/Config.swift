//
//  Config.swift
//  Stock Screener
//
//  Created by Admin on 03.04.2021.
//

import Foundation

struct Config {
    
    struct Api {
        static let trends = "https://cloud.iexapis.com/stable/stock/market/list/mostactive"
        static let trendsKey = "pk_8f50c7473cf041fdbe7f9bbafb968391"
        static let trendsAmount = 10
        
        static let main = "https://finnhub.io/api/v1/" // 60 calls per minute limit
        static let mainKey = "c1ccrp748v6scqmqri1g"
        
        static let logo = "https://storage.googleapis.com/iex/api/logos/"
    }

    struct Queues {
        static let builderTask = DispatchQueue(label: "stock-builder-tasks")
        static let stockDictionaryAccess = DispatchQueue(label: "access-stock-dictionary")
        static let resultDictionaryAccess = DispatchQueue(label: "acces-result-dictionary")
        static let favouriteDictionaryAccess = DispatchQueue(label: "access-favourite-dictionary")
        static let chartDataAccess = DispatchQueue(label: "chart-data")
    }
    
}
