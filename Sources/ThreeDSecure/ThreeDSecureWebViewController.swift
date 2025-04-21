import UIKit
import WebKit

protocol ThreeDSecureWebViewControllerDelegate: AnyObject {
    func webViewControllerDidFinish(_ controller: ThreeDSecureWebViewController, completed: Bool)
}

@objcMembers open class ThreeDSecureWebViewController: UIViewController {

    // MARK: - Properties

    private static let timeoutInterval: TimeInterval = 10.0

    private let webView: WKWebView
    private let navigationBar = UINavigationBar()
    private let initialURL: URL
    weak var delegate: ThreeDSecureWebViewControllerDelegate?

    // MARK: - Initialization

    /// 指定されたURLおよびオプションで許可ドメインを指定してWebViewControllerを初期化する。
    ///
    /// - Parameters:
    ///   - url: WebViewで最初に読み込むURL。
    @objc public init(
        url: URL
    ) {
        self.initialURL = url

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let version = Bundle.payjpBundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        configuration.applicationNameForUserAgent = "PAY.JP iOS WKWebView/\(version)"
        if #available(iOS 14.0, *) {
            let preferences = WKWebpagePreferences()
            preferences.allowsContentJavaScript = true
            configuration.defaultWebpagePreferences = preferences
        } else {
            configuration.preferences.javaScriptEnabled = true
        }
        self.webView = WKWebView(frame: .zero, configuration: configuration)

        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError(
            "init(coder:) has not been implemented. Use init(url: URL) instead."
        )
    }

    // MARK: - Lifecycle Methods

    override open func viewDidLoad() {
        super.viewDidLoad()

        setupWebView()
        setupNavigationBar()
        layoutUI()

        loadInitialURL()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isMovingFromParent || isBeingDismissed {
            webView.stopLoading()
            webView.navigationDelegate = nil
        }
    }

    // MARK: - Setup

    private func setupWebView() {
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        view.addSubview(webView)
    }

    private func setupNavigationBar() {
        let navItem = UINavigationItem()
        if #available(iOS 13.0, *) {
            navigationBar.barTintColor = UIColor.systemBackground
        }
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("payjp_common_close".localized, for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        navItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)
        navigationBar.items = [navItem]
    }

    private func layoutUI() {
        NSLayoutConstraint.activate([
            navigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),

            webView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Actions

    private func loadInitialURL() {
        let request = URLRequest(url: initialURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: Self.timeoutInterval)
        webView.load(request)
    }

    @objc private func closeButtonTapped() {
        delegate?.webViewControllerDidFinish(self, completed: false)
    }
}

// MARK: - WKNavigationDelegate

extension ThreeDSecureWebViewController: WKNavigationDelegate {

    public func webView(
        _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor(WKNavigationActionPolicy) -> Void
    ) {

        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        print("WebView navigation action: \(url)")

        // 設定されたリダイレクトURLに前方一致するかチェック
        if let redirectUrl = PAYJPSDK.threeDSecureURLConfiguration?.redirectURL,
           url.absoluteString.starts(with: redirectUrl.absoluteString) {
            print("Detected redirect URL, attempting to open: \(url)")
            UIApplication.shared.open(url, options: [:]) { [weak self] success in
                guard let self = self else { return }
                if success {
                    print("Successfully opened redirect URL: \(url)")
                    self.delegate?.webViewControllerDidFinish(self, completed: true)
                }
            }
            decisionHandler(.cancel)
            return
        }

        // Resource.bundle配下のfileスキームのみ許可
        if let scheme = url.scheme?.lowercased(), scheme == "file" {
            let resourceBundlePath = Bundle.resourceBundle.bundlePath
            if url.path.hasPrefix(resourceBundlePath + "/") {
                decisionHandler(.allow)
                return
            } else {
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }

    public func webView(
        _ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        print("WebView started loading: \(webView.url?.absoluteString ?? "")")
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView finished loading: \(webView.url?.absoluteString ?? "")")
    }

    public func webView(
        _ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error
    ) {
        print("WebView failed navigation with error: \(error)")
        loadErrorHTML(in: webView, error: error)
    }

    public func webView(
        _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        print("WebView failed provisional navigation with error: \(error)")
        loadErrorHTML(in: webView, error: error)
    }

    private func loadErrorHTML(in webView: WKWebView, error: Error? = nil) {
        let resourceBundle = Bundle.resourceBundle
        guard let htmlURL = resourceBundle.url(forResource: "tdserror", withExtension: "html"),
              let htmlData = try? Data(contentsOf: htmlURL),
              var htmlString = String(data: htmlData, encoding: .utf8) else {
            return
        }
        let errorMessage = error?.localizedDescription ?? ""
        htmlString = htmlString.replacingOccurrences(of: "{{errorMessage}}", with: errorMessage)
        webView.loadHTMLString(htmlString, baseURL: htmlURL.deletingLastPathComponent())
    }
}
