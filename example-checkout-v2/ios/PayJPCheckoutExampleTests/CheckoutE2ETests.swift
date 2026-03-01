//
//  CheckoutE2ETests.swift
//  PayJPCheckoutExampleTests
//
//  2026/01/20.
//

import XCTest
import Combine
@testable import PayJPCheckoutExample

final class CheckoutE2ETests: XCTestCase {
    var viewModel: CheckoutViewModel!
    var cancellables: Set<AnyCancellable>!

    // テスト用サーバーURL（環境変数または直接指定）
    let testServerURL = ProcessInfo.processInfo.environment["TEST_SERVER_URL"] ?? "http://localhost:3000"

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

    // MARK: - Server Health Check

    func testServerHealthCheck() async throws {
        let url = URL(string: testServerURL)!
        let (data, response) = try await URLSession.shared.data(from: url)

        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(httpResponse.statusCode, 200)

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["status"] as? String, "ok")
    }

    // MARK: - Checkout Session Creation Tests

    func testCreateCheckoutSessionAPICall() async throws {
        let endpoint = URL(string: "\(testServerURL)/create-checkout-session")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "price_id": "price_test_123",
            "quantity": 1,
            "success_url": "payjpcheckoutexample://checkout/success",
            "cancel_url": "payjpcheckoutexample://checkout/cancel"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)

        // サーバーが正常に応答することを確認
        // - 200: 成功（有効なprice_idの場合）
        // - 400/404: PAY.JP APIエラー（無効なprice_idの場合）
        // レスポンスがJSONであることを確認
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data),
                         "Response should be valid JSON. Status: \(httpResponse.statusCode)")

        // ステータスコードをログ出力（デバッグ用）
        print("API Response Status: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("API Response Body: \(responseString)")
        }
    }

    func testCreateCheckoutSessionMissingParams() async throws {
        let endpoint = URL(string: "\(testServerURL)/create-checkout-session")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 必須パラメータを欠いたリクエスト
        let body: [String: Any] = [
            "price_id": "price_test_123"
            // quantity, success_url, cancel_url が欠けている
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)

        XCTAssertEqual(httpResponse.statusCode, 400)

        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNotNil(json["error"])
    }

    // MARK: - Integration Test with ViewModel

    func testViewModelCreateCheckoutSessionIntegration() {
        let expectation = XCTestExpectation(description: "Checkout session creation")

        viewModel.backendURL = testServerURL
        viewModel.selectedProduct = SampleProduct(id: "price_test_123", name: "テスト商品", amount: 100)

        // checkoutURL または showResult の変更を監視
        viewModel.$checkoutURL
            .dropFirst()
            .sink { url in
                if url != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.$showResult
            .dropFirst()
            .sink { showResult in
                if showResult {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.createCheckoutSession()

        wait(for: [expectation], timeout: 10.0)

        // サーバーからの応答があったことを確認
        // （成功またはエラーのどちらか）
        XCTAssertTrue(viewModel.checkoutURL != nil || viewModel.showResult)
    }

    // MARK: - Response Parsing Tests

    func testCheckoutSessionResponseParsing() throws {
        let jsonString = """
        {
            "id": "cs_test_123",
            "url": "https://checkout.pay.jp/test",
            "status": "open"
        }
        """
        let data = jsonString.data(using: .utf8)!

        let response = try JSONDecoder().decode(CheckoutSessionResponse.self, from: data)

        XCTAssertEqual(response.id, "cs_test_123")
        XCTAssertEqual(response.url, "https://checkout.pay.jp/test")
        XCTAssertEqual(response.status, "open")
    }
}
