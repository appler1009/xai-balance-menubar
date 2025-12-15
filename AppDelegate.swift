import Cocoa
import Security
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var apiClient: XAIAPIClient?
    var refreshTimer: Timer?
    var launchAtLoginItem: NSMenuItem?

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
            kSecAttrService as String: "xai-balance-menu"
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func getCredentials() -> (apiKey: String, teamId: String)? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "xai_credentials",
            kSecAttrService as String: "xai-balance-menu",
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        if let data = result as? Data, let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            if let apiKey = dict["apiKey"], let teamId = dict["teamId"] {
                return (apiKey, teamId)
            }
        }
        return nil
    }

    func updateIcon() {
        let maxSize: CGFloat = 16 // Max dimension for menubar icon
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
            image.isTemplate = true // Render as template for proper menubar coloring
            statusItem?.button?.image = image
        } else {
            // Fallback to SF Symbol, which are square
            let targetSize = NSSize(width: maxSize, height: maxSize)
            if let symbolImage = NSImage(systemSymbolName: apiClient != nil ? "x.circle.fill" : "x.circle", accessibilityDescription: "Balance") {
                symbolImage.size = targetSize
                symbolImage.isTemplate = true // Ensure it renders correctly
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
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refreshBalance), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Set API Key", action: #selector(setAPIKey), keyEquivalent: ""))

        launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem?.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchAtLoginItem!)

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
        refreshTimer = Timer.scheduledTimer(timeInterval: 1800, target: self, selector: #selector(refreshBalance), userInfo: nil, repeats: true) // 30 minutes
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
            return
        }



        client.fetchBillingInfo { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let info):
                    let core = info.coreInvoice
                    var preValue: Double? = nil
                    var invValue: Double? = nil
                    if let preCred = Double(core.prepaidCredits.val), let used = Double(core.prepaidCreditsUsed.val) {
                        preValue = abs(preCred - used) / 100.0
                    }
                    if let limit = Double(info.effectiveSpendingLimit), let used = Double(core.amountAfterVat) {
                        invValue = (limit - used) / 100.0
                    }
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
                    self?.statusItem?.button?.title = "Error"
                }
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

    @objc func quitApp() {
        refreshTimer?.invalidate()
        NSApplication.shared.terminate(nil)
    }
}