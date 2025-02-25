//
//  ThreeDSecureURLConfiguration.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2020/03/31.
//

import Foundation

/// Configuration for using URL in 3DSecure process.
@objcMembers @objc(PAYThreeDSecureURLConfiguration)
public class ThreeDSecureURLConfiguration: NSObject {
    /// Redirect URL for launching app from web.
    let redirectURL: URL
    /// Redirect URL key.
    let redirectURLKey: String

    public init(redirectURL: URL, redirectURLKey: String) {
        self.redirectURL = redirectURL
        self.redirectURLKey = redirectURLKey
    }

    public func makeThreeDSecureEntryURL(resourceId: String) -> URL {
        let baseUrl = URL(string: "\(PAYJPApiEndpoint)tds/\(resourceId)")!
        let url = baseUrl.appendingPathComponent("start")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "publickey", value: PAYJPSDK.publicKey),
            URLQueryItem(name: "back", value: redirectURLKey)
        ]
        return components.url!
    }
}
