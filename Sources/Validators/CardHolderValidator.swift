//
//  CardHolderValidator.swift
//  PAYJP
//
//  Created by Tatsuya Kitagawa on 2024/10/02.
//  Copyright © 2024 PAY, Inc. All rights reserved.
//

import Foundation

protocol CardHolderValidatorType {
    func validate(cardHolder: String) -> CardHolderValidationResult
}

enum CardHolderValidationResult: Equatable {
    case valid
    case invalidCardHolderCharacter
    case invalidCardHolderLength
}

struct CardHolderValidator: CardHolderValidatorType {
    // swiftlint:disable force_try
    let regex = try! NSRegularExpression(pattern: "^[a-zA-Z0-9 \\-\\.]+$")
    // swiftlint:enable force_try
    func validate(cardHolder: String) -> CardHolderValidationResult {
        guard case 2...45 = cardHolder.count else {
            return .invalidCardHolderLength
        }
        let range = NSRange(location: 0, length: cardHolder.utf16.count)
        guard let _ = regex.firstMatch(in: cardHolder, options: [], range: range) else {
            return .invalidCardHolderCharacter
        }
        return .valid
    }
}
