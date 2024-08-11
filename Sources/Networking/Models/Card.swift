//
//  Card.swift
//  PAYJP
//
//  Created by k@binc.jp on 10/3/16.
//  Copyright © 2016 PAY, Inc. All rights reserved.
//
//  https://pay.jp/docs/api/#token-トークン
//
//

import Foundation

/// PAY.JP card object.
/// For security reasons, the card number is masked and you can get only last4 character.
/// The full documentations are following.
/// cf. [https://pay.jp/docs/api/#cardオブジェクト](https://pay.jp/docs/api/#cardオブジェクト)
@objcMembers @objc(PAYCard) public final class Card: NSObject, Decodable {
    public let identifer: String
    public let name: String?
    public let last4Number: String
    public let brand: String
    public let expirationMonth: UInt8
    public let expirationYear: UInt16
    public let fingerprint: String
    public let liveMode: Bool
    public let createdAt: Date
    public let threeDSecureStatus: PAYThreeDSecureStatus?
    public let email: String?
    public let phone: String?
    public var rawValue: [String: Any]?

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case last4Number = "last4"
        case brand
        case expirationMonth = "exp_month"
        case expirationYear = "exp_year"
        case fingerprint
        case liveMode = "livemode"
        case createdAt = "created"
        case threeDSecureStatus = "three_d_secure_status"
        case email
        case phone
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifer = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        last4Number = try container.decode(String.self, forKey: .last4Number)
        brand = try container.decode(String.self, forKey: .brand)
        expirationMonth = try container.decode(UInt8.self, forKey: .expirationMonth)
        expirationYear = try container.decode(UInt16.self, forKey: .expirationYear)
        fingerprint = try container.decode(String.self, forKey: .fingerprint)
        liveMode = try container.decode(Bool.self, forKey: .liveMode)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        if let tdsStatusRaw = try container.decodeIfPresent(String.self, forKey: .threeDSecureStatus) {
            threeDSecureStatus = ThreeDSecureStatus.find(rawValue: tdsStatusRaw)
        } else {
            threeDSecureStatus = nil
        }
        email = try container.decodeIfPresent(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
    }

    public init(identifier: String,
                name: String?,
                last4Number: String,
                brand: String,
                expirationMonth: UInt8,
                expirationYear: UInt16,
                fingerprint: String,
                liveMode: Bool,
                createAt: Date,
                threeDSecureStatus: PAYThreeDSecureStatus?,
                email: String?,
                phone: String?,
                rawValue: [String: Any]? = nil ) {
        self.identifer = identifier
        self.name = name
        self.last4Number = last4Number
        self.brand = brand
        self.expirationMonth = expirationMonth
        self.expirationYear = expirationYear
        self.fingerprint = fingerprint
        self.liveMode = liveMode
        self.createdAt = createAt
        self.threeDSecureStatus = threeDSecureStatus
        self.email = email
        self.phone = phone
        self.rawValue = rawValue
    }
}
