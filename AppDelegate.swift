import Cocoa
import Security
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
  var statusItem: NSStatusItem?
  var apiClient: XAIAPIClient?
  var refreshTimer: Timer?
  var launchAtLoginItem: NSMenuItem?
  var invoiceMenuItem: NSMenuItem?
  var prepaidMenuItem: NSMenuItem?
  var effectiveSpendingLimit: String?
  var amountAfterVat: String?
  var prepaidCredits: String?
  var prepaidCreditsUsed: String?
  var billingYear: Int?
  var billingMonth: Int?

  override init() {
    super.init()
  }

  func saveCredentials(apiKey: String, teamId: String) {
    let credentials = ["apiKey": apiKey, "teamId": teamId]
    guard let data = try? JSONEncoder().encode(credentials) else { return }
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: "xai_credentials",
      kSecValueData as String: data,
      kSecAttrService as String: "xai-balance-menu",
    ]
    SecItemDelete(query as CFDictionary)
    SecItemAdd(query as CFDictionary, nil)
  }

  func getCredentials() -> (apiKey: String, teamId: String)? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: "xai_credentials",
      kSecAttrService as String: "xai-balance-menu",
      kSecReturnData as String: true,
    ]
    var result: AnyObject?
    SecItemCopyMatching(query as CFDictionary, &result)
    if let data = result as? Data,
      let dict = try? JSONDecoder().decode([String: String].self, from: data)
    {
      if let apiKey = dict["apiKey"], let teamId = dict["teamId"] {
        return (apiKey, teamId)
      }
    }
    return nil
  }

  func updateIcon() {
    let maxSize: CGFloat = 16  // Max dimension for menubar icon
    if let image = NSImage(named: "XAI_Logo") {
      let originalSize = image.size
      let aspectRatio = originalSize.width / originalSize.height
      var newSize: NSSize
      if aspectRatio > 1 {
        // Wider than tall
        newSize = NSSize(width: maxSize, height: maxSize / aspectRatio)
      } else {
        // Taller than wide
        newSize = NSSize(width: maxSize * aspectRatio, height: maxSize)
      }
      image.size = newSize
      image.isTemplate = true  // Render as template for proper menubar coloring
      statusItem?.button?.image = image
    } else {
      // Fallback to SF Symbol, which are square
      let targetSize = NSSize(width: maxSize, height: maxSize)
      if let symbolImage = NSImage(
        systemSymbolName: apiClient != nil ? "x.circle.fill" : "x.circle",
        accessibilityDescription: "Balance")
      {
        symbolImage.size = targetSize
        symbolImage.isTemplate = true  // Ensure it renders correctly
        statusItem?.button?.image = symbolImage
      }
    }
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    // Load credentials from Keychain
    if let (apiKey, teamId) = getCredentials() {
      apiClient = XAIAPIClient(apiKey: apiKey, teamId: teamId)
    }

    // Create status item
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    updateIcon()
    statusItem?.button?.title = ""

    // Create menu
    let menu = NSMenu()
    menu.addItem(
      NSMenuItem(title: "Refresh", action: #selector(refreshBalance), keyEquivalent: "r"))

    launchAtLoginItem = NSMenuItem(
      title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
    launchAtLoginItem?.state = isLaunchAtLoginEnabled() ? .on : .off

    menu.addItem(NSMenuItem.separator())
    let invoiceTempItem = NSMenuItem(title: "Invoice: --", action: nil, keyEquivalent: "")
    invoiceMenuItem = invoiceTempItem
    menu.addItem(invoiceTempItem)
    let prepaidTempItem = NSMenuItem(title: "Prepaid: --", action: nil, keyEquivalent: "")
    prepaidMenuItem = prepaidTempItem
    menu.addItem(prepaidTempItem)

    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Set API Key", action: #selector(setAPIKey), keyEquivalent: ""))
    menu.addItem(launchAtLoginItem!)

    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "About...", action: #selector(showAbout), keyEquivalent: ""))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    statusItem?.menu = menu

    // Initial refresh if API key exists
    if apiClient != nil {
      refreshBalance()
      startRefreshTimer()
    }
  }

  func startRefreshTimer() {
    refreshTimer?.invalidate()
    refreshTimer = Timer.scheduledTimer(
      timeInterval: 1800, target: self, selector: #selector(refreshBalance), userInfo: nil,
      repeats: true)  // 30 minutes
  }

  @objc func setAPIKey() {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.messageText = "Enter xAI API Key and Team ID"
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Cancel")

    // Create a custom view with two text fields
    let customView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 80))

    let apiKeyLabel = NSTextField(labelWithString: "API Key:")
    apiKeyLabel.frame = NSRect(x: 0, y: 55, width: 60, height: 20)
    customView.addSubview(apiKeyLabel)

    let apiKeyField = NSTextField(frame: NSRect(x: 70, y: 50, width: 220, height: 24))
    customView.addSubview(apiKeyField)

    let teamIdLabel = NSTextField(labelWithString: "Team ID:")
    teamIdLabel.frame = NSRect(x: 0, y: 25, width: 60, height: 20)
    customView.addSubview(teamIdLabel)

    let teamIdField = NSTextField(frame: NSRect(x: 70, y: 20, width: 220, height: 24))
    customView.addSubview(teamIdField)

    alert.accessoryView = customView

    if alert.runModal() == .alertFirstButtonReturn {
      let key = apiKeyField.stringValue
      let teamId = teamIdField.stringValue
      saveCredentials(apiKey: key, teamId: teamId)
      apiClient = XAIAPIClient(apiKey: key, teamId: teamId)
      updateIcon()
      refreshBalance()
      startRefreshTimer()
    }
  }

  @objc func refreshBalance() {
    guard let client = apiClient else {
      statusItem?.button?.title = ""
      invoiceMenuItem?.title = "Invoice: no key"
      prepaidMenuItem?.title = "Prepaid: no key"
      return
    }

    client.fetchBillingInfo { [weak self] (result: Result<BillingInfo, Error>) in
      switch result {
        case .success(let info):
          let core = info.coreInvoice
          self?.effectiveSpendingLimit = info.effectiveSpendingLimit
          self?.amountAfterVat = core.amountAfterVat
          self?.prepaidCredits = core.prepaidCredits.val
          self?.prepaidCreditsUsed = core.prepaidCreditsUsed.val
          self?.billingYear = info.billingCycle.year
          self?.billingMonth = info.billingCycle.month
          var preValue: Double? = nil
          var invValue: Double? = nil
          if let preCred = Double(core.prepaidCredits.val),
            let used = Double(core.prepaidCreditsUsed.val)
          {
            preValue = abs(preCred - used) / 100.0
    }
          if let limit = Double(info.effectiveSpendingLimit), let used = Double(core.amountAfterVat)
          {
            invValue = (limit - used) / 100.0
          }
          // Update menu items
          let limitD = (Double(info.effectiveSpendingLimit) ?? 0) / 100.0
          let invUsedD = (Double(core.amountAfterVat) ?? 0) / 100.0
          let invBalD = limitD - invUsedD
          self?.invoiceMenuItem?.title = String(
            format: "Invoice limit $%.2f; used $%.2f; remain $%.2f", limitD, (limitD - invBalD),
            invBalD)
          let preCredD = (Double(core.prepaidCredits.val) ?? 0) / 100.0 * -1
          let preUsedD = (Double(core.prepaidCreditsUsed.val) ?? 0) / 100.0 * -1
          self?.prepaidMenuItem?.title = String(
            format: "Prepaid credit $%.2f; used $%.2f; balance $%.2f", preCredD, preUsedD,
            (preCredD - preUsedD))
          var parts: [String] = []
          if let pre = preValue, pre != 0 {
            parts.append(String(format: "$%.2f", pre))
          }
          if let inv = invValue, inv != 0 {
            parts.append(String(format: "$%.2f", inv))
          }
          if parts.isEmpty {
            self?.statusItem?.button?.title = "$0.00"
          } else {
            self?.statusItem?.button?.title = parts.joined(separator: " ")
          }
        case .failure:
          self?.invoiceMenuItem?.title = "Invoice: error"
          self?.prepaidMenuItem?.title = "Prepaid: error"
          self?.statusItem?.button?.title = "Error"
        }
      }
    }

  @objc func toggleLaunchAtLogin() {
    let enabled = !isLaunchAtLoginEnabled()
    setLaunchAtLoginEnabled(enabled)
    launchAtLoginItem?.state = enabled ? .on : .off
  }

  func isLaunchAtLoginEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: "launchAtLogin")
  }

  func setLaunchAtLoginEnabled(_ enabled: Bool) {
    UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
    let bundleIdentifier = Bundle.main.bundleIdentifier!
    print("Bundle ID: \(bundleIdentifier), Setting launch at login: \(enabled)")
    if SMLoginItemSetEnabled(bundleIdentifier as CFString, enabled) {
      print("Successfully set launch at login")
    } else {
      print("Failed to set launch at login")
    }
  }

  @objc func showAbout() {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.messageText = "xAI Balance Menu"

    // Debug: Check what files are available in the bundle
    if let resourcePath = Bundle.main.resourcePath {
      let files = try? FileManager.default.contentsOfDirectory(atPath: resourcePath)
      print("Bundle resources: \(files ?? [])")
    }

    // For now, use bundle version (we can manually update this)
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    print("Using bundle version: \(version) (\(build))")

    // Get year from latest git commit for copyright
    let currentYear: Int
    do {
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
      process.arguments = ["log", "-1", "--format=%ci"]
      let pipe = Pipe()
      process.standardOutput = pipe
      try process.run()
      process.waitUntilExit()
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      let yearString = output.split(separator: "-").first ?? ""
      currentYear = Int(yearString) ?? Calendar.current.component(.year, from: Date())
    } catch {
      currentYear = Calendar.current.component(.year, from: Date())
    }

    // Try to get copyright owner from bundle or use team name
    var copyrightOwner = "xAI"
    if let bundleCopyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String {
      // Extract owner from copyright string (e.g., "Copyright © 2025 Team Name. All rights reserved.")
      let pattern = "Copyright © \\d+ (.+?)\\."
      if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
        let match = regex.firstMatch(
          in: bundleCopyright, options: [],
          range: NSRange(bundleCopyright.startIndex..., in: bundleCopyright))
      {
        if let range = Range(match.range(at: 1), in: bundleCopyright) {
          copyrightOwner = String(bundleCopyright[range])
        }
      }
    }

    alert.informativeText =
      "Version \(version) (Build \(build))\n\nCopyright © \(currentYear) \(copyrightOwner).\nAll rights reserved."
    alert.addButton(withTitle: "OK")
    alert.alertStyle = .informational
    alert.runModal()
  }

  private func showDetailsAlert(title: String, message: String) {
    NSApp.activate(ignoringOtherApps: true)
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }

  @objc private func showInvoiceDetails() {
    guard let limit = effectiveSpendingLimit,
      let used = amountAfterVat,
      let year = billingYear,
      let month = billingMonth
    else {
      showDetailsAlert(
        title: "Invoice Details", message: "No billing data available. Please refresh.")
      return
    }
    let limitD = Double(limit)! / 100.0
    let usedD = Double(used)! / 100.0
    let remainD = limitD - usedD
    let cycle = "\(year)-\(String(format: "%02d", month))"
    let message = """
      Billing Cycle: \(cycle)
      Spending Limit: $\(String(format: "%.2f", limitD))
      Amount Used: $\(String(format: "%.2f", usedD))
      Remaining Balance: $\(String(format: "%.2f", remainD))
      """
    showDetailsAlert(title: "Invoice Billing Details", message: message)
  }

  @objc private func showPrepaidDetails() {
    guard let pre = prepaidCredits,
      let usedStr = prepaidCreditsUsed
    else {
      showDetailsAlert(
        title: "Prepaid Details", message: "No prepaid data available. Please refresh.")
      return
    }
    let preD = Double(pre)! / 100.0
    let usedD = Double(usedStr)! / 100.0
    let remainD = abs(preD - usedD)
    let message = """
      Prepaid Credits: $\(String(format: "%.2f", preD))
      Credits Used: $\(String(format: "%.2f", usedD))
      Remaining: $\(String(format: "%.2f", remainD))
      """
    showDetailsAlert(title: "Prepaid Credit & Usage", message: message)
  }

  @objc func quitApp() {
    refreshTimer?.invalidate()
    NSApplication.shared.terminate(nil)
  }
}
