import Foundation

struct StockNetwork {
    
    func performRequest<T: Codable>(with urlString: String) -> Result<T, StockError> {
        
        var result: Result<T, StockError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        guard let url = URL(string: urlString) else { return .failure(.urlError) }
        
        let request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 15)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                result = .failure(.sessionTaskError(error))
            }
            guard let safeData = data else {
                result = .failure(.requestError)
                return
            }
            do {
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(T.self, from: safeData)
                result = .success(decodedData)
            } catch {
                result = .failure(.decodeError)
            }
            semaphore.signal()
        }
        
        task.resume()
        
        if semaphore.wait(timeout: .now() + 15) == .timedOut {
            result = .failure(.timeout)
        }
        
        return result
    }
}

