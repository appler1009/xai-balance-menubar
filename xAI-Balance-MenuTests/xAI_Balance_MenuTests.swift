//
//  xAI_Balance_MenuTests.swift
//  xAI-Balance-MenuTests
//
//  Created by Appler on 2025-12-17.
//

import XCTest
import Foundation
@testable import xAI_Balance_Menu

final class XAIAPIClientTests: XCTestCase {

    func testAmountDecoding() throws {
        // Given: Sample amount JSON
        let json = """
        {"val": "123.45"}
        """

        // When: Decoding JSON
        let data = json.data(using: .utf8)!
        let amount = try JSONDecoder().decode(Amount.self, from: data)

        // Then: Verify amount is decoded correctly
        XCTAssertEqual(amount.val, "123.45")
    }

    func testBillingCycleDecoding() throws {
        // Given: Sample billing cycle JSON
        let json = """
        {"year": 2024, "month": 12}
        """

        // When: Decoding JSON
        let data = json.data(using: .utf8)!
        let billingCycle = try JSONDecoder().decode(BillingCycle.self, from: data)

        // Then: Verify values are decoded correctly
        XCTAssertEqual(billingCycle.year, 2024)
        XCTAssertEqual(billingCycle.month, 12)
    }

    func testBillingInfoDecoding() throws {
        // Given: Complete billing info JSON from xAI API
        let json = """
        {
            "coreInvoice": {
                "amountAfterVat": "15.42",
                "prepaidCredits": {"val": "50.00"},
                "prepaidCreditsUsed": {"val": "12.58"}
            },
            "effectiveSpendingLimit": "100.00",
            "billingCycle": {
                "year": 2025,
                "month": 1
            }
        }
        """

        // When: Decoding JSON
        let data = json.data(using: .utf8)!
        let billingInfo = try JSONDecoder().decode(BillingInfo.self, from: data)

        // Then: Verify all fields are decoded correctly
        XCTAssertEqual(billingInfo.coreInvoice.amountAfterVat, "15.42")
        XCTAssertEqual(billingInfo.coreInvoice.prepaidCredits.val, "50.00")
        XCTAssertEqual(billingInfo.coreInvoice.prepaidCreditsUsed.val, "12.58")
        XCTAssertEqual(billingInfo.effectiveSpendingLimit, "100.00")
        XCTAssertEqual(billingInfo.billingCycle.year, 2025)
        XCTAssertEqual(billingInfo.billingCycle.month, 1)
    }

    func testAPIClientInitialization() {
        // Given: API credentials
        let apiKey = "test-api-key-123"
        let teamId = "test-team-id-456"

        // When: Creating XAIAPIClient instance
        let client = XAIAPIClient(apiKey: apiKey, teamId: teamId)

        // Then: Client should be created successfully
        XCTAssertNotNil(client)
    }

    func testInvalidJSONDecoding() {
        // Given: Invalid JSON structure
        let json = """
        {"invalid": "json", "structure": "missing_fields"}
        """

        // When/Then: Decoding should throw an error
        let data = json.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(BillingInfo.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testEmptyAmountDecoding() throws {
        // Given: Empty amount value
        let json = """
        {"val": "0.00"}
        """

        // When: Decoding
        let data = json.data(using: .utf8)!
        let amount = try JSONDecoder().decode(Amount.self, from: data)

        // Then: Should handle zero amount correctly
        XCTAssertEqual(amount.val, "0.00")
    }

    func testNegativeAmountDecoding() throws {
        // Given: Negative amount (for refunds/credits)
        let json = """
        {"val": "-5.99"}
        """

        // When: Decoding
        let data = json.data(using: .utf8)!
        let amount = try JSONDecoder().decode(Amount.self, from: data)

        // Then: Should handle negative amounts
        XCTAssertEqual(amount.val, "-5.99")
    }
}