//
//  BalanceCalculatorTests.swift
//  xAI-Balance-MenuTests
//

import XCTest

@testable import xAI_Balance_Menu

final class BalanceCalculatorTests: XCTestCase {

  func testNoApiKeyMenuTitles() {
    let appDelegate = AppDelegate()
    appDelegate.invoiceMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    appDelegate.prepaidMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    appDelegate.apiClient = nil
    appDelegate.refreshBalance()

    XCTAssertEqual(appDelegate.invoiceMenuItem?.title, "Invoice: no key")
    XCTAssertEqual(appDelegate.prepaidMenuItem?.title, "Prepaid: no key")
  }

  func testValidBillingDataMenuTitles() {
    let appDelegate = AppDelegate()
    appDelegate.invoiceMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    appDelegate.prepaidMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    let mockClient = MockXAIAPIClient(apiKey: "test", teamId: "test")
    appDelegate.apiClient = mockClient

    let sampleData = BillingInfo(
      coreInvoice: CoreInvoice(
        amountAfterVat: "7500",  // $75 used
        prepaidCredits: Amount(val: "15000"),  // $150
        prepaidCreditsUsed: Amount(val: "4500")  // $45 used
      ),
      effectiveSpendingLimit: "25000",  // $250 limit
      billingCycle: BillingCycle(year: 2025, month: 12)
    )
    mockClient.mockResponse = sampleData

    let expectation = XCTestExpectation(description: "UI update")
    appDelegate.refreshBalance()

    DispatchQueue.main.async {
      let invoiceTitle = appDelegate.invoiceMenuItem?.title ?? ""
      let prepaidTitle = appDelegate.prepaidMenuItem?.title ?? ""

      print("invoiceTitle: '\(invoiceTitle)'")
      print("prepaidTitle: '\(prepaidTitle)'")

      XCTAssertTrue(invoiceTitle.contains("limit $250.00"))
      XCTAssertTrue(invoiceTitle.contains("used $75.00"))
      XCTAssertTrue(invoiceTitle.contains("remain $175.00"))
      XCTAssertTrue(prepaidTitle.contains("credit $-150.00"))
      XCTAssertTrue(prepaidTitle.contains("used $-45.00"))
      XCTAssertTrue(prepaidTitle.contains("balance $-105.00"))
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  func testApiErrorMenuTitles() {
    let appDelegate = AppDelegate()
    appDelegate.invoiceMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    appDelegate.prepaidMenuItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    let mockClient = MockXAIAPIClient(apiKey: "test", teamId: "test")
    appDelegate.apiClient = mockClient
    mockClient.shouldFail = true

    let expectation = XCTestExpectation(description: "UI update")
    appDelegate.refreshBalance()

    DispatchQueue.main.async {
      XCTAssertEqual(appDelegate.invoiceMenuItem?.title, "Invoice: error")
      XCTAssertEqual(appDelegate.prepaidMenuItem?.title, "Prepaid: error")
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }
}
