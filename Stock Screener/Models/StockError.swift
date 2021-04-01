import Foundation

enum StockError: Error {
    case requestError
    case sessionTaskError
    case decodeError
    case urlError
}
