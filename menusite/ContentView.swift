import Cocoa
import WebKit

// Traditional AppKit entry point
@main
class MainApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItems: [String: NSStatusItem] = [:]
    var webViewers: [String: WebViewerInstance] = [:]
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("🚀 App launched - setting up...")
        
        // Set activation policy once
        NSApp.setActivationPolicy(.accessory)
        print("📋 Activation policy set to accessory")
        
        // Test: Create a simple status bar item first
        let testItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = testItem.button {
            button.title = "✓"
            button.action = #selector(testAction)
            button.target = self
            print("✅ Test status bar item created successfully")
        } else {
            print("❌ ERROR: Could not create test status bar item")
        }
        
        // Small delay to ensure system is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.initializeApp()
        }
        
        print("📱 Initial setup complete")
    }
    
    @objc func testAction() {
        print("Test button clicked!")
        let alert = NSAlert()
        alert.messageText = "Menu Site"
        alert.informativeText = "Test button works! The app is running correctly."
        alert.runModal()
    }
    
    func initializeApp() {
        print("🔧 Initializing main app...")
        
        // Load saved instances or create default one
        loadSavedInstances()
        
        // Add menu item to create new instances
        setupMainMenu()
        
        print("✅ Setup complete. Status bar items: \(statusBarItems.count)")
    }
    
    func setupMainMenu() {
        // Create a simple menu for right-click functionality
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "New Website Viewer", action: #selector(createNewInstance), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Menu Site", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
        
        // Note: This menu will be used later for right-click functionality
    }
    
    @objc func createNewInstance() {
        print("🆕 Creating new instance...")
        let instanceId = UUID().uuidString
        createWebViewerInstance(id: instanceId)
        saveInstances()
    }
    
    func createWebViewerInstance(id: String, url: String? = nil, externalLinks: Bool = false, width: Int = 375, height: Int = 667) {
        print("🔨 Creating instance: \(id)")
        
        let instance = WebViewerInstance(
            id: id,
            targetURL: url ?? "https://home.i.smith.bz/",
            openLinksExternally: externalLinks,
            windowWidth: width,
            windowHeight: height
        )
        
        webViewers[id] = instance
        
        // Create status bar item with fixed length
        let statusBarItem = NSStatusBar.system.statusItem(withLength: 24)
        statusBarItems[id] = statusBarItem
        
        print("📊 Created status bar item for \(id)")
        
        if let button = statusBarItem.button {
            // Use a simple text icon initially
            button.title = "🌐"
            button.target = instance
            button.action = #selector(WebViewerInstance.togglePopover(_:))
            button.toolTip = "Website Viewer - \(instance.targetURL)"
            
            // Create right-click menu with more options
            let menu = NSMenu()
            
            // Toggle for external links
            let externalLinksItem = NSMenuItem(title: "Open Links Externally", action: #selector(WebViewerInstance.toggleExternalLinks), keyEquivalent: "")
            externalLinksItem.target = instance
            menu.addItem(externalLinksItem)
            
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Settings", action: #selector(WebViewerInstance.showSettings), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Refresh", action: #selector(WebViewerInstance.refresh), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "New Website Viewer", action: #selector(createNewInstance), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Close This Viewer", action: #selector(WebViewerInstance.closeInstance), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Quit Menu Site", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
            
            // Set targets for menu items
            for item in menu.items {
                if item.action == #selector(createNewInstance) || item.action == #selector(NSApplication.terminate(_:)) {
                    item.target = self
                } else if item.target == nil {
                    item.target = instance
                }
            }
            
            button.menu = menu
            
            print("✅ Button configured for \(id)")
        } else {
            print("❌ ERROR: Could not get button for status bar item \(id)")
        }
        
        instance.statusBarItem = statusBarItem
        instance.delegate = self
        
        // Setup the popover
        instance.setupPopover()
        
        // Update menu item states after setup
        instance.updateMenuStates()
        
        // Load favicon after a delay to allow web view to load
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            instance.updateIcon()
        }
        
        print("🎯 Instance \(id) setup complete")
    }
    
    func loadSavedInstances() {
        print("📂 Loading saved instances...")
        let savedInstances = UserDefaults.standard.array(forKey: "webViewerInstances") as? [[String: Any]] ?? []
        print("📋 Found \(savedInstances.count) saved instances")
        
        if savedInstances.isEmpty {
            // Create default instance
            print("🎯 No saved instances, creating default")
            createWebViewerInstance(id: "default")
        } else {
            for instanceData in savedInstances {
                guard let id = instanceData["id"] as? String,
                      let url = instanceData["url"] as? String else {
                    print("⚠️ Skipping invalid instance data")
                    continue
                }
                
                let externalLinks = instanceData["externalLinks"] as? Bool ?? false
                let width = instanceData["width"] as? Int ?? 375
                let height = instanceData["height"] as? Int ?? 667
                
                print("🔄 Loading instance: \(id) with URL: \(url)")
                createWebViewerInstance(id: id, url: url, externalLinks: externalLinks, width: width, height: height)
            }
        }
        print("✅ Finished loading instances")
    }
    
    func saveInstances() {
        let instancesData = webViewers.values.map { instance in
            return [
                "id": instance.id,
                "url": instance.targetURL,
                "externalLinks": instance.openLinksExternally,
                "width": instance.windowWidth,
                "height": instance.windowHeight
            ]
        }
        UserDefaults.standard.set(instancesData, forKey: "webViewerInstances")
        print("💾 Saved \(instancesData.count) instances")
    }
}

