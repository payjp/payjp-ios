//
//  ThreeDSecureSFSafariViewControllerDriver.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2020/04/06.
//  Copyright © 2020 PAY, Inc. All rights reserved.
//

import Foundation
import SafariServices

/// Web browse driver for SFSafariViewController.
public class ThreeDSecureSFSafariViewControllerDriver: NSObject, ThreeDSecureWebDriver {

    /// Shared instance.
    public static let shared = ThreeDSecureSFSafariViewControllerDriver()

    private weak var delegate: ThreeDSecureWebDriverDelegate?

    public func openWebBrowser(host: UIViewController, url: URL, delegate: ThreeDSecureWebDriverDelegate) {
        let safariVc = SFSafariViewController(url: url)
        safariVc.dismissButtonStyle = .close
        safariVc.delegate = self
        safariVc.modalPresentationStyle = .overFullScreen
        self.delegate = delegate
        host.present(safariVc, animated: true, completion: nil)
    }

    public func closeWebBrowser(host: UIViewController?, completion: (() -> Void)?) -> Bool {
        if host is SFSafariViewController {
            host?.dismiss(animated: true) {
                completion?()
            }
            return true
        }
        return false
    }
}

// MARK: SFSafariViewControllerDelegate
extension ThreeDSecureSFSafariViewControllerDriver: SFSafariViewControllerDelegate {

    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        delegate?.webBrowseDidFinish(self)
    }
}
