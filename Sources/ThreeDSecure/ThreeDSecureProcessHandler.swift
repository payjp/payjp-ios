//
//  ThreeDSecureProcessHandler.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2020/03/30.
//  Copyright © 2020 PAY, Inc. All rights reserved.
//

import UIKit
import SafariServices

/// 3DSecure process status.
@objc public enum ThreeDSecureProcessStatus: Int {
    /// when 3DSecure process is completed.
    case completed
    /// when 3DSecure process is canceled.
    case canceled
}

/// 3DSecure handler delegate.
public protocol ThreeDSecureProcessHandlerDelegate: class {

    /// Tells the delegate that 3DSecure process is finished.
    /// - Parameters:
    ///   - handler: ThreeDSecureProcessHandler
    ///   - status: ThreeDSecureProcessStatus
    func threeDSecureProcessHandlerDidFinish(_ handler: ThreeDSecureProcessHandler,
                                             status: ThreeDSecureProcessStatus)
}

/// Handler for 3DSecure process.
public protocol ThreeDSecureProcessHandlerType {

    /// Stsart 3DSecure process
    /// Delegate will be released once the process is finished.
    /// - Parameters:
    ///   - viewController: the viewController which will present SFSafariViewController.
    ///   - delegate: ThreeDSecureProcessHandlerDelegate
    ///   - token: Token
    func startThreeDSecureProcess(viewController: UIViewController,
                                  delegate: ThreeDSecureProcessHandlerDelegate,
                                  token: Token)

    /// Complete 3DSecure process.
    /// - Parameters:
    ///   - url: redirect URL
    func completeThreeDSecureProcess(url: URL) -> Bool
}

/// see ThreeDSecureProcessHandlerType.
@objc(PAYJPThreeDSecureProcessHandler) @objcMembers
public class ThreeDSecureProcessHandler: NSObject, ThreeDSecureProcessHandlerType {

    /// Shared instance.
    @objc(sharedHandler)
    public static let shared = ThreeDSecureProcessHandler()

    private weak var delegate: ThreeDSecureProcessHandlerDelegate?
    private let webDriver: ThreeDSecureWebDriver

    public init(webDriver: ThreeDSecureWebDriver = ThreeDSecureSFSafariViewControllerDriver.shared) {
        self.webDriver = webDriver
    }

    // MARK: ThreeDSecureProcessHandlerType

    public func startThreeDSecureProcess(viewController: UIViewController,
                                         delegate: ThreeDSecureProcessHandlerDelegate,
                                         token: Token) {
        self.delegate = delegate
        webDriver.openWebBrowser(host: viewController, url: token.tdsEntryUrl, delegate: self)
    }

    public func completeThreeDSecureProcess(url: URL) -> Bool {
        print(debug: "tds redirect url => \(url)")

        if let redirectUrl = PAYJPSDK.threeDSecureURLConfiguration?.redirectURL {
            if url.absoluteString.starts(with: redirectUrl.absoluteString) {
                let topViewController = UIApplication.topViewController()
                return webDriver.closeWebBrowser(host: topViewController) { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.threeDSecureProcessHandlerDidFinish(self, status: .completed)
                    self.delegate = nil
                }
            }
        }
        return false
    }
}

// MARK: ThreeDSecureWebDriverDelegate
extension ThreeDSecureProcessHandler: ThreeDSecureWebDriverDelegate {

    public func webBrowseDidFinish(_ driver: ThreeDSecureWebDriver) {
        delegate?.threeDSecureProcessHandlerDidFinish(self, status: .canceled)
        delegate = nil
    }
}
