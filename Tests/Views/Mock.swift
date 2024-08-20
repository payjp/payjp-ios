//
//  Mock.swift
//  PAYJP
//
//  Created by Tadashi Wakayanagi on 2019/12/06.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import XCTest
import PassKit
import AVFoundation
@testable import PAYJP

class MockCardFormScreenDelegate: CardFormScreenDelegate {
    var fetchedBrands: [CardBrand] = []
    var showIndicatorCalled = false
    var dismissIndicatorCalled = false
    var enableSubmitButtonCalled = false
    var disableSubmitButtonCalled = false
    var showErrorViewMessage: String?
    var showErrorViewButtonHidden = false
    var dismissErrorViewCalled = false
    var showErrorAlertMessage: String?
    var presentVerificationScreenToken: Token?
    var didCompleteCardFormCalled = false
    var didProducedCalled = false

    let error: Error?
    let expectation: XCTestExpectation?

    init(error: Error? = nil, expectation: XCTestExpectation? = nil) {
        self.error = error
        self.expectation = expectation
    }

    func reloadBrands(brands: [CardBrand]) {
        fetchedBrands = brands
        expectation?.fulfill()
    }

    func showIndicator() {
        showIndicatorCalled = true
    }

    func dismissIndicator() {
        dismissIndicatorCalled = true
    }

    func enableSubmitButton() {
        enableSubmitButtonCalled = true
    }

    func disableSubmitButton() {
        disableSubmitButtonCalled = true
    }

    func showErrorView(message: String, buttonHidden: Bool) {
        showErrorViewMessage = message
        showErrorViewButtonHidden = buttonHidden
        expectation?.fulfill()
    }

    func dismissErrorView() {
        dismissErrorViewCalled = true
    }

    func showErrorAlert(message: String) {
        showErrorAlertMessage = message
        expectation?.fulfill()
    }

    func presentVerificationScreen(token: Token) {
        presentVerificationScreenToken = token
        expectation?.fulfill()
    }

    func didCompleteCardForm(with result: CardFormResult) {
        didCompleteCardFormCalled = true
        expectation?.fulfill()
    }

    func didProduced(with token: Token, completionHandler: @escaping (Error?) -> Void) {
        didProducedCalled = true
        completionHandler(error)
    }
}

class MockTokenService: TokenServiceType {
    var createTokenResult: Result<Token, APIError>?
    var createTokenTenantId: String?
    var finishTokenThreeDSecureResult: Result<Token, APIError>?
    var finishTokenThreeDSecureTokenId: String?
    var getTokenResult: Result<Token, APIError>?
    var getTokenTokenId: String?
    let tokenOperationObserver: TokenOperationObserverType = MockTokenOperationObserverType()

    // swiftlint:disable function_parameter_count
    func createToken(cardNumber: String,
                     cvc: String,
                     expirationMonth: String,
                     expirationYear: String,
                     name: String?,
                     tenantId: String?,
                     email: String?,
                     phone: String?,
                     completion: @escaping (Result<Token, APIError>) -> Void) -> URLSessionDataTask? {

        self.createTokenTenantId = tenantId
        guard let result = createTokenResult else {
            fatalError("Set createTokenResult before invoked.")
        }
        completion(result)
        return nil
    }
    // swiftlint:enable function_parameter_count

    func createTokenForApplePay(paymentToken: PKPaymentToken,
                                completion: @escaping (Result<Token, APIError>) -> Void) -> URLSessionDataTask? {
        return nil
    }

    func finishTokenThreeDSecure(tokenId: String,
                                 completion: @escaping (Result<Token, APIError>) -> Void) -> URLSessionDataTask? {
        self.finishTokenThreeDSecureTokenId = tokenId
        guard let result = finishTokenThreeDSecureResult else {
            fatalError("Set finishTokenThreeDSecureResult before invoked.")
        }
        completion(result)
        return nil
    }

    func getToken(with tokenId: String,
                  completion: @escaping (Result<Token, APIError>) -> Void) -> URLSessionDataTask? {

        self.getTokenTokenId = tokenId
        guard let result = getTokenResult else {
            fatalError("Set getTokenResult before invoked.")
        }
        completion(result)
        return nil
    }
}

class MockAccountService: AccountsServiceType {
    let brands: [CardBrand]
    let error: APIError?
    var calledTenantId: String?

    init(brands: [CardBrand], error: APIError? = nil) {
        self.brands = brands
        self.error = error
    }

    func getAcceptedBrands(tenantId: String?,
                           completion: CardBrandsResult?) -> URLSessionDataTask? {

        self.calledTenantId = tenantId

        if let error = error {
            completion?(.failure(error))
        } else {
            completion?(.success(brands))
        }

        return nil
    }
}

class MockPermissionFetcher: PermissionFetcherType {
    let status: AVAuthorizationStatus
    let shouldAccess: Bool
    //    var completion : (() -> Void)?

    init(status: AVAuthorizationStatus = .notDetermined,
         shouldAccess: Bool = false) {
        self.status = status
        self.shouldAccess = shouldAccess
    }

    func checkCamera() -> AVAuthorizationStatus {
        return self.status
    }

    func requestCamera(completion: @escaping () -> Void) {
        if shouldAccess {
            completion()
        }
    }
}

class MockCardFormViewModelDelegate: CardFormViewModelDelegate {
    var startScannerCalled = false
    var showPermissionAlertCalled = false
    let expectation: XCTestExpectation?

    init(expectation: XCTestExpectation? = nil) {
        self.expectation = expectation
    }

    func startScanner() {
        startScannerCalled = true
        expectation?.fulfill()
    }

    func showPermissionAlert() {
        showPermissionAlertCalled = true
    }

    func updateThreeDSecureAttributes(email: PAYJP.ThreeDSecureAttributeEmail?, phone: PAYJP.ThreeDSecureAttributePhone?) {
    }
}

class MockTokenOperationObserverType: TokenOperationObserverType {
    var status: TokenOperationStatus = .acceptable
}