extension AppDelegate: WebViewerInstanceDelegate {
    func instanceDidUpdate(_ instance: WebViewerInstance) {
        saveInstances()
    }
    
    func instanceShouldClose(_ instance: WebViewerInstance) {
        print("🗑️ Closing instance: \(instance.id)")
        // Remove the instance
        statusBarItems[instance.id]?.statusBar?.removeStatusItem(statusBarItems[instance.id]!)
        statusBarItems.removeValue(forKey: instance.id)
        webViewers.removeValue(forKey: instance.id)
        saveInstances()
        
        // Quit app if no instances remain
        if webViewers.isEmpty {
            print("👋 No instances left, quitting app")
            NSApp.terminate(nil)
        }
    }
}

protocol WebViewerInstanceDelegate: AnyObject {
    func instanceDidUpdate(_ instance: WebViewerInstance)
    func instanceShouldClose(_ instance: WebViewerInstance)
}

class WebViewerInstance: NSObject {
    let id: String
    var statusBarItem: NSStatusItem?
    var popover: NSPopover!
    var webViewController: WebViewController!
    weak var delegate: WebViewerInstanceDelegate?
    
    // Settings
    var targetURL: String {
        didSet {
            // Reload the website when URL changes
            webViewController?.loadWebsite()
            delegate?.instanceDidUpdate(self)
        }
    }
    var openLinksExternally: Bool {
        didSet {
            updateMenuStates()
            delegate?.instanceDidUpdate(self)
        }
    }
    var windowWidth: Int {
        didSet {
            popover?.contentSize = NSSize(width: windowWidth, height: windowHeight)
            delegate?.instanceDidUpdate(self)
        }
    }
    var windowHeight: Int {
        didSet {
            popover?.contentSize = NSSize(width: windowWidth, height: windowHeight)
            delegate?.instanceDidUpdate(self)
        }
    }
    var customIconPath: String? {
        didSet {
            updateIcon()
            delegate?.instanceDidUpdate(self)
        }
    }
    var useFavicon: Bool = true {
        didSet {
            updateIcon()
            delegate?.instanceDidUpdate(self)
        }
    }
    
    init(id: String, targetURL: String, openLinksExternally: Bool, windowWidth: Int, windowHeight: Int) {
        self.id = id
        self.targetURL = targetURL
        self.openLinksExternally = openLinksExternally
        self.windowWidth = windowWidth
        self.windowHeight = windowHeight
        
        super.init()
        print("🎭 WebViewerInstance \(id) initialized")
    }
    
    func setupPopover() {
        print("🎪 Setting up popover for \(id)")
        // Create popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: windowWidth, height: windowHeight)
        popover.behavior = .transient
        popover.delegate = self
        
        // Create web view controller
        webViewController = WebViewController(instance: self)
        popover.contentViewController = webViewController
        
        print("✅ Popover setup complete for \(id)")
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        print("👆 Toggle popover for \(id)")
        if let button = statusBarItem?.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
    @objc func showSettings() {
        print("⚙️ Showing settings for \(id)")
        let settingsWindow = SettingsWindowController(instance: self)
        settingsWindow.delegate = webViewController
        settingsWindow.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func refresh() {
        print("🔄 Refreshing \(id)")
        webViewController?.refreshWebView()
    }
    
    @objc func toggleExternalLinks() {
        openLinksExternally.toggle()
        print("🔗 External links toggled to: \(openLinksExternally)")
        
        // Update the menu item state
        if let button = statusBarItem?.button,
           let menu = button.menu {
            for item in menu.items {
                if item.action == #selector(toggleExternalLinks) {
                    item.state = openLinksExternally ? .on : .off
                    break
                }
            }
        }
    }
    
    @objc func closeInstance() {
        print("❌ Close requested for \(id)")
        delegate?.instanceShouldClose(self)
    }
    
    func updateMenuStates() {
        // Update menu item states to reflect current settings
        if let button = statusBarItem?.button,
           let menu = button.menu {
            for item in menu.items {
                if item.action == #selector(toggleExternalLinks) {
                    item.state = openLinksExternally ? .on : .off
                }
            }
        }
    }
    
