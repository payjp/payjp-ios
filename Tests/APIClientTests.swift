//
//  APIClientTests.swift
//  PAYJPTests
//

import XCTest
import OHHTTPStubs
@testable import PAYJP

// swiftlint:disable force_try type_body_length function_parameter_count
class APIClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // token
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/tokens") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            let data = TestFixture.JSON(by: "token.json")
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }).name = "default"
        // card brands
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/accounts/brands") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            let data = TestFixture.JSON(by: "cardBrands.json")
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }).name = "default"
        PAYJPSDK.publicKey = "pk_test_d5b6d618c26b898d5ed4253c"
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testCreateToken_withPKPaymentToken() {
        let apiClient = APIClient.shared
        let json = TestFixture.JSON(by: "token.json")
        let expectedToken = try! Token.decodeJson(with: json, using: JSONDecoder.shared)

        let expectation = self.expectation(description: self.description)

        apiClient.createToken(with: StubPaymentToken()) { result in
            switch result {
            case .success(let token):
                XCTAssertEqual(token.identifer, expectedToken.identifer)
                XCTAssertEqual(token.used, expectedToken.used)
                XCTAssertEqual(token.livemode, expectedToken.livemode)
                XCTAssertEqual(token.createdAt, expectedToken.createdAt)
                XCTAssertEqual(token.rawValue?.count, expectedToken.rawValue?.count)
                XCTAssertEqual(token.card.identifer, expectedToken.card.identifer)
                XCTAssertEqual(token.card.rawValue?.count, expectedToken.card.rawValue?.count)
                expectation.fulfill()
            default:
                XCTFail()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCreateToken_withPKPaymentToken_objc() {
        let apiClient = APIClient.shared
        let json = TestFixture.JSON(by: "token.json")
        let expectedToken = try! Token.decodeJson(with: json, using: JSONDecoder.shared)

        let expectation = self.expectation(description: self.description)

        apiClient.createTokenWith(StubPaymentToken(), completionHandler: { (token, error) in
            XCTAssertNil(error)
            guard let token = token else {
                XCTFail()
                return
            }
            XCTAssertEqual(token.identifer, expectedToken.identifer)
            XCTAssertEqual(token.used, expectedToken.used)
            XCTAssertEqual(token.livemode, expectedToken.livemode)
            XCTAssertEqual(token.createdAt, expectedToken.createdAt)
            XCTAssertEqual(token.rawValue?.count, expectedToken.rawValue?.count)
            XCTAssertEqual(token.card.identifer, expectedToken.card.identifer)
            XCTAssertEqual(token.card.rawValue?.count, expectedToken.card.rawValue?.count)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCreateToken_withCardInput() {
        let apiClient = APIClient.shared
        let json = TestFixture.JSON(by: "token.json")
        let expectedToken = try! Token.decodeJson(with: json, using: JSONDecoder.shared)
        let cardNumber = "4242424242424242"
        let cardExpMonth = "02"
        let cardExpYear = "2020"
        let cardCvc = "123"
        let cardHolderName = "TARO YAMADA"
        let tenantId = "ten_123"

        HTTPStubs.removeAllStubs()
        stubCardInputResponse(cardNumber: cardNumber,
                              cardCvc: cardCvc,
                              cardExpMonth: cardExpMonth,
                              cardExpYear: cardExpYear,
                              cardHolderName: cardHolderName,
                              tenantId: tenantId,
                              json: json)

        let expectation = self.expectation(description: self.description)

        apiClient.createToken(with: cardNumber,
                              cvc: cardCvc,
                              expirationMonth: cardExpMonth,
                              expirationYear: cardExpYear,
                              name: cardHolderName,
                              tenantId: tenantId) { result in
            switch result {
            case .success(let token):
                XCTAssertEqual(token.identifer, expectedToken.identifer)
                XCTAssertEqual(token.used, expectedToken.used)
                XCTAssertEqual(token.livemode, expectedToken.livemode)
                XCTAssertEqual(token.createdAt, expectedToken.createdAt)
                XCTAssertEqual(token.rawValue?.count, expectedToken.rawValue?.count)
                XCTAssertEqual(token.card.identifer, expectedToken.card.identifer)
                XCTAssertEqual(token.card.rawValue?.count, expectedToken.card.rawValue?.count)
                expectation.fulfill()
            default:
                XCTFail()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testCreateToken_withCardInput_objc() {
        let apiClient = APIClient.shared
        let json = TestFixture.JSON(by: "token.json")
        let expectedToken = try! Token.decodeJson(with: json, using: JSONDecoder.shared)
        let cardNumber = "4242424242424242"
        let cardExpMonth = "02"
        let cardExpYear = "2020"
        let cardCvc = "123"
        let cardHolderName = "TARO YAMADA"
        let tenantId = "ten_123"

        HTTPStubs.removeAllStubs()
        stubCardInputResponse(cardNumber: cardNumber,
                              cardCvc: cardCvc,
                              cardExpMonth: cardExpMonth,
                              cardExpYear: cardExpYear,
                              cardHolderName: cardHolderName,
                              tenantId: tenantId,
                              json: json)

        let expectation = self.expectation(description: self.description)

        apiClient.createTokenWith(cardNumber,
                                  cvc: cardCvc,
                                  expirationMonth: cardExpMonth,
                                  expirationYear: cardExpYear,
                                  name: cardHolderName,
                                  tenantId: tenantId) { (token, error) in
            XCTAssertNil(error)
            guard let token = token else {
                XCTFail()
                return
            }
            XCTAssertEqual(token.identifer, expectedToken.identifer)
            XCTAssertEqual(token.used, expectedToken.used)
            XCTAssertEqual(token.livemode, expectedToken.livemode)
            XCTAssertEqual(token.createdAt, expectedToken.createdAt)
            XCTAssertEqual(token.rawValue?.count, expectedToken.rawValue?.count)
            XCTAssertEqual(token.card.identifer, expectedToken.card.identifer)
            XCTAssertEqual(token.card.rawValue?.count, expectedToken.card.rawValue?.count)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetToken() {
        let apiClient = APIClient.shared
        let tokenId = "tok_eff34b780cbebd61e87f09ecc9c6"
        let json = TestFixture.JSON(by: "token.json")
        let decoder = JSONDecoder.shared
        let expectedToken = try! Token.decodeJson(with: json, using: decoder)

        let expectation = self.expectation(description: self.description)

        apiClient.getToken(with: tokenId) { result in
            switch result {
            case .success(let token):
                XCTAssertEqual(token.identifer, expectedToken.identifer)
                XCTAssertEqual(token.used, expectedToken.used)
                XCTAssertEqual(token.livemode, expectedToken.livemode)
                XCTAssertEqual(token.createdAt, expectedToken.createdAt)
                XCTAssertEqual(token.rawValue?.count, expectedToken.rawValue?.count)
                XCTAssertEqual(token.card.identifer, expectedToken.card.identifer)
                XCTAssertEqual(token.card.rawValue?.count, expectedToken.card.rawValue?.count)
                expectation.fulfill()
            default:
                XCTFail()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetToken_objc() {
        let apiClient = APIClient.shared
        let tokenId = "tok_eff34b780cbebd61e87f09ecc9c6"
        let json = TestFixture.JSON(by: "token.json")
        let decoder = JSONDecoder.shared
        let expectedToken = try! Token.decodeJson(with: json, using: decoder)

        let expectation = self.expectation(description: self.description)

        apiClient.getTokenWith(tokenId) { (token, error) in
            XCTAssertNil(error)
            guard let token = token else {
                XCTFail()
                return
            }
            XCTAssertEqual(token.identifer, expectedToken.identifer)
            XCTAssertEqual(token.used, expectedToken.used)
            XCTAssertEqual(token.livemode, expectedToken.livemode)
            XCTAssertEqual(token.createdAt, expectedToken.createdAt)
            XCTAssertEqual(token.rawValue?.count, expectedToken.rawValue?.count)
            XCTAssertEqual(token.card.identifer, expectedToken.card.identifer)
            XCTAssertEqual(token.card.rawValue?.count, expectedToken.card.rawValue?.count)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetAcceptedBrands() {
        let apiClient = APIClient.shared
        let tenantId = "tenand_id"
        let json = TestFixture.JSON(by: "cardBrands.json")
        let decoder = JSONDecoder.shared
        let expectedResponse = try! decoder.decode(GetAcceptedBrandsResponse.self, from: json)

        let expectation = self.expectation(description: self.description)

        apiClient.getAcceptedBrands(with: tenantId) { result in
            switch result {
            case .success(let brands):
                XCTAssertEqual(brands, expectedResponse.acceptedBrands)
                expectation.fulfill()
            default:
                XCTFail()
            }
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testGetAcceptedBrands_objc() {
        let apiClient = APIClient.shared
        let tenantId = "tenand_id"
        let json = TestFixture.JSON(by: "cardBrands.json")
        let decoder = JSONDecoder.shared
        let expectedResponse = try! decoder.decode(GetAcceptedBrandsResponse.self, from: json)
        let expectedBrands = expectedResponse.acceptedBrands.map { $0.rawValue as NSString }

        let expectation = self.expectation(description: self.description)

        apiClient.getAcceptedBrandsWith(tenantId) { (brands, error) in
            XCTAssertNil(error)
            XCTAssertEqual(brands, expectedBrands)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    private func stubCardInputResponse(cardNumber: String,
                                       cardCvc: String,
                                       cardExpMonth: String,
                                       cardExpYear: String,
                                       cardHolderName: String,
                                       tenantId: String,
                                       json: Data) {
        let cardHolderNameEncoded = cardHolderName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        stub(condition: { (req) -> Bool in
            // check request
            if let body = req.ohhttpStubs_httpBody {
                let bodyString = String(data: body, encoding: String.Encoding.utf8)
                let bodyParts = bodyString?.split(separator: "&").map(String.init)
                let body = bodyParts?.reduce([String: String]()) { original, string -> [String: String] in
                    var result = original
                    let pair = string.split(separator: "=").map(String.init)
                    result[pair[0]] = pair[1]
                    return result
                }

                XCTAssertEqual(body?["card%5Bnumber%5D"], cardNumber)
                XCTAssertEqual(body?["card%5Bcvc%5D"], cardCvc)
                XCTAssertEqual(body?["card%5Bexp_month%5D"], cardExpMonth)
                XCTAssertEqual(body?["card%5Bexp_year%5D"], cardExpYear)
                XCTAssertEqual(body?["card%5Bname%5D"], cardHolderNameEncoded)
                XCTAssertEqual(body?["tenant"], tenantId)
                return true
            }
            return false
        }, response: { (_) -> HTTPStubsResponse in
            HTTPStubsResponse(data: json, statusCode: 200, headers: nil)
        })
    }

    private func stubTdsResponse(tdsId: String, json: Data) {
        stub(condition: { (req) -> Bool in
            // check request
            if let body = req.ohhttpStubs_httpBody {
                let bodyString = String(data: body, encoding: String.Encoding.utf8)
                let bodyParts = bodyString?.split(separator: "&").map(String.init)
                let body = bodyParts?.reduce([String: String]()) { original, string -> [String: String] in
                    var result = original
                    let pair = string.split(separator: "=").map(String.init)
                    result[pair[0]] = pair[1]
                    print(string)
                    return result
                }

                XCTAssertEqual(body?["three_d_secure_token"], tdsId)
                return true
            }
            return false
        }, response: { (_) -> HTTPStubsResponse in
            HTTPStubsResponse(data: json, statusCode: 200, headers: nil)
        })
    }
}
// swiftlint:enable force_try type_body_length function_parameter_count
