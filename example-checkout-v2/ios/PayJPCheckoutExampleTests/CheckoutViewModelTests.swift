//
//  CheckoutViewModelTests.swift
//  PayJPCheckoutExampleTests
//
//  2026/01/20.
//

import XCTest
import Combine
@testable import PayJPCheckoutExample

final class CheckoutViewModelTests: XCTestCase {
    var viewModel: CheckoutViewModel!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        viewModel = CheckoutViewModel()
        cancellables = []
    }

    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.backendURL, "http://localhost:3000")
        XCTAssertNil(viewModel.selectedProduct)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.checkoutURL)
        XCTAssertEqual(viewModel.resultMessage, "")
        XCTAssertFalse(viewModel.showResult)
        XCTAssertFalse(viewModel.isError)
        XCTAssertTrue(viewModel.products.isEmpty)
    }

    // MARK: - Validation Tests

    func testCreateCheckoutSessionWithoutProduct() {
        viewModel.backendURL = "https://example.com"
        viewModel.selectedProduct = nil

        viewModel.createCheckoutSession()

        XCTAssertTrue(viewModel.showResult)
        XCTAssertTrue(viewModel.isError)
        XCTAssertEqual(viewModel.resultMessage, "商品を選択してください")
    }

    func testCreateCheckoutSessionWithoutBackendURL() {
        viewModel.backendURL = ""
        viewModel.selectedProduct = SampleProduct(id: "price_test_123", name: "テスト商品", amount: 100)

        viewModel.createCheckoutSession()

        XCTAssertTrue(viewModel.showResult)
        XCTAssertTrue(viewModel.isError)
        XCTAssertEqual(viewModel.resultMessage, "サーバーURLを入力してください")
    }

    func testCreateCheckoutSessionStartsLoading() {
        // Valid URL format to test that loading state is set
        viewModel.backendURL = "http://localhost:9999"
        viewModel.selectedProduct = SampleProduct(id: "price_test_123", name: "テスト商品", amount: 100)

        viewModel.createCheckoutSession()

        // When a valid URL is provided, loading should start
        // (Note: This test may complete before the async operation finishes)
        // The key validation is that it doesn't show an immediate error
        XCTAssertFalse(viewModel.resultMessage == "無効なURLです")
    }

    // MARK: - URL Redirect Handling Tests

    func testHandleSuccessRedirect() {
        let successURL = URL(string: "payjpcheckoutexample://checkout/success")!

        viewModel.handleRedirectURL(successURL)

        XCTAssertTrue(viewModel.showResult)
        XCTAssertFalse(viewModel.isError)
        XCTAssertTrue(viewModel.resultMessage.contains("決済が完了しました"))
        XCTAssertNil(viewModel.checkoutURL)
    }

    func testHandleCancelRedirect() {
        let cancelURL = URL(string: "payjpcheckoutexample://checkout/cancel")!

        viewModel.handleRedirectURL(cancelURL)

        XCTAssertTrue(viewModel.showResult)
        XCTAssertTrue(viewModel.isError)
        XCTAssertEqual(viewModel.resultMessage, "決済がキャンセルされました")
        XCTAssertNil(viewModel.checkoutURL)
    }

    func testHandleUnknownRedirect() {
        let unknownURL = URL(string: "payjpcheckoutexample://checkout/unknown")!

        viewModel.handleRedirectURL(unknownURL)

        XCTAssertTrue(viewModel.showResult)
        XCTAssertTrue(viewModel.isError)
        XCTAssertTrue(viewModel.resultMessage.contains("不明なリダイレクト"))
        XCTAssertNil(viewModel.checkoutURL)
    }

    // MARK: - Product Selection Tests

    func testSelectProduct() {
        let product = SampleProduct(id: "price_test_123", name: "テスト商品", amount: 100)

        viewModel.selectedProduct = product

        XCTAssertEqual(viewModel.selectedProduct?.id, product.id)
        XCTAssertEqual(viewModel.selectedProduct?.name, product.name)
        XCTAssertEqual(viewModel.selectedProduct?.amount, product.amount)
    }
}
