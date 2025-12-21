import Foundation

struct Amount: Codable {
  let val: String
}

struct BillingInfo: Codable {
  let coreInvoice: CoreInvoice
  let effectiveSpendingLimit: String
  let billingCycle: BillingCycle
}

struct CoreInvoice: Codable {
  let amountAfterVat: String
  let prepaidCredits: Amount
  let prepaidCreditsUsed: Amount
  // Add other fields if needed
}

struct BillingCycle: Codable {
  let year: Int
  let month: Int
}

class XAIAPIClient {
  private let baseURL = "https://management-api.x.ai"
  private let apiKey: String
  private let teamId: String

  init(apiKey: String, teamId: String) {
    self.apiKey = apiKey
    self.teamId = teamId
  }
    func fetchBillingInfo(completion: @escaping (Result<BillingInfo, Error>) -> Void) {
        print("🔍 XAI API Request: \(baseURL)/v1/billing/teams/\(teamId)/postpaid/invoice/preview")
        print("📡 Headers: Authorization: Bearer \(String(apiKey.prefix(8)))...")
        
        let url = URL(string: "\(baseURL)/v1/billing/teams/\(teamId)/postpaid/invoice/preview")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
          if let httpResponse = response as? HTTPURLResponse {
            print("📥 Response: \(httpResponse.statusCode), \(data?.count ?? 0) bytes")
            if let data = data, let jsonString = String(data: data, encoding: .utf8) {
              print("📄 FULL JSON RESPONSE:")
              print(jsonString)
              print("📄 END JSON")
            }
          }
      if let httpResponse = response as? HTTPURLResponse {
        print("📥 Response: \(httpResponse.statusCode), \(data?.count ?? 0) bytes")
      }
      if let error = error {
        completion(.failure(error))
        return
      }
      if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
        let errorMessage = "HTTP Error: \(httpResponse.statusCode)"
        completion(
          .failure(
            NSError(
              domain: "", code: httpResponse.statusCode,
              userInfo: [NSLocalizedDescriptionKey: errorMessage])))
        return
      }
      guard let data = data else {
        completion(
          .failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
        return
      }

      do {
        let info = try JSONDecoder().decode(BillingInfo.self, from: data)
        completion(.success(info))
      } catch {
        completion(.failure(error))
      }
    }.resume()
  }
}
