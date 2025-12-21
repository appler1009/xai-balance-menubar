import Foundation
@testable import xAI_Balance_Menu

class MockXAIAPIClient: XAIAPIClient {
    var mockResponse: BillingInfo?
    var shouldFail = false
    
    override func fetchBillingInfo(completion: @escaping (Result<BillingInfo, Error>) -> Void) {
        print("Mock fetchBillingInfo called, shouldFail: \(shouldFail), hasResponse: \(mockResponse != nil)")
        if shouldFail {
            completion(.failure(NSError(domain: "MockError", code: 500, userInfo: nil)))
        } else if let response = mockResponse {
            completion(.success(response))
        }
    }
}