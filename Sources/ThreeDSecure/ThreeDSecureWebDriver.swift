//
//  ThreeDSecureWebDriver.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2020/04/06.
//  Copyright © 2020 PAY, Inc. All rights reserved.
//

import Foundation
import SafariServices

/// Delegate of web browse driver.
public protocol ThreeDSecureWebDriverDelegate: AnyObject {

    /// Tells the delegate that web browsing is finished.
    /// - Parameter driver: ThreeDSecureWebDriver
    func webBrowseDidFinish(_ driver: ThreeDSecureWebDriver)
}

/// Web browse driver for 3DSecure.
public protocol ThreeDSecureWebDriver {

    /// Open web browser.
    /// - Parameters:
    ///   - host: host ViewController
    ///   - url: load url
    ///   - delegate: ThreeDSecureWebDriverDelegate
    func openWebBrowser(host: UIViewController, url: URL, delegate: ThreeDSecureWebDriverDelegate)

    /// Close web browser.
    /// - Parameters:
    ///   - host: host ViewController
    ///   - completion: completion action after dismiss SFSafariViewController
    func closeWebBrowser(host: UIViewController?, completion: (() -> Void)?) -> Bool
}
