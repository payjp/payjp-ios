//
//  CardFormInput.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2019/12/05.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import Foundation

struct CardFormInput {
    let cardNumber: String
    let expirationMonth: String
    let expirationYear: String
    let cvc: String
    let cardHolder: String?
    let email: String?
    let phoneNumber: String?
}
