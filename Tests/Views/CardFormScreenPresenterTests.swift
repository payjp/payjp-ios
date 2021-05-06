//
//  CardFormScreenPresenterTests.swift
//  PAYJPTests
//
//  Created by Tadashi Wakayanagi on 2019/12/05.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import XCTest
@testable import PAYJP

class CardFormScreenPresenterTests: XCTestCase {

    private func cardFormInput() -> CardFormInput {
        return CardFormInput(cardNumber: "1234",
                             expirationMonth: "4",
                             expirationYear: "20",
                             cvc: "123",
                             cardHolder: "waka")
    }

    private func mockToken(tdsStatus: PAYThreeDSecureStatus? = nil) -> Token {
        let card = Card(identifier: "card_id",
                        name: "paykun",
                        last4Number: "1234",
                        brand: "visa",
                        expirationMonth: 12,
                        expirationYear: 19,
                        fingerprint: "abcdefg",
                        liveMode: false,
                        createAt: Date(),
                        threeDSecureStatus: tdsStatus)
        let token = Token(identifier: "token_id",
                          livemode: false,
                          used: false,
                          card: card,
                          createAt: Date())
        return token
    }

    private func mockAccpetedBrands() -> [CardBrand] {
        let brands: [CardBrand] = [.visa, .mastercard, .jcb]
        return brands
    }

    func testCreateToken_success() {
        let expectation = self.expectation(description: "view update")
        let mockDelegate = MockCardFormScreenDelegate(expectation: expectation)
        let mockService = MockTokenService()
        mockService.createTokenResult = .success(mockToken())

        let presenter = CardFormScreenPresenter(delegate: mockDelegate, tokenService: mockService)
        presenter.createToken(tenantId: "tenant_id", formInput: cardFormInput())
        presenter.tokenOperationStatusDidUpdate(status: .running)
        presenter.tokenOperationStatusDidUpdate(status: .throttled)
        presenter.tokenOperationStatusDidUpdate(status: .acceptable)

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockService.createTokenTenantId, "tenant_id")
        XCTAssertTrue(mockDelegate.showIndicatorCalled, "showIndicator not called")
        XCTAssertTrue(mockDelegate.disableSubmitButtonCalled, "disableSubmitButton not called")
        XCTAssertTrue(mockDelegate.didProducedCalled, "didProduced not called")
        XCTAssertFalse(mockDelegate.dismissIndicatorCalled, "dismissIndicator is called")
        XCTAssertFalse(mockDelegate.enableSubmitButtonCalled, "enableSubmitButton is called")
        XCTAssertTrue(mockDelegate.didCompleteCardFormCalled, "didCompleteCardForm not called")
        XCTAssertTrue(presenter.cardFormResultSuccess)

