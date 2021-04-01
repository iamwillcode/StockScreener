import Foundation

struct StockNetwork {
    
    func performRequest<T: Codable>(with urlString: String) -> Result<T, StockError> {
        
        var result: Result<T, StockError>!
        
        let semaphore = DispatchSemaphore(value: 0)
        
        guard let url = URL(string: urlString) else { return .failure(.urlError) }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                result = .failure(.sessionTaskError)
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
        }.resume()
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        
        return result
    }
    
}

