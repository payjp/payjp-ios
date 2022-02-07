//
//  CardFormViewControllerDelegate.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2019/11/19.
//

import Foundation

/// CardFormViewController delegate.
@objc(PAYCardFormViewControllerDelegate)
public protocol CardFormViewControllerDelegate: AnyObject {

    /// Callback when card form operation is completed.
    ///
    /// - Parameter result: CardFormResult
    func cardFormViewController(_: CardFormViewController, didCompleteWith result: CardFormResult)

    /// Callback when creating token is completed.
    ///
    /// - Parameters:
    ///   - token: token created by card form
    ///   - completionHandler: completion action
    func cardFormViewController(_: CardFormViewController,
                                didProduced token: Token,
                                completionHandler: @escaping (Error?) -> Void)
}

/// Result of card form operation.
@objc public enum CardFormResult: Int {
    /// when saving token is successful
    case success = 0
    /// when card form screen is closed
    case cancel = 1
}
