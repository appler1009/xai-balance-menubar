import XCTest
@testable import xAI_Balance_Menu

final class RealXAIAPITests: XCTestCase {
    
    func testRealXAIAPIDataParsing() throws {
        let realJson = """
        {
          "coreInvoice": {
            "amountAfterVat": "619",
            "prepaidCredits": {"val": "-740"},
            "prepaidCreditsUsed": {"val": "-740"}
          },
          "effectiveSpendingLimit": "1500",
          "billingCycle": {"year": 2025, "month": 12}
        }
        """
        
        let data = realJson.data(using: .utf8)!
        let billingInfo = try JSONDecoder().decode(BillingInfo.self, from: data)
        
        XCTAssertEqual(billingInfo.effectiveSpendingLimit, "1500")
        XCTAssertEqual(billingInfo.coreInvoice.amountAfterVat, "619")
        XCTAssertEqual(billingInfo.coreInvoice.prepaidCredits.val, "-740")
        XCTAssertEqual(billingInfo.coreInvoice.prepaidCreditsUsed.val, "-740")
        XCTAssertEqual(billingInfo.billingCycle.year, 2025)
        XCTAssertEqual(billingInfo.billingCycle.month, 12)
        
        // Verify menu item formatting with real data
        let limitD = Double("1500")! / 100.0  // $15.00
        let usedD = Double("619")! / 100.0     // $6.19
        let balanceD = limitD - usedD           // $8.81
        
        let expectedInvoice = String(format: "Invoice limit $%.2f; used $%.2f; remain $%.2f", limitD, usedD, balanceD)
        print("✅ Real data invoice menu: \(expectedInvoice)")
        
        let preCredD = Double("-740")! / 100.0 * -1  // -$7.40 * -1 = $7.40
        let preUsedD = Double("-740")! / 100.0 * -1  // -$7.40 * -1 = $7.40  
        let preBalanceD = preCredD - preUsedD         // $0.00
        
        let expectedPrepaid = String(format: "Prepaid credit $%.2f; used $%.2f; balance $%.2f", preCredD, preUsedD, preBalanceD)
        print("✅ Real data prepaid menu: \(expectedPrepaid)")
    }
    
    func testRealDataMenuCalculations() {
        let appDelegate = AppDelegate()
        appDelegate.invoiceMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        appDelegate.prepaidMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        let mockClient = MockXAIAPIClient(apiKey: "test", teamId: "test")
        appDelegate.apiClient = mockClient
        
        let realData = BillingInfo(
            coreInvoice: CoreInvoice(
                amountAfterVat: "619",      // $6.19 used
                prepaidCredits: Amount(val: "-740"),     // -$7.40
                prepaidCreditsUsed: Amount(val: "-740")  // -$7.40 used
            ),
            effectiveSpendingLimit: "1500",  // $15.00 limit
            billingCycle: BillingCycle(year: 2025, month: 12)
        )
        mockClient.mockResponse = realData
        
        appDelegate.refreshBalance()
        
        let invoiceTitle = appDelegate.invoiceMenuItem?.title ?? ""
        let prepaidTitle = appDelegate.prepaidMenuItem?.title ?? ""
        
        XCTAssertTrue(invoiceTitle.contains("limit $15.00"))
        XCTAssertTrue(invoiceTitle.contains("used $6.19"))
        XCTAssertTrue(invoiceTitle.contains("remain $8.81"))
        XCTAssertTrue(prepaidTitle.contains("credit $7.40"))
        XCTAssertTrue(prepaidTitle.contains("used $7.40"))
        XCTAssertTrue(prepaidTitle.contains("balance $0.00"))
    }
}