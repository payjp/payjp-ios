import Foundation
import UIKit

public class ThreeDSecureWebViewControllerDriver: NSObject, ThreeDSecureWebDriver {

    public static let shared = ThreeDSecureWebViewControllerDriver()

    private weak var webDriverDelegate: ThreeDSecureWebDriverDelegate?
    private weak var webViewController: ThreeDSecureWebViewController?

    public func openWebBrowser(host: UIViewController, url: URL, delegate: ThreeDSecureWebDriverDelegate) {
        closeWebBrowserInternal {}

        let webVC = ThreeDSecureWebViewController(url: url)
        webVC.delegate = self
        webVC.modalPresentationStyle = .fullScreen
        self.webDriverDelegate = delegate
        self.webViewController = webVC

        host.present(webVC, animated: true, completion: nil)
    }

    public func closeWebBrowser(host: UIViewController?, completion: (() -> Void)?) -> Bool {
        if host == nil || host === self.webViewController {
            return closeWebBrowserInternal(completion: completion)
        }
        completion?()
        return false
    }

    @discardableResult
    private func closeWebBrowserInternal(completion: (() -> Void)? = nil) -> Bool {
        guard let webVC = self.webViewController else {
            completion?()
            return false
        }

        guard webVC.presentingViewController != nil || webVC.navigationController?.isBeingDismissed == false else {
            completion?()
            return false
        }

        webVC.dismiss(animated: true) { [weak self] in
            self?.webViewController = nil
            completion?()
        }
        return true
    }
}

// MARK: - ThreeDSecureWebViewControllerDelegate
extension ThreeDSecureWebViewControllerDriver: ThreeDSecureWebViewControllerDelegate {

    func webViewControllerDidFinish(_ controller: ThreeDSecureWebViewController, completed: Bool) {
        closeWebBrowserInternal { [weak self] in
            guard let self = self else { return }
            if !completed {
                self.webDriverDelegate?.webBrowseDidFinish(self)
            }
        }
    }
}
