import Foundation

struct PrepaidBalance: Codable {
    let balance: Double
    let changes: [BalanceChange]
}

struct BalanceChange: Codable {
    let amount: Double
    let timestamp: String
    let description: String
}

struct PostpaidInvoice: Codable {
    let amount: Double
    let dueDate: String
}

class XAIAPIClient {
    private let baseURL = "https://api.x.ai/v1/management"
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func fetchPrepaidBalance(completion: @escaping (Result<PrepaidBalance, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/prepaid-balance")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            do {
                let balance = try JSONDecoder().decode(PrepaidBalance.self, from: data)
                completion(.success(balance))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchPostpaidInvoice(completion: @escaping (Result<PostpaidInvoice, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/postpaid-invoice")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            do {
                let invoice = try JSONDecoder().decode(PostpaidInvoice.self, from: data)
                completion(.success(invoice))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}