        XCTAssertFalse(mockDelegate.dismissIndicatorCalled, "dismissIndicator is called")
        XCTAssertFalse(mockDelegate.enableSubmitButtonCalled, "enableSubmitButton is called")
    }

    func testCreateToken_failure() {
        let error = NSError(domain: "mock_domain", code: 0, userInfo: [NSLocalizedDescriptionKey: "mock api error"])
        let apiError = APIError.systemError(error)
        let expectation = self.expectation(description: "view update")
        let mockDelegate = MockCardFormScreenDelegate(expectation: expectation)
        let mockService = MockTokenService()
        mockService.createTokenResult = .failure(apiError)

        let presenter = CardFormScreenPresenter(delegate: mockDelegate, tokenService: mockService)
        presenter.createToken(tenantId: "tenant_id", formInput: cardFormInput())
        presenter.tokenOperationStatusDidUpdate(status: .running)
        presenter.tokenOperationStatusDidUpdate(status: .throttled)

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockService.createTokenTenantId, "tenant_id")
        XCTAssertTrue(mockDelegate.showIndicatorCalled, "showIndicator not called")
        XCTAssertTrue(mockDelegate.disableSubmitButtonCalled, "disableSubmitButton not called")
        XCTAssertFalse(mockDelegate.dismissIndicatorCalled, "dismissIndicator is called")
        XCTAssertFalse(mockDelegate.enableSubmitButtonCalled, "enableSubmitButton is called")
        XCTAssertEqual(mockDelegate.showErrorAlertMessage, "mock api error")
        XCTAssertFalse(presenter.cardFormResultSuccess)

        presenter.tokenOperationStatusDidUpdate(status: .acceptable)

        XCTAssertTrue(mockDelegate.dismissIndicatorCalled, "dismissIndicator is not called")
        XCTAssertTrue(mockDelegate.enableSubmitButtonCalled, "enableSubmitButton is not called")
    }

    func testCreateToken_delegate_failure() {
        let error = NSError(domain: "mock_domain",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "mock delegate error"])
        let expectation = self.expectation(description: "view update")
        let mockDelegate = MockCardFormScreenDelegate(error: error, expectation: expectation)
        let mockService = MockTokenService()
        mockService.createTokenResult = .success(mockToken())

        let presenter = CardFormScreenPresenter(delegate: mockDelegate, tokenService: mockService)
        presenter.createToken(tenantId: "tenant_id", formInput: cardFormInput())
        presenter.tokenOperationStatusDidUpdate(status: .running)
        presenter.tokenOperationStatusDidUpdate(status: .throttled)

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockService.createTokenTenantId, "tenant_id")
        XCTAssertTrue(mockDelegate.showIndicatorCalled, "showIndicator not called")
        XCTAssertTrue(mockDelegate.disableSubmitButtonCalled, "disableSubmitButton not called")
        XCTAssertFalse(mockDelegate.dismissIndicatorCalled, "dismissIndicator is called")
        XCTAssertFalse(mockDelegate.enableSubmitButtonCalled, "enableSubmitButton is called")
        XCTAssertEqual(mockDelegate.showErrorAlertMessage, "mock delegate error")
        XCTAssertFalse(presenter.cardFormResultSuccess)

        presenter.tokenOperationStatusDidUpdate(status: .acceptable)

        XCTAssertTrue(mockDelegate.dismissIndicatorCalled, "dismissIndicator is not called")
        XCTAssertTrue(mockDelegate.enableSubmitButtonCalled, "enableSubmitButton is not called")
    }

    func testFetchBrands_success() {
        let expectation = self.expectation(description: "view update")
        let mockDelegate = MockCardFormScreenDelegate(expectation: expectation)
        let brands = mockAccpetedBrands()
        let mockService = MockAccountService(brands: brands)

        let presenter = CardFormScreenPresenter(delegate: mockDelegate, accountsService: mockService)
        presenter.fetchBrands(tenantId: "tenant_id")

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockService.calledTenantId, "tenant_id")
        XCTAssertTrue(mockDelegate.showIndicatorCalled, "showIndicator not called")
        XCTAssertEqual(mockDelegate.fetchedBrands, brands)
        XCTAssertTrue(mockDelegate.dismissIndicatorCalled, "dismissIndicator not called")
        XCTAssertTrue(mockDelegate.dismissErrorViewCalled, "dismissErrorView not called")
        XCTAssertFalse(presenter.cardFormResultSuccess)
    }

    func testFetchBrands_failure() {
        let error = NSError(domain: "mock_domain",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "mock api error"])
        let apiError = APIError.systemError(error)
        let expectation = self.expectation(description: "view update")
        let mockDelegate = MockCardFormScreenDelegate(expectation: expectation)
        let mockService = MockAccountService(brands: mockAccpetedBrands(), error: apiError)

        let presenter = CardFormScreenPresenter(delegate: mockDelegate, accountsService: mockService)
        presenter.fetchBrands(tenantId: "tenant_id")

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockService.calledTenantId, "tenant_id")
        XCTAssertTrue(mockDelegate.showIndicatorCalled, "showIndicator not called")
        XCTAssertTrue(mockDelegate.dismissIndicatorCalled, "dismissIndicator not called")
        XCTAssertTrue(mockDelegate.dismissErrorViewCalled, "dismissErrorView not called")
        XCTAssertEqual(mockDelegate.showErrorViewMessage, "mock api error")
        XCTAssertFalse(mockDelegate.showErrorViewButtonHidden)
        XCTAssertFalse(presenter.cardFormResultSuccess)
    }

    func testPresentVerificationScreen_with_Token() {
        let expectation = self.expectation(description: "view update")
        let mockDelegate = MockCardFormScreenDelegate(expectation: expectation)
        // 3DSステータスがunverifiedの場合認証フローに進むべき
        let token = mockToken(tdsStatus: .unverified)
        let mockService = MockTokenService()
        mockService.createTokenResult = .success(token)

        let presenter = CardFormScreenPresenter(delegate: mockDelegate, tokenService: mockService)
        presenter.createToken(tenantId: "tenant_id", formInput: cardFormInput())
        presenter.tokenOperationStatusDidUpdate(status: .running)
        presenter.tokenOperationStatusDidUpdate(status: .throttled)
        presenter.tokenOperationStatusDidUpdate(status: .acceptable)

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockService.createTokenTenantId, "tenant_id")
        XCTAssertTrue(mockDelegate.showIndicatorCalled, "showIndicator not called")
        XCTAssertTrue(mockDelegate.disableSubmitButtonCalled, "disableSubmitButton not called")
        XCTAssertEqual(mockDelegate.presentVerificationScreenToken?.identifer, token.identifer)
        XCTAssertFalse(presenter.cardFormResultSuccess)
    }

    func testCompleteTokenTds_with_Token_success() {
        let expectation = self.expectation(description: "view update")
        expectation.expectedFulfillmentCount = 2
        let mockDelegate = MockCardFormScreenDelegate(expectation: expectation)
        let unverifiedToken = mockToken(tdsStatus: .unverified)
        let verifiedToken = mockToken(tdsStatus: .verified)
        let mockService = MockTokenService()
        mockService.createTokenResult = .success(unverifiedToken)
        mockService.finishTokenThreeDSecureResult = .success(verifiedToken)

        let presenter = CardFormScreenPresenter(delegate: mockDelegate,
                                                tokenService: mockService)
        presenter.createToken(tenantId: "tenant_id", formInput: cardFormInput())
        presenter.completeTokenTds()
        presenter.tokenOperationStatusDidUpdate(status: .running)
        presenter.tokenOperationStatusDidUpdate(status: .throttled)
        presenter.tokenOperationStatusDidUpdate(status: .acceptable)

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockService.finishTokenThreeDSecureTokenId, verifiedToken.identifer)
        XCTAssertTrue(mockDelegate.didProducedCalled, "didProduced not called")
        XCTAssertFalse(mockDelegate.dismissIndicatorCalled, "dismissIndicator is called")
        XCTAssertFalse(mockDelegate.enableSubmitButtonCalled, "enableSubmitButton is called")
        XCTAssertTrue(mockDelegate.didCompleteCardFormCalled, "didCompleteCardForm not called")
        XCTAssertTrue(presenter.cardFormResultSuccess)
    }

    func testCompleteTokenTds_with_Token_failure() {
        let error = NSError(domain: "mock_domain",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "mock api error"])
        let apiError = APIError.systemError(error)
        let expectation = self.expectation(description: "view update")
        expectation.expectedFulfillmentCount = 2
        let mockDelegate = MockCardFormScreenDelegate(expectation: expectation)
        let unverifiedToken = mockToken(tdsStatus: .unverified)
        let mockService = MockTokenService()
        mockService.createTokenResult = .success(unverifiedToken)
        mockService.finishTokenThreeDSecureResult = .failure(apiError)

        let presenter = CardFormScreenPresenter(delegate: mockDelegate,
                                                tokenService: mockService)
        presenter.createToken(tenantId: "tenant_id", formInput: cardFormInput())
        presenter.completeTokenTds()

        waitForExpectations(timeout: 1, handler: nil)

        XCTAssertEqual(mockService.finishTokenThreeDSecureTokenId, unverifiedToken.identifer)
        XCTAssertTrue(mockDelegate.dismissIndicatorCalled, "dismissIndicator not called")
        XCTAssertTrue(mockDelegate.enableSubmitButtonCalled, "enableSubmitButton not called")
        XCTAssertEqual(mockDelegate.showErrorAlertMessage, "mock api error")
        XCTAssertFalse(presenter.cardFormResultSuccess)
    }
}
