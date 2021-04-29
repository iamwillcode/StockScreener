import Foundation

enum StockError: Error {
    case requestError
    case sessionTaskError(Error?)
    case decodeError
    case urlError
    case tickerPriceError(String)
    case tickerLogoError(String)
    case searchError(String)
    case trendsError
}

extension StockError: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .requestError:
            return NSLocalizedString(
                "Can't make URL request.",
                comment: ""
            )
        case .sessionTaskError(let error):
            return NSLocalizedString(
                "URLSession task error: \(String(describing: error)).",
                comment: ""
            )
        case .decodeError:
            return NSLocalizedString(
                "Can't decode JSON.",
                comment: ""
            )
        case .urlError:
            return NSLocalizedString(
                "Bad request URL.",
                comment: ""
            )
        case .tickerPriceError(let ticker):
            return NSLocalizedString(
                "Can't get price for \(ticker).",
                comment: ""
            )
        case .tickerLogoError(let ticker):
            return NSLocalizedString(
                "Can't get logo for \(ticker).",
                comment: ""
            )
        case .searchError(let ticker):
            return NSLocalizedString(
                "Can't find any matches for \(ticker).",
                comment: ""
            )
        case .trendsError:
            return NSLocalizedString(
                "Can't get trending tickers.",
                comment: ""
            )
        }
    }
    
}
