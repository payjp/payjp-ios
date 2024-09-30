//
//  CreateTokenRequest.swift
//  PAYJP
//
//  Created by Li-Hsuan Chen on 2019/07/25.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import Foundation

struct CreateTokenRequest: BaseRequest {
    typealias Response = Token

    var path: String = "tokens"
    var httpMethod: String = "POST"
    var bodyParameters: [String: String]? {
        var parameters = [
            "card[number]": cardNumber,
            "card[cvc]": cvc,
            "card[exp_month]": expirationMonth,
            "card[exp_year]": expirationYear
        ]

        parameters["card[name]"] = name
        parameters["tenant"] = tenantId
        parameters["card[email]"] = email
        parameters["card[phone]"] = phone
        parameters["three_d_secure"] = String(threeDSecure)
        return parameters
    }

    // MARK: - Data

    let cardNumber: String
    let cvc: String
    let expirationMonth: String
    let expirationYear: String
    let name: String?
    let tenantId: String?
    let email: String?
    let phone: String?
    let threeDSecure: Bool
}
