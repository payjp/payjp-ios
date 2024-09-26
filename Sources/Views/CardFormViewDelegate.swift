//
//  CardFormViewDelegate.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2019/10/11.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import UIKit

/// CardFormView delegate.
@objc(PAYCardFormViewDelegate)
public protocol CardFormViewDelegate: AnyObject {

    /// Callback when form input validated
    ///
    /// - Parameters:
    ///   - cardFormView: CardFormView
    ///   - isValid: form is valid
    func formInputValidated(in cardFormView: UIView, isValid: Bool)

    /// Callback when keyboard done key tapped. It's available only card holder input field.
    ///
    /// - Parameter cardFormView: CardFormView
    func formInputDoneTapped(in cardFormView: UIView)
}

/// CardForm action protocol.
public protocol CardFormAction {

    /// Form is valid
    var isValid: Bool { get }

    /// Create token for swift
    ///
    /// - Parameters:
    ///   - tenantId: identifier of tenant
    ///   - useThreeDSecure: Whether use 3-D secure or not
    ///   - completion: completion action
    func createToken(tenantId: String?, useThreeDSecure: Bool, completion: @escaping (Result<Token, Error>) -> Void)

    /// Create token for objective-c
    ///
    /// - Parameters:
    ///   - tenantId: identifier of tenant
    ///   - useThreeDSecure: Whether use 3-D secure or not
    ///   - completion: completion action
    func createTokenWith(_ tenantId: String?, useThreeDSecure: Bool, completion: @escaping (Token?, NSError?) -> Void)

    /// Fetch accepted card brands for swift
    ///
    /// - Parameters:
    ///   - tenantId: tenantId identifier of tenant
    ///   - completion: completion action
    func fetchBrands(tenantId: String?, completion: CardBrandsResult?)

    /// Fetch accepted card brands for objective-c
    ///
    /// - Parameters:
    ///   - tenantId: tenantId identifier of tenant
    ///   - completion: completion action
    func fetchBrandsWith(_ tenantId: String?, completion: (([NSString]?, NSError?) -> Void)?)

    /// Validate card form
    ///
    /// - Returns: is valid form
    func validateCardForm() -> Bool

    /// Setup input accessory view of text field
    ///
    /// - Parameter view: input accessory view
    func setupInputAccessoryView(view: UIView)

    /// Enable extra attributes for 3-D Secure.
    /// Both [ExtraAttributesEmail] and [ExtraAttributesPhone] is enabled as default.
    /// - Parameters:
    ///  - extraAttributes: array of attributes.
    func apply(extraAttributes: [ExtraAttribute])
}
