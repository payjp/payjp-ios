//
//  ClientTests.swift
//  PAYJPTests
//
//  Created by Tadashi Wakayanagi on 2019/12/02.
//  Copyright © 2019 PAY, Inc. All rights reserved.
//

import XCTest
import OHHTTPStubs
@testable import PAYJP

struct MockRequest: BaseRequest {
    typealias Response = Token

    var path: String
    var httpMethod: String = "GET"

    let tokenId: String

    init(tokenId: String, path: String? = nil) {
        self.tokenId = tokenId
        self.path = path ?? "mocks/\(tokenId)"
    }
}

class ClientTests: XCTestCase {

    let client = Client.shared

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testRequest_systemError() {
        let notConnectedError = NSError(domain: NSURLErrorDomain, code: URLError.notConnectedToInternet.rawValue)
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/mocks") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            return HTTPStubsResponse(error: notConnectedError)
        }).name = "default"

        let expectation = self.expectation(description: self.description)
        let request = MockRequest(tokenId: "mock_id")
        client.request(with: request) { result in
            switch result {
            case .failure(let apiError):
                switch apiError {
                case .systemError:
                    expectation.fulfill()
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequest_invalidJSON_200() {
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/mocks") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }).name = "default"

        let expectation = self.expectation(description: self.description)
        let request = MockRequest(tokenId: "mock_id")
        client.request(with: request) { result in
            switch result {
            case .failure(let apiError):
                switch apiError {
                case .invalidJSON:
                    expectation.fulfill()
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequest_invalidJSON_500() {
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/mocks") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        }).name = "default"

        let expectation = self.expectation(description: self.description)
        let request = MockRequest(tokenId: "mock_id")
        client.request(with: request) { result in
            switch result {
            case .failure(let apiError):
                switch apiError {
                case .invalidJSON:
                    expectation.fulfill()
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequest_serviceError() {
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/mocks") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            let data = TestFixture.JSON(by: "error.json")
            return HTTPStubsResponse(data: data, statusCode: 400, headers: nil)
        }).name = "default"

        let expectation = self.expectation(description: self.description)
        let request = MockRequest(tokenId: "mock_id")
        client.request(with: request) { result in
            switch result {
            case .failure(let apiError):
                switch apiError {
                case .serviceError:
                    expectation.fulfill()
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequest_rateLimitError() {
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/mocks") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            let data = TestFixture.JSON(by: "error.json")
            return HTTPStubsResponse(data: data, statusCode: 429, headers: nil)
        }).name = "default"

        let expectation = self.expectation(description: self.description)
        let request = MockRequest(tokenId: "mock_id")
        client.request(with: request) { result in
            switch result {
            case .failure(let apiError):
                switch apiError {
                case .rateLimitExceeded:
                    expectation.fulfill()
                default:
                    XCTFail()
                }
            default:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testRequest_success() {
        stub(condition: { (req) -> Bool in
            req.url?.host == "api.pay.jp" && req.url?.path.starts(with: "/v1/mocks") ?? false
        }, response: { (_) -> HTTPStubsResponse in
            let data = TestFixture.JSON(by: "token.json")
            return HTTPStubsResponse(data: data, statusCode: 200, headers: nil)
        }).name = "default"

        let expectation = self.expectation(description: self.description)
        let request = MockRequest(tokenId: "mock_id")
        client.request(with: request) { result in
            switch result {
            case .success:
                expectation.fulfill()
            default:
                XCTFail()
            }
        }
        waitForExpectations(timeout: 1, handler: nil)
    }

    private func mock200Response(urlString: String = "\(PAYJPApiEndpoint)tokens") -> HTTPURLResponse {
        return HTTPURLResponse(url: URL(string: urlString)!,
                               statusCode: 200,
                               httpVersion: "",
                               headerFields: nil)!
    }
}
