//
//  CardHolderValidator.swift
//  PAYJP
//
//  Created by Tatsuya Kitagawa on 2024/10/02.
//  Copyright © 2024 PAY, Inc. All rights reserved.
//

import Foundation

protocol CardHolderValidatorType {
    func isValid(cardHolder: String) -> Bool
}

struct CardHolderValidator: CardHolderValidatorType {
    // swiftlint:disable force_try
    let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9 \\-\\.]+$")
    // swiftlint:enable force_try
    func isValid(cardHolder: String) -> Bool {
        let range = NSRange(location: 0, length: cardHolder.utf16.count)
        return regex.firstMatch(in: cardHolder, options: [], range: range) != nil
    }
}
