import XCTest
import WebKit
@testable import PAYJP

final class ThreeDSecureWebViewControllerTests: XCTestCase {
    func testUserAgentIsSetCorrectly() {
        let version = Bundle.payjpBundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let url = URL(string: "https://example.com")!
        let vc = ThreeDSecureWebViewController(url: url)
        let exp = expectation(description: "Retrieve UserAgent")

        _ = vc.view

        let webViewMirror = Mirror(reflecting: vc)
        guard let webView = webViewMirror.children.first(where: { $0.label == "webView" })?.value as? WKWebView else {
            XCTFail("Failed to retrieve webView")
            return
        }
        webView.evaluateJavaScript("navigator.userAgent") { result, error in
            guard let userAgent = result as? String else {
                XCTFail("Failed to retrieve UserAgent: \(error?.localizedDescription ?? "")")
                exp.fulfill()
                return
            }
            XCTAssertTrue(userAgent.contains("PAY.JP iOS WKWebView/\(version)"), "Expected value is not included in UserAgent: \(userAgent)")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }

    func testErrorIsDisplayedInWebView() {
        let url = URL(string: "http://invalid.invalid-domain-for-test-404.localhost/")!
        let vc = ThreeDSecureWebViewController(url: url)
        let exp = expectation(description: "Display error HTML")

        _ = vc.view

        let webViewMirror = Mirror(reflecting: vc)
        guard let webView = webViewMirror.children.first(where: { $0.label == "webView" })?.value as? WKWebView else {
            XCTFail("Failed to retrieve webView")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            webView.evaluateJavaScript("document.body.innerHTML") { result, error in
                guard let html = result as? String else {
                    XCTFail("Failed to retrieve HTML: \(error?.localizedDescription ?? "")")
                    exp.fulfill()
                    return
                }
                XCTAssertTrue(html.contains("A server with the specified hostname could not be found."), "Error content is not included in the HTML: \(html)")
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 10.0)
    }
}
