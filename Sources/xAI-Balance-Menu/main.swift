import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var apiClient: XAIAPIClient?
    var refreshTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Load API key from UserDefaults
        if let apiKey = UserDefaults.standard.string(forKey: "xai_api_key") {
            apiClient = XAIAPIClient(apiKey: apiKey)
        }
        
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "Balance: No API Key"
        
        // Create menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refreshBalance), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Set API Key", action: #selector(setAPIKey), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
        
        // Initial refresh if API key exists
        if apiClient != nil {
            refreshBalance()
            startRefreshTimer()
        }
    }
    
    @objc func setAPIKey() {
        let alert = NSAlert()
        alert.messageText = "Enter xAI API Key"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        alert.accessoryView = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let key = input.stringValue
            UserDefaults.standard.set(key, forKey: "xai_api_key")
            apiClient = XAIAPIClient(apiKey: key)
            refreshBalance()
            startRefreshTimer()
        }
    }
    
    func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(timeInterval: 1800, target: self, selector: #selector(refreshBalance), userInfo: nil, repeats: true) // 30 minutes
    }
    
    @objc func refreshBalance() {
        guard let client = apiClient else {
            statusItem?.button?.title = "Balance: No API Key"
            return
        }
        
        statusItem?.button?.title = "Balance: Loading..."
        
        client.fetchPrepaidBalance { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let balance):
                    self?.statusItem?.button?.title = String(format: "Balance: $%.2f", balance.balance)
                case .failure:
                    // Try postpaid if prepaid fails
                    client.fetchPostpaidInvoice { [weak self] result2 in
                        DispatchQueue.main.async {
                            switch result2 {
                            case .success(let invoice):
                                self?.statusItem?.button?.title = String(format: "Invoice: $%.2f", invoice.amount)
                            case .failure(let error):
                                self?.statusItem?.button?.title = "Balance: Error"
                                print("API Error: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func quitApp() {
        refreshTimer?.invalidate()
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()