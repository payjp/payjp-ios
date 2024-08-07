//
//  CardFormViewModelTests.swift
//  PAYJPTests
//
//  Created by Tadashi Wakayanagi on 2019/08/08.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import XCTest
import AVFoundation
@testable import PAYJP

// swiftlint:disable type_body_length
class CardFormViewModelTests: XCTestCase {

    let viewModel = CardFormViewViewModel()

    func testUpdateCardNumberEmpty() {
        let result = viewModel.update(cardNumber: "", separator: "-")

        switch result {
        case .failure(let error):
            switch error {
            case .cardNumberEmptyError(value: nil, isInstant: false):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateCardNumberNil() {
        let result = viewModel.update(cardNumber: nil, separator: "-")

        switch result {
        case .failure(let error):
            switch error {
            case .cardNumberEmptyError(value: nil, isInstant: false):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateCardNumberInvalidLength() {
        let result = viewModel.update(cardNumber: "4242424242", separator: "-")
        //        let cardNumber = CardNumber(formatted: "4242 4242 42", brand: .visa)

        switch result {
        case .failure(let error):
            switch error {
            case .cardNumberInvalidError(value: _, isInstant: false):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateCardNumberInvalidLuhn() {
        let result = viewModel.update(cardNumber: "4242424242424241", separator: "-")
        //        let cardNumber = CardNumber(formatted: "4242 4242 4242 4241", brand: .visa)

        switch result {
        case .failure(let error):
            switch error {
            case .cardNumberInvalidError(value: _, isInstant: true):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateCardNumberSuccess() {
        let result = viewModel.update(cardNumber: "4242424242424242", separator: "-")

        switch result {
        case .success(let value):
            XCTAssertEqual(value.formatted, "4242-4242-4242-4242")
            XCTAssertEqual(value.brand, .visa)
        default:
            XCTFail()
        }
    }

    func testUpdateExpirationEmpty() {
        let result = viewModel.update(expiration: "")

        switch result {
        case .failure(let error):
            switch error {
            case .expirationEmptyError(value: nil, isInstant: false):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateExpirationNil() {
        let result = viewModel.update(expiration: nil)

        switch result {
        case .failure(let error):
            switch error {
            case .expirationEmptyError(value: nil, isInstant: false):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateExpirationInvalidMonth() {
        let result = viewModel.update(expiration: "15")

        switch result {
        case .failure(let error):
            switch error {
            case .expirationInvalidError(value: _, isInstant: true):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateExpirationInvalidYear() {
        let result = viewModel.update(expiration: "08/10")

        switch result {
        case .failure(let error):
            switch error {
            case .expirationInvalidError(value: _, isInstant: true):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateExpirationOneDigitMonth() {
        let result = viewModel.update(expiration: "1")

        switch result {
        case .failure(let error):
            switch error {
            case .expirationInvalidError(value: _, isInstant: false):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateExpirationTwoDigitMonth() {
        let result = viewModel.update(expiration: "20")

        switch result {
        case .failure(let error):
            switch error {
            case .expirationInvalidError(value: _, isInstant: false):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateExpirationSuccess() {
        let result = viewModel.update(expiration: "12/99")

        switch result {
        case .success(let value):
            XCTAssertEqual(value.formatted, "12/99")
            XCTAssertEqual(value.display, "12/99")
        default:
            XCTFail()
        }
    }

    func testUpdateCvcEmpty() {
        let result = viewModel.update(cvc: "")

        switch result {
        case .failure(let error):
            switch error {
            case .cvcEmptyError(value: nil, isInstant: false):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateCvcNil() {
        let result = viewModel.update(cvc: nil)

        switch result {
        case .failure(let error):
            switch error {
            case .cvcEmptyError(value: nil, isInstant: false):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateCvcInvalid() {
        let result = viewModel.update(cvc: "12")

        switch result {
        case .failure(let error):
            switch error {
            case .cvcInvalidError(value: "12", isInstant: false):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateCvcSuccess() {
        _ = viewModel.update(cardNumber: "42", separator: "-")
        let result = viewModel.update(cvc: "123")

        switch result {
        case .success(let value):
            XCTAssertEqual(value, "123")
        default:
            XCTFail()
        }
    }

    func testUpdateCvcWhenBrandChanged() {
        _ = viewModel.update(cardNumber: "4242", separator: "-")
        let result = viewModel.update(cvc: "1234")

        switch result {
        case .failure(let error):
            switch error {
            case .cvcInvalidError(value: "1234", isInstant: true):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateCardHolderEmpty() {
        let result = viewModel.update(cardHolder: "")

        switch result {
        case .failure(let error):
            switch error {
            case .cardHolderEmptyError(value: nil, isInstant: false):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateCardHolderNil() {
        let result = viewModel.update(cardHolder: nil)

        switch result {
        case .failure(let error):
            switch error {
            case .cardHolderEmptyError(value: nil, isInstant: false):
                break
            default:
                XCTFail()
            }
        default:
            XCTFail()
        }
    }

    func testUpdateCardHolderSuccess() {
        let result = viewModel.update(cardHolder: "PAY TARO")

        switch result {
        case .success(let value):
            XCTAssertEqual(value, "PAY TARO")
        default:
            XCTFail()
        }
    }

    func testIsValidAllValid() {
        _ = viewModel.update(cardNumber: "4242424242424242", separator: "-")
        _ = viewModel.update(expiration: "12/99")
        _ = viewModel.update(cvc: "123")
        _ = viewModel.update(cardHolder: "PAY TARO")

        let result = viewModel.isValid
        XCTAssertTrue(result)
    }

    func testIsValidNotAllValid() {
        _ = viewModel.update(cardNumber: "4242424242424242", separator: "-")
        _ = viewModel.update(expiration: "12/9")
        _ = viewModel.update(cvc: "123")
        _ = viewModel.update(cardHolder: "PAY TARO")

        let result = viewModel.isValid
        XCTAssertFalse(result)
    }

    func testRequestOcr_notAuthorized() {
        let expectation = self.expectation(description: "view update")
        let mockPermissionFetcher = MockPermissionFetcher(status: AVAuthorizationStatus.notDetermined,
                                                          shouldAccess: true)
        let delegate = MockCardFormViewModelDelegate(expectation: expectation)
        let viewModel = CardFormViewViewModel(permissionFetcher: mockPermissionFetcher)
        viewModel.delegate = delegate
        viewModel.requestOcr()

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertTrue(delegate.startScannerCalled)
        XCTAssertFalse(delegate.showPermissionAlertCalled)
    }

    func testRequestOcr_authorized() {
        let mockPermissionFetcher = MockPermissionFetcher(status: AVAuthorizationStatus.authorized)
        let delegate = MockCardFormViewModelDelegate()
        let viewModel = CardFormViewViewModel(permissionFetcher: mockPermissionFetcher)
        viewModel.delegate = delegate
        viewModel.requestOcr()

        XCTAssertTrue(delegate.startScannerCalled)
        XCTAssertFalse(delegate.showPermissionAlertCalled)
    }

    func testRequestOcr_denied() {
        let mockPermissionFetcher = MockPermissionFetcher(status: AVAuthorizationStatus.denied)
        let delegate = MockCardFormViewModelDelegate()
        let viewModel = CardFormViewViewModel(permissionFetcher: mockPermissionFetcher)
        viewModel.delegate = delegate
        viewModel.requestOcr()

        XCTAssertFalse(delegate.startScannerCalled)
        XCTAssertTrue(delegate.showPermissionAlertCalled)
    }

    func testRequestOcr_other() {
        let mockPermissionFetcher = MockPermissionFetcher(status: AVAuthorizationStatus.restricted)
        let delegate = MockCardFormViewModelDelegate()
        let viewModel = CardFormViewViewModel(permissionFetcher: mockPermissionFetcher)
        viewModel.delegate = delegate
        viewModel.requestOcr()

        XCTAssertFalse(delegate.startScannerCalled)
        XCTAssertFalse(delegate.showPermissionAlertCalled)
    }
}
// swiftlint:enable type_body_length