    func updateIcon() {
        guard let button = statusBarItem?.button else { return }
        
        if let customPath = customIconPath, !customPath.isEmpty {
            // Use custom icon
            if let customImage = NSImage(contentsOfFile: customPath) {
                customImage.size = NSSize(width: 18, height: 18)
                button.image = customImage
                button.title = ""
                return
            }
        }
        
        if useFavicon {
            // Try to get favicon
            getFavicon { [weak self] favicon in
                DispatchQueue.main.async {
                    if let favicon = favicon {
                        favicon.size = NSSize(width: 18, height: 18)
                        button.image = favicon
                        button.title = ""
                    } else {
                        // Fallback to default icon
                        button.image = nil
                        button.title = "🌐"
                    }
                }
            }
        } else {
            // Use default icon
            button.image = nil
            button.title = "🌐"
        }
    }
    
    func getFavicon(completion: @escaping (NSImage?) -> Void) {
        guard let url = URL(string: targetURL),
              let host = url.host else {
            completion(nil)
            return
        }
        
        // Try multiple favicon URLs
        let faviconURLs = [
            "https://\(host)/favicon.ico",
            "https://\(host)/favicon.png",
            "https://www.google.com/s2/favicons?domain=\(host)&sz=32"
        ]
        
        tryFaviconURLs(faviconURLs, completion: completion)
    }
    
    func tryFaviconURLs(_ urls: [String], completion: @escaping (NSImage?) -> Void) {
        guard !urls.isEmpty else {
            completion(nil)
            return
        }
        
        guard let url = URL(string: urls[0]) else {
            tryFaviconURLs(Array(urls.dropFirst()), completion: completion)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let data = data, let image = NSImage(data: data) {
                completion(image)
            } else {
                // Try next URL
                self?.tryFaviconURLs(Array(urls.dropFirst()), completion: completion)
            }
        }.resume()
    }
}

extension WebViewerInstance: NSPopoverDelegate {
    func popoverDidClose(_ notification: Notification) {
        print("🔽 Popover closed for \(id)")
    }
}

class WebViewController: NSViewController {
    weak var instance: WebViewerInstance!
    var webView: WKWebView!
    var settingsButton: NSButton!
    var refreshButton: NSButton!
    var closeButton: NSButton!
    var toolbar: NSView!
    
    convenience init(instance: WebViewerInstance) {
        self.init()
        self.instance = instance
    }
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: instance.windowWidth, height: instance.windowHeight))
        
        print("🎬 Loading web view for \(instance.id)")
        setupToolbar()
        setupWebView()
        loadWebsite()
    }
    
    func setupToolbar() {
        toolbar = NSView()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.wantsLayer = true
        toolbar.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Only refresh button in toolbar
        refreshButton = NSButton()
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.title = "🔄"
        refreshButton.isBordered = false
        refreshButton.target = self
        refreshButton.action = #selector(refreshWebView)
        
        toolbar.addSubview(refreshButton)
        view.addSubview(toolbar)
        
        // Constraints
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 30),
            
            refreshButton.centerXAnchor.constraint(equalTo: toolbar.centerXAnchor),
            refreshButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor)
        ])
    }
    
    func setupWebView() {
        let config = WKWebViewConfiguration()
        
        // Basic configuration
        config.suppressesIncrementalRendering = false
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // Create preferences
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        
        // Set mobile user agent
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1"
        
        // Configure webView properties
        webView.allowsBackForwardNavigationGestures = false
        
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        print("🔧 WebView setup complete")
    }
    
    func loadWebsite() {
        guard let url = URL(string: instance.targetURL) else {
            print("❌ Invalid URL: \(instance.targetURL)")
            return
        }
        print("🌐 Loading website: \(url)")
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    @objc func refreshWebView() {
        print("🔄 Refreshing web view")
        webView.reload()
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        print("🌐 Navigation request: \(url)")
        
        // Always allow the initial load, reloads, and form submissions
        if navigationAction.navigationType == .reload ||
           navigationAction.navigationType == .formSubmitted ||
           navigationAction.navigationType == .formResubmitted ||
           webView.url == nil {
            decisionHandler(.allow)
            return
        }
        
        // Check if we should open links externally ONLY for link clicks
        if instance.openLinksExternally && navigationAction.navigationType == .linkActivated {
            print("🔗 Opening externally: \(url)")
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        
        // Allow all other navigation (redirects, JavaScript navigation, etc.)
        print("✅ Allowing navigation to: \(url)")
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("🌐 Started loading: \(webView.url?.absoluteString ?? "unknown")")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ Web view finished loading: \(webView.url?.absoluteString ?? "unknown")")
        
        // Update favicon when page loads
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.instance.updateIcon()
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ Web view failed to load: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("❌ Web view failed provisional navigation: \(error.localizedDescription)")
        
        // Try loading a simpler page as fallback
        if let url = URL(string: "https://example.com") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("💥 WebView process terminated - reloading")
        webView.reload()
    }
}

extension WebViewController: SettingsDelegate {
    func settingsDidUpdate() {
        print("🔄 Settings updated - reloading website to: \(instance.targetURL)")
        
        // Force reload the new URL
        loadWebsite()
        
        // Update popover size if needed
        instance.popover.contentSize = NSSize(width: instance.windowWidth, height: instance.windowHeight)
        view.frame = NSRect(x: 0, y: 0, width: instance.windowWidth, height: instance.windowHeight)
        
        // Update the status bar button tooltip
        instance.statusBarItem?.button?.toolTip = "Website Viewer - \(instance.targetURL)"
        
        // Update menu states
        instance.updateMenuStates()
        
        // Update icon after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.instance.updateIcon()
        }
    }
}

