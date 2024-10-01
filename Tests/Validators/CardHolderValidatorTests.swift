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
        XCTAssertEqual(validator.isValid(cardHolder: "JANE DOE"), true)
        XCTAssertEqual(validator.isValid(cardHolder: "abcABC012 -."), true)
        XCTAssertEqual(validator.isValid(cardHolder: "山田たろう"), false)
    }
}
