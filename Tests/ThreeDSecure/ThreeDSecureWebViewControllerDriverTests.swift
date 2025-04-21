import XCTest
@testable import PAYJP

final class ThreeDSecureWebViewControllerDriverTests: XCTestCase {
    class DummyHostViewController: UIViewController {
        var presentedVC: UIViewController?
        override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
            presentedVC = viewControllerToPresent
            completion?()
        }
    }

    class DummyDelegate: ThreeDSecureWebDriverDelegate {
        var didFinishCalled = false
        func webBrowseDidFinish(_ driver: ThreeDSecureWebDriver) {
            didFinishCalled = true
        }
    }

    func testOpenWebBrowser_presentsWebViewController() {
        let driver = ThreeDSecureWebViewControllerDriver()
        let host = DummyHostViewController()
        let delegate = DummyDelegate()
        let url = URL(string: "https://example.com")!

        driver.openWebBrowser(host: host, url: url, delegate: delegate)
        XCTAssertTrue(host.presentedVC is ThreeDSecureWebViewController)
    }

    func testCloseWebBrowser_dismissesWebViewController() {
        let driver = ThreeDSecureWebViewControllerDriver()
        let host = DummyHostViewController()
        let delegate = DummyDelegate()
        let url = URL(string: "https://example.com")!
        driver.openWebBrowser(host: host, url: url, delegate: delegate)
        let result = driver.closeWebBrowser(host: nil, completion: nil)
        XCTAssertTrue(result)
    }

    func testWebViewControllerDidFinish_callsDelegate() {
        let driver = ThreeDSecureWebViewControllerDriver()
        let host = DummyHostViewController()
        let delegate = DummyDelegate()
        let url = URL(string: "https://example.com")!
        driver.openWebBrowser(host: host, url: url, delegate: delegate)
        if let webVC = host.presentedVC as? ThreeDSecureWebViewController {
            (driver as? ThreeDSecureWebViewControllerDriver)?.webViewControllerDidFinish(webVC, completed: false)
            XCTAssertTrue(delegate.didFinishCalled)
        } else {
            XCTFail("WebViewController was not presented")
        }
    }
}