protocol SettingsDelegate: AnyObject {
    func settingsDidUpdate()
}

class SettingsWindowController: NSWindowController {
    weak var delegate: SettingsDelegate?
    weak var instance: WebViewerInstance!
    
    convenience init(instance: WebViewerInstance) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Website Viewer Settings"
        window.center()
        
        self.init(window: window)
        self.instance = instance
        
        let settingsView = SettingsViewController(instance: instance)
        settingsView.delegate = self
        window.contentViewController = settingsView
    }
}

extension SettingsWindowController: SettingsDelegate {
    func settingsDidUpdate() {
        delegate?.settingsDidUpdate()
    }
}

class SettingsViewController: NSViewController {
    weak var delegate: SettingsDelegate?
    weak var instance: WebViewerInstance!
    
    var urlTextField: NSTextField!
    var externalLinksCheckbox: NSButton!
    var widthTextField: NSTextField!
    var heightTextField: NSTextField!
    var useFaviconCheckbox: NSButton!
    var customIconTextField: NSTextField!
    var browseIconButton: NSButton!
    
    convenience init(instance: WebViewerInstance) {
        self.init()
        self.instance = instance
    }
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 450))
        
        setupUI()
        loadCurrentSettings()
    }
    
    func setupUI() {
        // URL Label and TextField
        let urlLabel = NSTextField(labelWithString: "Website URL:")
        urlLabel.translatesAutoresizingMaskIntoConstraints = false
        
        urlTextField = NSTextField()
        urlTextField.translatesAutoresizingMaskIntoConstraints = false
        urlTextField.placeholderString = "https://example.com"
        
        // External Links Checkbox
        externalLinksCheckbox = NSButton(checkboxWithTitle: "Open links in external browser", target: self, action: nil)
        externalLinksCheckbox.translatesAutoresizingMaskIntoConstraints = false
        
        // Window Size
        let sizeLabel = NSTextField(labelWithString: "Window Size:")
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let widthLabel = NSTextField(labelWithString: "Width:")
        widthLabel.translatesAutoresizingMaskIntoConstraints = false
        
        widthTextField = NSTextField()
        widthTextField.translatesAutoresizingMaskIntoConstraints = false
        widthTextField.placeholderString = "375"
        
        let heightLabel = NSTextField(labelWithString: "Height:")
        heightLabel.translatesAutoresizingMaskIntoConstraints = false
        
        heightTextField = NSTextField()
        heightTextField.translatesAutoresizingMaskIntoConstraints = false
        heightTextField.placeholderString = "667"
        
        // Icon Settings
        let iconLabel = NSTextField(labelWithString: "Menu Bar Icon:")
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        useFaviconCheckbox = NSButton(checkboxWithTitle: "Use website favicon", target: self, action: #selector(faviconToggled))
        useFaviconCheckbox.translatesAutoresizingMaskIntoConstraints = false
        
        let customIconLabel = NSTextField(labelWithString: "Custom Icon:")
        customIconLabel.translatesAutoresizingMaskIntoConstraints = false
        
        customIconTextField = NSTextField()
        customIconTextField.translatesAutoresizingMaskIntoConstraints = false
        customIconTextField.placeholderString = "Path to custom icon file"
        
        browseIconButton = NSButton(title: "Browse...", target: self, action: #selector(browseForIcon))
        browseIconButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Save Button
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveSettings))
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.keyEquivalent = "\r"
        
        // Add subviews
        [urlLabel, urlTextField, externalLinksCheckbox, sizeLabel, widthLabel, widthTextField, heightLabel, heightTextField, iconLabel, useFaviconCheckbox, customIconLabel, customIconTextField, browseIconButton, saveButton].forEach {
            view.addSubview($0)
        }
        
        // Constraints
        NSLayoutConstraint.activate([
            urlLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            urlLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            urlTextField.topAnchor.constraint(equalTo: urlLabel.bottomAnchor, constant: 8),
            urlTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            urlTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            externalLinksCheckbox.topAnchor.constraint(equalTo: urlTextField.bottomAnchor, constant: 20),
            externalLinksCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            sizeLabel.topAnchor.constraint(equalTo: externalLinksCheckbox.bottomAnchor, constant: 20),
            sizeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            widthLabel.topAnchor.constraint(equalTo: sizeLabel.bottomAnchor, constant: 8),
            widthLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            widthTextField.centerYAnchor.constraint(equalTo: widthLabel.centerYAnchor),
            widthTextField.leadingAnchor.constraint(equalTo: widthLabel.trailingAnchor, constant: 8),
            widthTextField.widthAnchor.constraint(equalToConstant: 80),
            
            heightLabel.centerYAnchor.constraint(equalTo: widthLabel.centerYAnchor),
            heightLabel.leadingAnchor.constraint(equalTo: widthTextField.trailingAnchor, constant: 20),
            
            heightTextField.centerYAnchor.constraint(equalTo: heightLabel.centerYAnchor),
            heightTextField.leadingAnchor.constraint(equalTo: heightLabel.trailingAnchor, constant: 8),
            heightTextField.widthAnchor.constraint(equalToConstant: 80),
            
            iconLabel.topAnchor.constraint(equalTo: widthLabel.bottomAnchor, constant: 20),
            iconLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            useFaviconCheckbox.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 8),
            useFaviconCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            customIconLabel.topAnchor.constraint(equalTo: useFaviconCheckbox.bottomAnchor, constant: 12),
            customIconLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            customIconTextField.topAnchor.constraint(equalTo: customIconLabel.bottomAnchor, constant: 8),
            customIconTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            customIconTextField.trailingAnchor.constraint(equalTo: browseIconButton.leadingAnchor, constant: -8),
            
            browseIconButton.centerYAnchor.constraint(equalTo: customIconTextField.centerYAnchor),
            browseIconButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            browseIconButton.widthAnchor.constraint(equalToConstant: 80),
            
            saveButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    func loadCurrentSettings() {
        urlTextField.stringValue = instance.targetURL
        externalLinksCheckbox.state = instance.openLinksExternally ? .on : .off
        widthTextField.stringValue = String(instance.windowWidth)
        heightTextField.stringValue = String(instance.windowHeight)
        useFaviconCheckbox.state = instance.useFavicon ? .on : .off
        customIconTextField.stringValue = instance.customIconPath ?? ""
        
        updateIconFieldsState()
    }
    
    @objc func faviconToggled() {
        updateIconFieldsState()
    }
    
    func updateIconFieldsState() {
        let useFavicon = useFaviconCheckbox.state == .on
        customIconTextField.isEnabled = !useFavicon
        browseIconButton.isEnabled = !useFavicon
    }
    
    @objc func browseForIcon() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp, .gif, .ico]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                customIconTextField.stringValue = url.path
            }
        }
    }
    
    @objc func saveSettings() {
        print("💾 Saving settings...")
        instance.targetURL = urlTextField.stringValue
        instance.openLinksExternally = externalLinksCheckbox.state == .on
        instance.useFavicon = useFaviconCheckbox.state == .on
        instance.customIconPath = customIconTextField.stringValue.isEmpty ? nil : customIconTextField.stringValue
        
        if let width = Int(widthTextField.stringValue), width > 0 {
            instance.windowWidth = width
        }
        
        if let height = Int(heightTextField.stringValue), height > 0 {
            instance.windowHeight = height
        }
        
        delegate?.settingsDidUpdate()
        view.window?.close()
    }
}
