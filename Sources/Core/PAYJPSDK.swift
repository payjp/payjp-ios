//
//  PAYJPSDK.swift
//  PAYJP
//
//  Created by Li-Hsuan Chen on 2019/07/24.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import Foundation
#if SWIFT_PACKAGE
@_exported import PAYJP_ObjC
#endif

/// PAY.JP SDK initial settings.
public protocol PAYJPSDKType: AnyObject {
    /// PAY.JP public key.
    static var publicKey: String? { get set }
    /// Locale.
    static var locale: Locale? { get set }
    /// 3DSecure URL configuration.
    static var threeDSecureURLConfiguration: ThreeDSecureURLConfiguration? { get set }
}

/// see PAYJPSDKType.
@objc(PAYJPSDK) @objcMembers
public final class PAYJPSDK: NSObject, PAYJPSDKType {

    private override init() {}

    // MARK: - PAYJPSDKType

    public static var publicKey: String? {
        didSet {
            guard let publicKey = publicKey else {
                authToken = ""
                return
            }
            // public key validation
            PublicKeyValidator.shared.validate(publicKey: publicKey)

            let data = "\(publicKey):".data(using: .utf8)!
            let base64String = data.base64EncodedString()
            authToken = "Basic \(base64String)"
        }
    }
    public static var locale: Locale?

    public static var threeDSecureURLConfiguration: ThreeDSecureURLConfiguration?

    public static var clientInfo: ClientInfo = .default

    // Update by Fastlane :bump_up_version
    public static let sdkVersion: String = "1.6.1"

    static var authToken: String = ""
}
