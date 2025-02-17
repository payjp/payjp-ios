//
//  Token.swift
//  PAYJP
//
//  Created by k@binc.jp on 9/29/16.
//  Copyright © 2016 PAY, Inc. All rights reserved.
//
//  https://pay.jp/docs/api/#token-トークン
//

import Foundation

typealias RawValue = [String: Any]

/// PAY.JP token object.
/// cf. [https://pay.jp/docs/api/#token-トークン](https://pay.jp/docs/api/#token-トークン)
@objcMembers @objc(PAYToken) public final class Token: NSObject, Decodable {
    public let identifer: String
    public let livemode: Bool
    public let used: Bool
    public let card: Card
    public let createdAt: Date
    public var rawValue: [String: Any]?

    // MARK: - Decodable

    private enum CodingKeys: String, CodingKey {
        case id = "id"
        case livemode
        case used
        case card
        case createdAt = "created"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifer = try container.decode(String.self, forKey: .id)
        livemode = try container.decode(Bool.self, forKey: .livemode)
        used = try container.decode(Bool.self, forKey: .used)
        card = try container.decode(Card.self, forKey: .card)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    public init(identifier: String,
                livemode: Bool,
                used: Bool,
                card: Card,
                createAt: Date,
                rawValue: [String: Any]? = nil) {
        self.identifer = identifier
        self.livemode = livemode
        self.used = used
        self.card = card
        self.createdAt = createAt
        self.rawValue = rawValue
    }
}

extension Token: JSONDecodable {

    /**
     * Provide a factory function to decode json by JSONDecoder
     * and also desereialize all fields as a arbitrary dictionary by JSONSerialization.
     */
    static func decodeJson(with data: Data, using decoder: JSONDecoder) throws -> Token {
        let token = try decoder.decode(self, from: data)
        // assign rawValue by JSONSerialization
        let jsonOptions = JSONSerialization.ReadingOptions.allowFragments
        guard let rawValue = try JSONSerialization.jsonObject(with: data,
                                                              options: jsonOptions) as? RawValue,
              let cardRawValue = rawValue["card"] as? RawValue else {
            let context = DecodingError.Context(codingPath: [],
                                                debugDescription: "Cannot deserialize rawValue")
            throw DecodingError.dataCorrupted(context)
        }
        token.rawValue = rawValue
        token.card.rawValue = cardRawValue
        return token
    }
}

extension Token {
    public override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Token {
            return self.identifer == object.identifer
        }

        return false
    }
}
