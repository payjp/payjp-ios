//
//  CardHolderValidatorTests.swift
//  PAYJP
//
//  Created by Tatsuya Kitagawa on 2024/10/02.
//  Copyright © 2024 PAY, Inc. All rights reserved.
//

import XCTest
@testable import PAYJP

class CardHolderValidatorTests: XCTestCase {
    func testCardHolderValidation() {
        let validator = CardHolderValidator()
        XCTAssertEqual(validator.validate(cardHolder: "JANE DOE"), .valid)
        XCTAssertEqual(validator.validate(cardHolder: "abcABC012 -."), .valid)
        XCTAssertEqual(validator.validate(cardHolder: "山田たろう"), .invalidCardHolderCharacter)
        // 全角スペースは不可
        XCTAssertEqual(validator.validate(cardHolder: "JANE　DOE"), .invalidCardHolderCharacter)
        // 全角数字は不可
        XCTAssertEqual(validator.validate(cardHolder: "１２３"), .invalidCardHolderCharacter)
        // 46文字以上は不可
        XCTAssertEqual(validator.validate(cardHolder: "1234567890123456789012345678901234567890123456"), .invalidCardHolderLength)
        // 45文字はOK
        XCTAssertEqual(validator.validate(cardHolder: "123456789012345678901234567890123456789012345"), .valid)
    }
}
